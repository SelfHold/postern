package cloudsync

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"slices"
	"strings"
	"sync"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"sshmanager/core/cloudsync/pb"
	"sshmanager/core/hosts"
)

// The app's identity in CloudSync. Never change them: another id sees
// other data.
const (
	AppID     = "sshmanager"
	AppName   = "SSH Manager"
	RecordKey = "hosts.json"
	// MaxRecord is CloudSync's limit for one value.
	MaxRecord = 256 << 10
)

// Phase of sync, as the app shows it.
type Phase int

const (
	PhaseOff Phase = iota + 1
	PhaseNotRunning
	PhaseNoVault
	PhaseLocked
	PhasePairing
	PhaseOffline
	PhaseSynced
	PhaseError
)

// Status is what the UI shows.
type Status struct {
	Phase       Phase
	Enabled     bool
	Available   bool
	PairingCode string
	Error       string
	Pending     bool
	LastSyncMs  int64
	DeviceName  string
	// SharedServers: hosts live in CloudSync's shared server list (scope
	// "servers"); otherwise in this app's own record.
	SharedServers bool
	// SafeKeys: the SSH keys of CloudSync's safe can be used (scope
	// "ssh_keys").
	SafeKeys bool
}

// localState is kept per device, outside the synced data (CONNECTOR.md § 7): the token
// is valid on this device only.
type localState struct {
	Enabled    bool   `json:"enabled"`
	Token      string `json:"token,omitempty"`
	VaultID    string `json:"vault_id,omitempty"`
	Base       string `json:"base,omitempty"`
	SyncedHash string `json:"synced_hash,omitempty"`
	// Shared server list (Mode "servers"): cursor of ListServerChanges and
	// the revision + hash each server was last synced at.
	Mode    string                `json:"mode,omitempty"`
	Cursor  string                `json:"cursor,omitempty"`
	Servers map[string]serverSync `json:"servers,omitempty"`
}

// Syncer keeps the hosts store and the CloudSync record in step.
type Syncer struct {
	dialer      Dialer
	store       *hosts.Store
	statePath   string
	description string
	interval    time.Duration

	mu         sync.Mutex
	st         localState
	status     Status
	onStatus   func(Status)
	onRekey    func(from, to string)
	pairing    context.CancelFunc // set while a pairing request waits
	watchStop  context.CancelFunc // set while Watch runs
	kick       chan struct{}
	lastProbed time.Time
}

// New loads the device state from statePath. description is shown to the
// user in the pairing dialog ("SSH Manager 0.1 on linux").
func New(d Dialer, store *hosts.Store, statePath, description string) (*Syncer, error) {
	s := &Syncer{
		dialer:      d,
		store:       store,
		statePath:   statePath,
		description: description,
		interval:    30 * time.Second,
		kick:        make(chan struct{}, 1),
	}
	data, err := os.ReadFile(statePath)
	switch {
	case err == nil:
		if err := json.Unmarshal(data, &s.st); err != nil {
			return nil, fmt.Errorf("cloudsync state: %w", err)
		}
	case !errors.Is(err, os.ErrNotExist):
		return nil, err
	}
	s.status = Status{Phase: PhaseOff, Enabled: s.st.Enabled}
	if s.st.Enabled {
		s.status.Phase = PhaseNotRunning
	}
	store.OnChange(s.Kick)
	return s, nil
}

// OnStatus sets the function called on every status change.
func (s *Syncer) OnStatus(fn func(Status)) {
	s.mu.Lock()
	s.onStatus = fn
	s.mu.Unlock()
}

// OnRekey sets the function called when a host gets the id CloudSync
// chose for it (open terminals and panels follow it).
func (s *Syncer) OnRekey(fn func(from, to string)) {
	s.mu.Lock()
	s.onRekey = fn
	s.mu.Unlock()
}

// Status returns the current status.
func (s *Syncer) Status() Status {
	s.mu.Lock()
	defer s.mu.Unlock()
	st := s.status
	st.Pending = st.Enabled && hosts.Hash(s.store.Bytes()) != s.st.SyncedHash
	return st
}

// Kick asks for a sync round now.
func (s *Syncer) Kick() {
	select {
	case s.kick <- struct{}{}:
	default:
	}
}

