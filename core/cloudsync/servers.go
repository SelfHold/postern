package cloudsync

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"maps"
	"slices"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"

	"sshmanager/core/cloudsync/pb"
	"sshmanager/core/hosts"
)

// Scopes of the Connector API this app asks for (CONNECTOR.md § 13–14).
const (
	ScopeServers = "servers"
	ScopeSSHKeys = "ssh_keys"
)

// modeServers: hosts live in CloudSync's shared server list (scope
// "servers"); otherwise in this app's own record hosts.json.
const modeServers = "servers"

// Keys of Server.extra owned by this app. Other apps' keys are kept as is.
const extraStartDir = AppID + ".start_dir"

// ErrNoKeys: CloudSync does not give this app the SSH keys of its safe.
var ErrNoKeys = errors.New("CloudSync does not share its SSH keys with this app")

type serverSync struct {
	Rev  string `json:"rev"`
	Hash string `json:"hash"`
}

func ownExtra(k string) bool { return len(k) > len(AppID) && k[:len(AppID)+1] == AppID+"." }

// toServer is a host as the shared list sees it. A pasted private key has
// no field there: it stays on this device (auth SSH_KEY, no ssh_key_id).
func toServer(h hosts.Host) *pb.Server {
	sv := &pb.Server{
		Id:           h.ID,
		Name:         h.Name,
		Group:        h.Group,
		Host:         h.Address,
		Port:         uint32(h.Port),
		User:         h.User,
		HostKeys:     slices.Clone(h.HostKeys),
		JumpServerId: h.JumpID,
		Notes:        h.Notes,
		Tags:         slices.Clone(h.Tags),
		CreatedMs:    h.CreatedMs,
	}
	switch h.Auth {
	case hosts.AuthPassword:
		sv.Auth, sv.Password = pb.Server_PASSWORD, h.Password
	case hosts.AuthAgent:
		sv.Auth = pb.Server_AGENT
	case hosts.AuthSafeKey:
		sv.Auth, sv.SshKeyId = pb.Server_SSH_KEY, h.KeyID
	case hosts.AuthKey:
		sv.Auth = pb.Server_SSH_KEY
	}
	extra := map[string][]byte{}
	for k, v := range h.Extra {
		if !ownExtra(k) {
			extra[k] = v
		}
	}
	if h.StartDir != "" {
		extra[extraStartDir] = []byte(h.StartDir)
	}
	if len(extra) > 0 {
		sv.Extra = extra
	}
	return sv
}

// fromServer is the host of a shared server; local gives what only this
// device keeps (a pasted private key).
func fromServer(sv *pb.Server, local *hosts.Host) hosts.Host {
	h := hosts.Host{
		ID:        sv.Id,
		Name:      sv.Name,
		Group:     sv.Group,
		Address:   sv.Host,
		Port:      int(sv.Port),
		User:      sv.User,
		HostKeys:  slices.Clone(sv.HostKeys),
		JumpID:    sv.JumpServerId,
		Notes:     sv.Notes,
		Tags:      slices.Clone(sv.Tags),
		CreatedMs: sv.CreatedMs,
		UpdatedMs: sv.ModifiedMs,
	}
	switch sv.Auth {
	case pb.Server_PASSWORD:
		h.Auth, h.Password = hosts.AuthPassword, sv.Password
	case pb.Server_AGENT:
		h.Auth = hosts.AuthAgent
	case pb.Server_SSH_KEY:
		if sv.SshKeyId != "" {
			h.Auth, h.KeyID = hosts.AuthSafeKey, sv.SshKeyId
		} else {
			h.Auth = hosts.AuthKey
			if local != nil {
				h.PrivateKey, h.Passphrase = local.PrivateKey, local.Passphrase
			}
		}
	default:
		h.Auth = hosts.AuthPassword
	}
	for k, v := range sv.Extra {
		if k == extraStartDir {
			h.StartDir = string(v)
			continue
		}
		if !ownExtra(k) {
			if h.Extra == nil {
				h.Extra = map[string][]byte{}
			}
			h.Extra[k] = v
		}
	}
	return h
}

