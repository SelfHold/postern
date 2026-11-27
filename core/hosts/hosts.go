// Package hosts keeps the list of SSH hosts in one JSON file. The same
// bytes are the CloudSync record (see core/cloudsync), so the format is
// canonical: hosts and tombstones sorted by id, no volatile fields.
package hosts

import (
	"bytes"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"sync"
	"time"
)

// Auth methods.
const (
	AuthPassword = "password"
	AuthKey      = "key"
	AuthAgent    = "agent"
	// AuthSafeKey: an SSH key of CloudSync's password safe, by entry id
	// (KeyID). The private key is fetched at connect time, never stored.
	AuthSafeKey = "cloudsync_key"
)

// Host is one server. Secrets (password, key) are part of it: the file is
// private to the user locally and sealed by CloudSync when synced.
type Host struct {
	ID         string `json:"id"`
	Name       string `json:"name"`
	Group      string `json:"group,omitempty"`
	Address    string `json:"address"`
	Port       int    `json:"port,omitempty"`
	User       string `json:"user"`
	Auth       string `json:"auth"`
	Password   string `json:"password,omitempty"`
	PrivateKey string `json:"private_key,omitempty"`
	Passphrase string `json:"passphrase,omitempty"`
	KeyID      string `json:"key_id,omitempty"`
	// HostKeys: trusted server keys, authorized_keys format.
	HostKeys []string `json:"host_keys,omitempty"`
	Notes    string   `json:"notes,omitempty"`
	StartDir string   `json:"start_dir,omitempty"`
	Tags     []string `json:"tags,omitempty"`
	JumpID   string   `json:"jump_id,omitempty"`
	// Extra: fields of other apps from the shared server list, kept as is.
	Extra     map[string][]byte `json:"extra,omitempty"`
	CreatedMs int64             `json:"created_ms,omitempty"`
	UpdatedMs int64             `json:"updated_ms"`
}

// Removed is a tombstone: a host deleted on one device stays deleted when
// another device's older copy is merged in.
type Removed struct {
	ID   string `json:"id"`
	AtMs int64  `json:"at_ms"`
}

// File is the whole document.
type File struct {
	Version int       `json:"version"`
	Hosts   []Host    `json:"hosts"`
	Removed []Removed `json:"removed,omitempty"`
	// Migrated maps host ids of this file to server ids of CloudSync's
	// shared server list, once a device moved the hosts there. Other
	// devices re-key their copies with it instead of uploading them again.
	Migrated map[string]string `json:"migrated,omitempty"`
}

// FormatVersion of File. Newer readers keep unknown fields out of the
// merge, so only a breaking change bumps it.
const FormatVersion = 1

// TombstoneTTL: tombstones older than this (relative to the newest time in
// the file, so every device prunes alike) are dropped.
const TombstoneTTL = 90 * 24 * time.Hour

// ErrNotFound is returned for an unknown host id.
var ErrNotFound = errors.New("host not found")

// Decode parses a document; empty input is an empty list.
func Decode(data []byte) (File, error) {
	var f File
	if len(bytes.TrimSpace(data)) == 0 {
		return File{Version: FormatVersion}, nil
	}
	if err := json.Unmarshal(data, &f); err != nil {
		return File{}, fmt.Errorf("hosts: %w", err)
	}
	if f.Version > FormatVersion {
		return File{}, fmt.Errorf("hosts: format %d is newer than this app (%d)", f.Version, FormatVersion)
	}
	f.Version = FormatVersion
	return f.normalized(), nil
}

// Encode returns the canonical bytes of f.
func Encode(f File) []byte {
	f = f.normalized()
	data, err := json.MarshalIndent(f, "", "  ")
	if err != nil {
		panic(err) // plain structs: cannot fail
	}
	return append(data, '\n')
}

// Hash of the canonical bytes.
func Hash(data []byte) string {
	s := sha256.Sum256(data)
	return hex.EncodeToString(s[:])
}

func (f File) normalized() File {
	hs := slices.Clone(f.Hosts)
	if hs == nil {
		hs = []Host{}
	}
	rs := slices.Clone(f.Removed)
	slices.SortFunc(hs, func(a, b Host) int { return strings.Compare(a.ID, b.ID) })
	slices.SortFunc(rs, func(a, b Removed) int { return strings.Compare(a.ID, b.ID) })
	if len(rs) == 0 {
		rs = nil
	}
	var mg map[string]string
	if len(f.Migrated) > 0 {
		mg = f.Migrated
	}
	return File{Version: FormatVersion, Hosts: hs, Removed: rs, Migrated: mg}
}