// Run syncs until ctx ends: at start, on every local change, on every
// change CloudSync reports, and every 30 s.
func (s *Syncer) Run(ctx context.Context) {
	for {
		s.Round(ctx)
		select {
		case <-ctx.Done():
			s.stopWatch()
			return
		case <-s.kick:
		case <-time.After(s.interval):
		}
	}
}

func (s *Syncer) setStatus(fn func(*Status)) {
	s.mu.Lock()
	old := s.status
	fn(&s.status)
	s.status.Enabled = s.st.Enabled
	if s.pairing != nil {
		s.status.Phase = PhasePairing
	} else {
		s.status.PairingCode = ""
	}
	cb, cur := s.onStatus, s.status
	s.mu.Unlock()
	if cb != nil && cur != old {
		cb(cur)
	}
}

func (s *Syncer) saveLocked() error {
	data, err := json.MarshalIndent(s.st, "", "  ")
	if err != nil {
		return err
	}
	return hosts.WriteAtomic(s.statePath, data)
}

// authCtx adds the bearer token (desktops) to ctx.
func (s *Syncer) authCtx(ctx context.Context) context.Context {
	s.mu.Lock()
	tok := s.st.Token
	s.mu.Unlock()
	if tok == "" {
		return ctx
	}
	return metadata.AppendToOutgoingContext(ctx, "authorization", "Bearer "+tok)
}

func (s *Syncer) dial(ctx context.Context) (pb.ConnectorClient, io.Closer, error) {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	return s.dialer.Dial(ctx)
}

// Round runs one sync round.
func (s *Syncer) Round(ctx context.Context) {
	s.mu.Lock()
	st := s.st
	pairing := s.pairing != nil
	s.mu.Unlock()

	if !st.Enabled && !pairing {
		// Off: look now and then whether CloudSync is there, so the app
		// can offer "Sync via CloudSync".
		s.mu.Lock()
		probe := time.Since(s.lastProbed) > time.Minute || s.status.Phase != PhaseOff
		if probe {
			s.lastProbed = time.Now()
		}
		s.mu.Unlock()
		if probe {
			avail := s.probe(ctx)
			s.setStatus(func(x *Status) { x.Phase, x.Available = PhaseOff, avail })
		}
		return
	}

	cli, closer, err := s.dial(ctx)
	if err != nil {
		s.notRunning(err)
		return
	}
	defer closer.Close()
	actx := s.authCtx(ctx)
	hello, err := cli.Hello(actx, &pb.HelloRequest{AppId: AppID})
	if err != nil {
		s.notRunning(err)
		return
	}
	s.setStatus(func(x *Status) { x.Available, x.DeviceName = true, hello.DeviceName })
	if hello.ApiVersion > APIVersion {
		s.setStatus(func(x *Status) {
			x.Phase, x.Error = PhaseError, fmt.Sprintf("CloudSync speaks API v%d: update this app", hello.ApiVersion)
		})
		return
	}
	switch hello.State {
	case pb.VaultState_NO_VAULT:
		s.setStatus(func(x *Status) { x.Phase, x.Error = PhaseNoVault, "" })
		return
	case pb.VaultState_LOCKED:
		s.setStatus(func(x *Status) { x.Phase, x.Error = PhaseLocked, "" })
		return
	}
	if pairing && !st.Enabled {
		s.setStatus(func(x *Status) {})
		return
	}
	if !hello.Paired {
		s.turnOff("CloudSync no longer knows this app (pairing revoked): switch sync on again")
		return
	}
	s.mu.Lock()
	switch {
	case s.st.VaultID == "":
		s.st.VaultID = hello.VaultId
		_ = s.saveLocked()
	case s.st.VaultID != hello.VaultId:
		s.mu.Unlock()
		s.turnOff("another CloudSync vault is open: switch sync on again to use it")
		return
	}
	s.mu.Unlock()

	shared := slices.Contains(hello.Scopes, ScopeServers)
	s.setStatus(func(x *Status) {
		x.SharedServers, x.SafeKeys = shared, slices.Contains(hello.Scopes, ScopeSSHKeys)
	})
	if shared {
		s.mu.Lock()
		mode := s.st.Mode
		s.mu.Unlock()
		if mode != modeServers {
			err = s.migrate(actx, cli)
		}
		if err == nil {
			err = s.syncServers(actx, cli)
		}
	} else {
		s.mu.Lock()
		if s.st.Mode == modeServers {
			// The scope was taken away: back to the own record, merged
			// with what it holds.
			s.st.Mode, s.st.Cursor, s.st.Servers, s.st.Base, s.st.SyncedHash = "", "", nil, "", ""
			_ = s.saveLocked()
		}
		s.mu.Unlock()
		err = s.reconcile(actx, cli)
	}
	switch status.Code(err) {
	case codes.OK:
		phase := PhaseSynced
		if hello.State == pb.VaultState_OFFLINE {
			phase = PhaseOffline
		}
		s.setStatus(func(x *Status) { x.Phase, x.Error, x.LastSyncMs = phase, "", time.Now().UnixMilli() })
		s.startWatch(ctx)
	case codes.Unavailable:
		s.setStatus(func(x *Status) { x.Phase, x.Error = PhaseOffline, "" })
	case codes.FailedPrecondition:
		s.setStatus(func(x *Status) { x.Phase, x.Error = PhaseLocked, "" })
	case codes.Unauthenticated:
		s.turnOff("CloudSync no longer knows this app (pairing revoked): switch sync on again")
	default:
		s.setStatus(func(x *Status) { x.Phase, x.Error = PhaseError, errText(err) })
	}
}