// serverHash says whether a host changed in what the shared list holds.
func serverHash(h hosts.Host) string {
	sv := toServer(h)
	sv.CreatedMs = 0
	b, err := proto.MarshalOptions{Deterministic: true}.Marshal(sv)
	if err != nil {
		panic(err)
	}
	sum := sha256.Sum256(b)
	return hex.EncodeToString(sum[:])
}

func removedAt(f hosts.File, id string) int64 {
	for _, r := range f.Removed {
		if r.ID == id {
			return r.AtMs
		}
	}
	return -1
}

// syncServers pulls the changes of the shared list into the local list,
// then pushes local changes. Every server is its own compare-and-swap; a
// server changed on both sides goes to the newer edit.
func (s *Syncer) syncServers(ctx context.Context, cli pb.ConnectorClient) error {
	s.mu.Lock()
	cursor := s.st.Cursor
	revs := maps.Clone(s.st.Servers)
	s.mu.Unlock()
	if revs == nil {
		revs = map[string]serverSync{}
	}

	// 1. What changed in CloudSync (nil = removed).
	remote := map[string]*pb.Server{}
	full := cursor == ""
	if !full {
		r, err := cli.ListServerChanges(ctx, &pb.ListChangesRequest{Cursor: cursor})
		if err != nil {
			return err
		}
		if r.Reset_ {
			full = true
		} else {
			var ids []string
			for _, c := range r.Changes {
				switch {
				case c.Deleted:
					remote[c.Id] = nil
				case revs[c.Id].Rev == c.Revision:
					delete(remote, c.Id) // our own write
				default:
					ids = append(ids, c.Id)
				}
			}
			got, err := s.getServers(ctx, cli, ids)
			if err != nil {
				return err
			}
			for _, id := range ids {
				remote[id] = got[id] // missing = removed meanwhile
			}
			cursor = r.Cursor
		}
	}
	if full {
		remote = map[string]*pb.Server{}
		cursor = ""
		page := ""
		for {
			r, err := cli.ListServers(ctx, &pb.ListServersRequest{Data: true, PageToken: page})
			if err != nil {
				return err
			}
			if cursor == "" {
				cursor = r.Cursor // from the first page: later changes are listed again
			}
			for _, sv := range r.Servers {
				remote[sv.Id] = sv
			}
			if page = r.NextPageToken; page == "" {
				break
			}
		}
		for id := range revs {
			if _, ok := remote[id]; !ok {
				remote[id] = nil
			}
		}
	}

	// 2. Apply them to the local list.
	_, err := s.store.Update(func(f hosts.File) (hosts.File, error) {
		for _, id := range slices.Sorted(maps.Keys(remote)) {
			sv := remote[id]
			i := f.Find(id)
			known, synced := revs[id]
			localChanged := i >= 0 && (!synced || serverHash(f.Hosts[i]) != known.Hash)
			if sv == nil {
				delete(revs, id)
				if i >= 0 && !localChanged {
					f.Hosts = slices.Delete(f.Hosts, i, i+1)
				}
				// Changed here but removed there: the edit wins and the host
				// is uploaded again as a new server (step 3).
				continue
			}
			if i >= 0 && localChanged && f.Hosts[i].UpdatedMs > sv.ModifiedMs {
				revs[id] = serverSync{Rev: sv.Revision, Hash: known.Hash} // still to push
				continue
			}
			if at := removedAt(f, id); i < 0 && at > sv.ModifiedMs {
				revs[id] = serverSync{Rev: sv.Revision, Hash: "removed"} // still to delete
				continue
			}
			var local *hosts.Host
			if i >= 0 {
				local = &f.Hosts[i]
			}
			h := fromServer(sv, local)
			if i >= 0 {
				f.Hosts[i] = h
			} else {
				f.Hosts = append(f.Hosts, h)
			}
			f.Removed = slices.DeleteFunc(f.Removed, func(r hosts.Removed) bool { return r.ID == id })
			revs[id] = serverSync{Rev: sv.Revision, Hash: serverHash(h)}
		}
		return f, nil
	})
	if err != nil {
		return err
	}

	// 3. Push local changes.
	var pushErr error
	retry := false
	f := s.store.File()
	for _, h := range f.Hosts {
		k, ok := revs[h.ID]
		if ok && serverHash(h) == k.Hash {
			continue
		}
		sv, base := toServer(h), k.Rev
		if !ok {
			sv.Id, base = "", "" // new: CloudSync picks the id
		}
		out, err := cli.PutServer(ctx, &pb.PutServerRequest{Server: sv, Base: base})
		if status.Code(err) == codes.Aborted {
			retry = true
			continue
		}
		if err != nil {
			pushErr = err
			break
		}
		if !ok {
			if err := s.rekey(h.ID, out.Id); err != nil {
				pushErr = err
				break
			}
			h.ID = out.Id
		}
		revs[out.Id] = serverSync{Rev: out.Revision, Hash: serverHash(h)}
	}
	if pushErr == nil {
		for _, r := range f.Removed {
			k, ok := revs[r.ID]
			if !ok {
				continue
			}
			_, err := cli.DeleteServer(ctx, &pb.DeleteServerRequest{Id: r.ID, Base: k.Rev})
			if status.Code(err) == codes.Aborted {
				retry = true
				continue
			}
			if err != nil && status.Code(err) != codes.NotFound {
				pushErr = err
				break
			}
			delete(revs, r.ID)
		}
	}

	s.mu.Lock()
	s.st.Cursor, s.st.Servers = cursor, revs
	_ = s.saveLocked()
	s.mu.Unlock()
	if retry {
		// Someone wrote meanwhile: the next round pulls it and pushes again.
		s.Kick()
	}
	return pushErr
}