// Merge folds documents into one. It is a pure function of the set of
// inputs (order does not matter), so every device that merges the same
// versions gets the same bytes:
//   - a host present in several inputs: the one with the newest UpdatedMs,
//     ties broken by the larger canonical encoding;
//   - tombstones: union, the newest time per id; a tombstone at or after a
//     host's UpdatedMs removes it (an edit after the removal brings it back).
func Merge(files ...File) File {
	best := map[string]Host{}
	dead := map[string]int64{}
	var newest int64
	for _, f := range files {
		for _, h := range f.Hosts {
			newest = max(newest, h.UpdatedMs)
			cur, ok := best[h.ID]
			if !ok || newer(h, cur) {
				best[h.ID] = h
			}
		}
		for _, r := range f.Removed {
			newest = max(newest, r.AtMs)
			dead[r.ID] = max(dead[r.ID], r.AtMs)
		}
	}
	out := File{Version: FormatVersion}
	for _, f := range files {
		for k, v := range f.Migrated {
			if out.Migrated == nil {
				out.Migrated = map[string]string{}
			}
			// Two devices migrating at once: the larger server id wins, so
			// the result does not depend on the order.
			if cur, ok := out.Migrated[k]; !ok || v > cur {
				out.Migrated[k] = v
			}
		}
	}
	for id, h := range best {
		if at, ok := dead[id]; ok && at >= h.UpdatedMs {
			continue
		}
		out.Hosts = append(out.Hosts, h)
	}
	cut := newest - TombstoneTTL.Milliseconds()
	for id, at := range dead {
		if at >= cut {
			out.Removed = append(out.Removed, Removed{ID: id, AtMs: at})
		}
	}
	return out.normalized()
}

func newer(a, b Host) bool {
	if a.UpdatedMs != b.UpdatedMs {
		return a.UpdatedMs > b.UpdatedMs
	}
	ea, _ := json.Marshal(a)
	eb, _ := json.Marshal(b)
	return bytes.Compare(ea, eb) > 0
}

// NewID returns a random host id.
func NewID() string {
	var b [12]byte
	if _, err := rand.Read(b[:]); err != nil {
		panic(err)
	}
	return hex.EncodeToString(b[:])
}

// Store is the local file, the working copy: the app reads and writes it
// whether or not CloudSync is there.
type Store struct {
	path string
	now  func() time.Time

	mu       sync.Mutex
	file     File
	onChange []func()
}

// Open loads path (a missing file is an empty list).
func Open(path string) (*Store, error) {
	s := &Store{path: path, now: time.Now}
	data, err := os.ReadFile(path)
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return nil, err
	}
	if s.file, err = Decode(data); err != nil {
		return nil, err
	}
	return s, nil
}

// OnChange registers fn, called after every change (local or replaced).
func (s *Store) OnChange(fn func()) {
	s.mu.Lock()
	s.onChange = append(s.onChange, fn)
	s.mu.Unlock()
}

// List returns the hosts sorted by group, then name.
func (s *Store) List() []Host {
	s.mu.Lock()
	hs := slices.Clone(s.file.Hosts)
	s.mu.Unlock()
	slices.SortFunc(hs, func(a, b Host) int {
		if c := strings.Compare(strings.ToLower(a.Group), strings.ToLower(b.Group)); c != 0 {
			return c
		}
		return strings.Compare(strings.ToLower(a.Name), strings.ToLower(b.Name))
	})
	return hs
}

// Get returns one host.
func (s *Store) Get(id string) (Host, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, h := range s.file.Hosts {
		if h.ID == id {
			return h, nil
		}
	}
	return Host{}, ErrNotFound
}

// Save creates (empty id) or replaces a host and stamps UpdatedMs.
func (s *Store) Save(h Host) (Host, error) {
	if err := Validate(h); err != nil {
		return Host{}, err
	}
	s.mu.Lock()
	if h.ID == "" {
		h.ID = NewID()
	}
	h.UpdatedMs = s.stamp(h.ID)
	f := s.file
	f.Hosts = slices.DeleteFunc(slices.Clone(f.Hosts), func(x Host) bool { return x.ID == h.ID })
	f.Hosts = append(f.Hosts, h)
	f.Removed = slices.DeleteFunc(slices.Clone(f.Removed), func(r Removed) bool { return r.ID == h.ID })
	err := s.writeLocked(f)
	s.mu.Unlock()
	if err != nil {
		return Host{}, err
	}
	s.changed()
	return h, nil
}

// Delete removes a host and leaves a tombstone.
func (s *Store) Delete(id string) error {
	s.mu.Lock()
	f := s.file
	n := len(f.Hosts)
	f.Hosts = slices.DeleteFunc(slices.Clone(f.Hosts), func(x Host) bool { return x.ID == id })
	if len(f.Hosts) == n {
		s.mu.Unlock()
		return ErrNotFound
	}
	f.Removed = append(slices.DeleteFunc(slices.Clone(f.Removed), func(r Removed) bool { return r.ID == id }),
		Removed{ID: id, AtMs: s.stamp(id)})
	err := s.writeLocked(f)
	s.mu.Unlock()
	if err == nil {
		s.changed()
	}
	return err
}