func (s *Syncer) probe(ctx context.Context) bool {
	cli, closer, err := s.dial(ctx)
	if err != nil {
		return false
	}
	defer closer.Close()
	h, err := cli.Hello(ctx, &pb.HelloRequest{AppId: AppID})
	return err == nil && h.State != pb.VaultState_NO_VAULT
}

func (s *Syncer) notRunning(err error) {
	msg := ""
	if !errors.Is(err, ErrNotRunning) && status.Code(err) != codes.Unavailable {
		msg = errText(err)
	}
	s.setStatus(func(x *Status) { x.Phase, x.Available, x.Error = PhaseNotRunning, false, msg })
}

// turnOff switches sync off and keeps the local file (CONNECTOR.md § 5 step 4).
func (s *Syncer) turnOff(why string) {
	s.stopWatch()
	s.mu.Lock()
	s.st = localState{}
	_ = s.saveLocked()
	s.mu.Unlock()
	s.setStatus(func(x *Status) { x.Phase, x.Error = PhaseOff, why })
}

// reconcile is CONNECTOR.md § 7 "Running": push a local change, take a remote one,
// merge when both changed or devices wrote concurrently.
func (s *Syncer) reconcile(ctx context.Context, cli pb.ConnectorClient) error {
	for range 5 {
		item, err := cli.Get(ctx, &pb.GetRequest{Key: RecordKey})
		if err != nil {
			return err
		}
		s.mu.Lock()
		base, synced := s.st.Base, s.st.SyncedHash
		s.mu.Unlock()
		local := s.store.Bytes()
		localChanged := hosts.Hash(local) != synced
		vs := item.Versions

		if item.Revision == base && len(vs) <= 1 && base != "" {
			if !localChanged {
				return nil
			}
			rev, err := s.put(ctx, cli, local, item.Revision)
			if status.Code(err) == codes.Aborted {
				continue
			}
			if err != nil {
				return err
			}
			s.saveSynced(rev, local)
			return nil
		}

		// Remote changed, or the first sync of this device.
		slices.SortFunc(vs, func(a, b *pb.Version) int { return strings.Compare(a.Id, b.Id) })
		var remotes []hosts.File
		for _, v := range vs {
			f, err := hosts.Decode(v.Data)
			if err != nil {
				// Never discard a version we cannot read (CONNECTOR.md § 6.2).
				return fmt.Errorf("a synced version from %s cannot be read, left as is: %w", v.DeviceName, err)
			}
			remotes = append(remotes, f)
		}
		localFile, err := hosts.Decode(local)
		if err != nil {
			return err
		}
		var result hosts.File
		switch {
		case len(remotes) == 0:
			result = localFile
		case len(remotes) == 1 && !localChanged && base != "":
			result = remotes[0]
		default:
			result = hosts.Merge(append(remotes, localFile)...)
		}
		ok, err := s.store.ReplaceIf(local, result)
		if err != nil {
			return err
		}
		if !ok {
			continue // edited meanwhile: start over
		}
		out := hosts.Encode(result)
		if len(vs) == 1 && bytes.Equal(out, vs[0].Data) {
			s.saveSynced(item.Revision, out)
			return nil
		}
		rev, err := s.put(ctx, cli, out, item.Revision)
		if status.Code(err) == codes.Aborted {
			continue
		}
		if err != nil {
			return err
		}
		s.saveSynced(rev, out)
		return nil
	}
	return errors.New("the host list keeps changing in CloudSync: will retry")
}