func (s *Syncer) getServers(ctx context.Context, cli pb.ConnectorClient, ids []string) (map[string]*pb.Server, error) {
	out := map[string]*pb.Server{}
	for len(ids) > 0 {
		n := min(len(ids), 500)
		r, err := cli.GetServers(ctx, &pb.GetServersRequest{Ids: ids[:n]})
		if err != nil {
			return nil, err
		}
		for _, sv := range r.Servers {
			out[sv.Id] = sv
		}
		ids = ids[n:]
	}
	return out, nil
}

// rekey gives a local host the id CloudSync chose for it.
func (s *Syncer) rekey(from, to string) error {
	if from == to {
		return nil
	}
	_, err := s.store.Update(func(f hosts.File) (hosts.File, error) {
		if i := f.Find(from); i >= 0 {
			f.Hosts[i].ID = to
		}
		for i := range f.Removed {
			if f.Removed[i].ID == from {
				f.Removed[i].ID = to
			}
		}
		return f, nil
	})
	if err == nil {
		s.mu.Lock()
		cb := s.onRekey
		s.mu.Unlock()
		if cb != nil {
			cb(from, to)
		}
	}
	return err
}

// migrate moves the hosts of this app's own record into the shared list,
// once for all devices: the record keeps a map old id → server id, so a
// device that comes later re-keys its copy instead of uploading it again.
func (s *Syncer) migrate(ctx context.Context, cli pb.ConnectorClient) error {
	if err := s.reconcile(ctx, cli); err != nil {
		return err
	}
	revs := map[string]serverSync{}
	var mapping map[string]string
	for attempt := 0; ; attempt++ {
		item, err := cli.Get(ctx, &pb.GetRequest{Key: RecordKey})
		if err != nil {
			return err
		}
		var files []hosts.File
		for _, v := range item.Versions {
			f, err := hosts.Decode(v.Data)
			if err != nil {
				return fmt.Errorf("the synced host list cannot be read: %w", err)
			}
			files = append(files, f)
		}
		rec := hosts.Merge(files...)
		if len(rec.Migrated) > 0 {
			mapping = rec.Migrated
			break
		}
		if mapping == nil {
			mapping = map[string]string{}
			for _, h := range s.store.File().Hosts {
				sv := toServer(h)
				sv.Id = ""
				out, err := cli.PutServer(ctx, &pb.PutServerRequest{Server: sv})
				if err != nil {
					return err
				}
				mapping[h.ID] = out.Id
				h.ID = out.Id
				revs[out.Id] = serverSync{Rev: out.Revision, Hash: serverHash(h)}
			}
		}
		rec.Migrated = mapping
		_, err = cli.Put(ctx, &pb.PutRequest{Key: RecordKey, Data: hosts.Encode(rec), Base: item.Revision})
		if status.Code(err) == codes.Aborted && attempt < 3 {
			continue // written meanwhile: merge the maps and try again
		}
		if err != nil {
			return err
		}
		break
	}
	_, err := s.store.Update(func(f hosts.File) (hosts.File, error) {
		for i := range f.Hosts {
			if to, ok := mapping[f.Hosts[i].ID]; ok {
				f.Hosts[i].ID = to
			}
		}
		for i := range f.Removed {
			if to, ok := mapping[f.Removed[i].ID]; ok {
				f.Removed[i].ID = to
			}
		}
		f.Migrated = nil
		return f, nil
	})
	if err != nil {
		return err
	}
	s.mu.Lock()
	s.st.Mode, s.st.Cursor, s.st.Servers = modeServers, "", revs
	_ = s.saveLocked()
	cb := s.onRekey
	s.mu.Unlock()
	if cb != nil {
		for from, to := range mapping {
			cb(from, to)
		}
	}
	return nil
}