// stamp is "now", but always after the host's last known time, so an edit
// on a device with a slow clock still wins over the version it replaces.
func (s *Store) stamp(id string) int64 {
	t := s.now().UnixMilli()
	for _, h := range s.file.Hosts {
		if h.ID == id && h.UpdatedMs >= t {
			t = h.UpdatedMs + 1
		}
	}
	for _, r := range s.file.Removed {
		if r.ID == id && r.AtMs >= t {
			t = r.AtMs + 1
		}
	}
	return t
}

// Bytes returns the canonical bytes of the current list.
func (s *Store) Bytes() []byte {
	s.mu.Lock()
	defer s.mu.Unlock()
	return Encode(s.file)
}

// File returns the current document.
func (s *Store) File() File {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.file.normalized()
}

// Replace writes f as the new local list (after a merge or a download).
// It reports whether anything changed.
func (s *Store) Replace(f File) (bool, error) {
	s.mu.Lock()
	same := bytes.Equal(Encode(f), Encode(s.file))
	var err error
	if !same {
		err = s.writeLocked(f)
	}
	s.mu.Unlock()
	if err != nil || same {
		return false, err
	}
	s.changed()
	return true, nil
}

// ReplaceIf is Replace, but only while the local list still has the bytes
// old: a sync that read the list before a local edit never overwrites the
// edit. ok is false when the list changed meanwhile.
func (s *Store) ReplaceIf(old []byte, f File) (ok bool, err error) {
	s.mu.Lock()
	cur := Encode(s.file)
	if !bytes.Equal(cur, old) {
		s.mu.Unlock()
		return false, nil
	}
	same := bytes.Equal(Encode(f), cur)
	if !same {
		err = s.writeLocked(f)
	}
	s.mu.Unlock()
	if err != nil {
		return false, err
	}
	if !same {
		s.changed()
	}
	return true, nil
}

func (s *Store) writeLocked(f File) error {
	data := Encode(f)
	if err := writeAtomic(s.path, data); err != nil {
		return err
	}
	s.file = f.normalized()
	return nil
}

func (s *Store) changed() {
	s.mu.Lock()
	fns := slices.Clone(s.onChange)
	s.mu.Unlock()
	for _, fn := range fns {
		fn()
	}
}

// writeAtomic writes data to path through a temp file and a rename, so a
// crash leaves either the old or the new file, never half of one.
func writeAtomic(path string, data []byte) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	tmp, err := os.CreateTemp(filepath.Dir(path), "."+filepath.Base(path)+".*")
	if err != nil {
		return err
	}
	defer os.Remove(tmp.Name())
	if err := tmp.Chmod(0o600); err != nil {
		tmp.Close()
		return err
	}
	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Sync(); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmp.Name(), path)
}

// Update changes the list under the store's lock: fn gets a copy of the
// document and returns the new one. It reports whether anything changed.
func (s *Store) Update(fn func(f File) (File, error)) (bool, error) {
	s.mu.Lock()
	before := Encode(s.file)
	// fn may change the copy in place: it gets its own slices.
	cur, err := Decode(before)
	if err != nil {
		s.mu.Unlock()
		return false, err
	}
	next, err := fn(cur)
	if err != nil {
		s.mu.Unlock()
		return false, err
	}
	same := bytes.Equal(Encode(next), before)
	if !same {
		err = s.writeLocked(next)
	}
	s.mu.Unlock()
	if err != nil || same {
		return false, err
	}
	s.changed()
	return true, nil
}

// Find returns the index of the host with id in f.Hosts, or -1.
func (f File) Find(id string) int {
	return slices.IndexFunc(f.Hosts, func(h Host) bool { return h.ID == id })
}

// WriteAtomic is writeAtomic for other packages (sync state).
func WriteAtomic(path string, data []byte) error { return writeAtomic(path, data) }

// Validate checks the fields a connection needs.
func Validate(h Host) error {
	switch {
	case strings.TrimSpace(h.Name) == "":
		return errors.New("name is required")
	case strings.TrimSpace(h.Address) == "":
		return errors.New("address is required")
	case strings.TrimSpace(h.User) == "":
		return errors.New("user is required")
	case h.Port < 0 || h.Port > 65535:
		return errors.New("port must be 1–65535")
	}
	switch h.Auth {
	case AuthPassword, AuthAgent:
	case AuthKey:
		if strings.TrimSpace(h.PrivateKey) == "" {
			return errors.New("private key is required")
		}
	case AuthSafeKey:
		if strings.TrimSpace(h.KeyID) == "" {
			return errors.New("pick a key from CloudSync")
		}
	default:
		return fmt.Errorf("unknown auth %q", h.Auth)
	}
	return nil
}