func (s *Syncer) put(ctx context.Context, cli pb.ConnectorClient, data []byte, base string) (string, error) {
	if len(data) > MaxRecord {
		return "", fmt.Errorf("the host list is %d KiB, CloudSync takes at most %d KiB", len(data)>>10, MaxRecord>>10)
	}
	item, err := cli.Put(ctx, &pb.PutRequest{Key: RecordKey, Data: data, Base: base})
	if err != nil {
		return "", err
	}
	return item.Revision, nil
}

func (s *Syncer) saveSynced(rev string, data []byte) {
	s.mu.Lock()
	s.st.Base, s.st.SyncedHash = rev, hosts.Hash(data)
	_ = s.saveLocked()
	s.mu.Unlock()
}

// Enable switches sync on: it asks CloudSync for pairing when this app is
// not paired yet and returns the code to show (Status.PairingCode); the
// answer arrives through OnStatus.
func (s *Syncer) Enable(ctx context.Context) (Status, error) {
	cli, closer, err := s.dial(ctx)
	if err != nil {
		s.notRunning(err)
		return s.Status(), ErrNotRunning
	}
	defer closer.Close()
	hello, err := cli.Hello(s.authCtx(ctx), &pb.HelloRequest{AppId: AppID})
	if err != nil {
		s.notRunning(err)
		return s.Status(), ErrNotRunning
	}
	if hello.State == pb.VaultState_NO_VAULT {
		return s.Status(), errors.New("CloudSync is not set up on this device yet")
	}
	if hello.Paired {
		s.mu.Lock()
		s.st.Enabled = true
		s.st.VaultID = hello.VaultId
		s.st.Base, s.st.SyncedHash = "", ""
		err := s.saveLocked()
		s.mu.Unlock()
		s.setStatus(func(x *Status) { x.Error = "" })
		s.Kick()
		return s.Status(), err
	}
	return s.requestPairing(ctx, cli)
}

// RequestAccess asks CloudSync again, while paired, for the scopes this
// app wants (shared servers, SSH keys): the pairing stays valid while the
// request waits.
func (s *Syncer) RequestAccess(ctx context.Context) (Status, error) {
	cli, closer, err := s.dial(ctx)
	if err != nil {
		s.notRunning(err)
		return s.Status(), ErrNotRunning
	}
	defer closer.Close()
	return s.requestPairing(ctx, cli)
}

func (s *Syncer) requestPairing(ctx context.Context, cli pb.ConnectorClient) (Status, error) {
	req := &pb.PairingRequest{AppId: AppID, AppName: AppName, Description: s.description,
		Scopes: []string{ScopeServers, ScopeSSHKeys}}
	t, err := cli.RequestPairing(ctx, req)
	if status.Code(err) == codes.InvalidArgument {
		// A CloudSync that does not know these scopes yet: pair for the
		// app's own record only.
		req.Scopes = nil
		t, err = cli.RequestPairing(ctx, req)
	}
	if err != nil {
		return s.Status(), errors.New(errText(err))
	}
	s.mu.Lock()
	if s.pairing != nil {
		s.pairing()
	}
	pctx, cancel := context.WithDeadline(context.Background(), time.UnixMilli(t.ExpiresUnixMs).Add(10*time.Second))
	s.pairing = cancel
	s.mu.Unlock()
	s.setStatus(func(x *Status) { x.PairingCode, x.Error = formatCode(t.Code), "" })
	go s.await(pctx, cancel, t.Ticket)
	return s.Status(), nil
}