// SafeKeys lists the SSH keys of CloudSync's safe (no secrets).
func (s *Syncer) SafeKeys(ctx context.Context) ([]*pb.SshKey, error) {
	cli, closer, err := s.ready(ctx, ScopeSSHKeys)
	if err != nil {
		return nil, err
	}
	defer closer()
	r, err := cli.ListSshKeys(s.authCtx(ctx), &pb.ListSshKeysRequest{})
	if err != nil {
		return nil, keyErr(err)
	}
	return r.Keys, nil
}

// FetchKey returns the private key of a safe entry, for one connection.
// It is never stored.
func (s *Syncer) FetchKey(ctx context.Context, id string) (string, string, error) {
	cli, closer, err := s.ready(ctx, ScopeSSHKeys)
	if err != nil {
		return "", "", err
	}
	defer closer()
	r, err := cli.GetSshKeys(s.authCtx(ctx), &pb.GetSshKeysRequest{Ids: []string{id}})
	if err != nil {
		return "", "", keyErr(err)
	}
	for _, k := range r.Keys {
		if k.Id == id {
			return k.PrivateKey, k.Passphrase, nil
		}
	}
	return "", "", errors.New("the key is no longer in CloudSync: pick another one")
}

// ready dials CloudSync and checks that sync is on and scope granted.
func (s *Syncer) ready(ctx context.Context, scope string) (pb.ConnectorClient, func(), error) {
	s.mu.Lock()
	on := s.st.Enabled
	s.mu.Unlock()
	if !on {
		return nil, nil, errors.New("switch CloudSync sync on to use its keys")
	}
	ctx, cancel := context.WithTimeout(ctx, 20*time.Second)
	cli, closer, err := s.dialer.Dial(ctx)
	if err != nil {
		cancel()
		return nil, nil, ErrNotRunning
	}
	done := func() { closer.Close(); cancel() }
	h, err := cli.Hello(s.authCtx(ctx), &pb.HelloRequest{AppId: AppID})
	if err != nil {
		done()
		return nil, nil, ErrNotRunning
	}
	switch {
	case h.State == pb.VaultState_LOCKED:
		done()
		return nil, nil, errors.New("CloudSync is locked: unlock it first")
	case !slices.Contains(h.Scopes, scope):
		done()
		return nil, nil, ErrNoKeys
	}
	return cli, done, nil
}

func keyErr(err error) error {
	switch status.Code(err) {
	case codes.PermissionDenied, codes.Unimplemented:
		return ErrNoKeys
	case codes.FailedPrecondition:
		return errors.New("CloudSync is locked: unlock it first")
	}
	return errors.New(errText(err))
}