// await waits for the user's answer in CloudSync.
func (s *Syncer) await(ctx context.Context, cancel context.CancelFunc, ticket string) {
	defer cancel()
	finish := func(fn func()) {
		s.mu.Lock()
		mine := s.pairing != nil && ctx.Err() == nil
		s.pairing = nil
		if mine {
			fn()
		}
		s.mu.Unlock()
	}
	for ctx.Err() == nil {
		cli, closer, err := s.dial(ctx)
		if err != nil {
			select {
			case <-ctx.Done():
			case <-time.After(5 * time.Second):
			}
			continue
		}
		r, err := cli.AwaitPairing(ctx, &pb.AwaitPairingRequest{Ticket: ticket, WaitSeconds: 60})
		closer.Close()
		if err != nil {
			select {
			case <-ctx.Done():
			case <-time.After(5 * time.Second):
			}
			continue
		}
		switch r.Status {
		case pb.PairingStatus_PENDING:
			continue
		case pb.PairingStatus_APPROVED:
			finish(func() {
				if !s.st.Enabled {
					s.st = localState{Enabled: true}
				}
				if r.Token != "" { // Android: no token, the package is the credential
					s.st.Token = r.Token
				}
				_ = s.saveLocked()
			})
			s.setStatus(func(x *Status) { x.Error = "" })
			s.Kick()
			return
		case pb.PairingStatus_DENIED:
			finish(func() {})
			s.pairingEnded("CloudSync denied the request")
			return
		default:
			finish(func() {})
			s.pairingEnded("the request expired: try again")
			return
		}
	}
	finish(func() {})
	s.pairingEnded("")
}

// pairingEnded reports a request that was not approved; an existing
// pairing (a request for more scopes) keeps syncing.
func (s *Syncer) pairingEnded(why string) {
	s.mu.Lock()
	on := s.st.Enabled
	s.mu.Unlock()
	if on {
		s.setStatus(func(x *Status) { x.Error = why })
		s.Kick()
		return
	}
	s.setStatus(func(x *Status) { x.Phase, x.Error = PhaseOff, why })
}

// Disable switches sync off, keeps the local file and forgets the pairing.
// The record stays in CloudSync for the other devices.
func (s *Syncer) Disable(ctx context.Context) Status {
	s.stopWatch()
	s.mu.Lock()
	if s.pairing != nil {
		s.pairing()
		s.pairing = nil
	}
	had := s.st.Token != "" || s.st.Enabled
	s.mu.Unlock()
	if had {
		if cli, closer, err := s.dial(ctx); err == nil {
			_, _ = cli.Unpair(s.authCtx(ctx), &pb.UnpairRequest{})
			closer.Close()
		}
	}
	s.mu.Lock()
	s.st = localState{}
	_ = s.saveLocked()
	s.mu.Unlock()
	s.setStatus(func(x *Status) { x.Phase, x.Error = PhaseOff, "" })
	return s.Status()
}

// startWatch keeps one Watch stream open; every change kicks a round.
// Without Watch (Android adapter, old CloudSync) the 30 s rounds remain.
func (s *Syncer) startWatch(ctx context.Context) {
	s.mu.Lock()
	if s.watchStop != nil {
		s.mu.Unlock()
		return
	}
	wctx, cancel := context.WithCancel(ctx)
	s.watchStop = cancel
	s.mu.Unlock()
	go func() {
		defer func() {
			s.mu.Lock()
			s.watchStop = nil
			s.mu.Unlock()
			cancel()
		}()
		cli, closer, err := s.dial(wctx)
		if err != nil {
			return
		}
		defer closer.Close()
		stream, err := cli.Watch(s.authCtx(wctx), &pb.WatchRequest{})
		if err != nil {
			return
		}
		// Watch sends nothing at first; the round that started it has just
		// read the record, and the 30 s rounds catch a change in between.
		opened := time.Now()
		for {
			if _, err := stream.Recv(); err != nil {
				// A stream that fails at once (Unimplemented, no auth) is
				// left to the periodic rounds; kicking would spin.
				if time.Since(opened) > 5*time.Second {
					s.Kick()
				}
				return
			}
			s.Kick()
		}
	}()
}

func (s *Syncer) stopWatch() {
	s.mu.Lock()
	stop := s.watchStop
	s.mu.Unlock()
	if stop != nil {
		stop()
	}
}

// formatCode shows "123456" as "123 456".
func formatCode(c string) string {
	if len(c) == 6 {
		return c[:3] + " " + c[3:]
	}
	return c
}

func errText(err error) string {
	if st, ok := status.FromError(err); ok && st.Message() != "" {
		return st.Message()
	}
	return err.Error()
}
