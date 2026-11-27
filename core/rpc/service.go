// Package rpc is the core's gRPC API for the app (proto/postern.proto).
package rpc

import (
	"context"
	"errors"
	"io"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/pkg/sftp"
	"golang.org/x/crypto/ssh"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"github.com/SelfHold/postern/core/fsys"
	"github.com/SelfHold/postern/core/hosts"
	"github.com/SelfHold/postern/core/rpc/pb"
	"github.com/SelfHold/postern/core/shard"
	"github.com/SelfHold/postern/core/sshc"
)

// Set at build time (-ldflags -X).
var (
	Version = "0.1.0"
	Build   = "dev"
)

// Service implements pb.CoreServer.
type Service struct {
	pb.UnimplementedCoreServer

	store    *hosts.Store
	sync     *shard.Syncer
	local    fsys.FS
	platform string

	subMu sync.Mutex
	subs  map[chan *pb.Event]struct{}

	poolMu sync.Mutex
	pool   map[string]*remote
}

type remote struct {
	ssh  *ssh.Client
	sftp *sftp.Client
	used time.Time
}

// New builds the service. local is this device's file tree.
func New(store *hosts.Store, syncer *shard.Syncer, local fsys.FS, platform string) *Service {
	s := &Service{
		store:    store,
		sync:     syncer,
		local:    local,
		platform: platform,
		subs:     map[chan *pb.Event]struct{}{},
		pool:     map[string]*remote{},
	}
	store.OnChange(func() { s.publish(&pb.Event{Kind: pb.Event_HOSTS}) })
	syncer.OnStatus(func(shard.Status) { s.publish(&pb.Event{Kind: pb.Event_SYNC}) })
	syncer.OnRekey(func(from, to string) {
		s.poolMu.Lock()
		if r, ok := s.pool[from]; ok {
			delete(s.pool, from)
			s.pool[to] = r
		}
		s.poolMu.Unlock()
		s.publish(&pb.Event{Kind: pb.Event_HOSTS, Message: "rekey " + from + " " + to})
	})
	go s.janitor()
	return s
}

// TokenAuth makes every call carry "authorization: Bearer <token>".
func TokenAuth(token string) []grpc.ServerOption {
	check := func(ctx context.Context) error {
		md, _ := metadata.FromIncomingContext(ctx)
		for _, v := range md.Get("authorization") {
			if v == "Bearer "+token {
				return nil
			}
		}
		return status.Error(codes.Unauthenticated, "bad token")
	}
	return []grpc.ServerOption{
		grpc.MaxRecvMsgSize(8 << 20),
		grpc.UnaryInterceptor(func(ctx context.Context, req any, _ *grpc.UnaryServerInfo, h grpc.UnaryHandler) (any, error) {
			if err := check(ctx); err != nil {
				return nil, err
			}
			return h(ctx, req)
		}),
		grpc.StreamInterceptor(func(srv any, ss grpc.ServerStream, _ *grpc.StreamServerInfo, h grpc.StreamHandler) error {
			if err := check(ss.Context()); err != nil {
				return err
			}
			return h(srv, ss)
		}),
	}
}

// Close drops every pooled connection.
func (s *Service) Close() {
	s.poolMu.Lock()
	defer s.poolMu.Unlock()
	for id, r := range s.pool {
		r.sftp.Close()
		r.ssh.Close()
		delete(s.pool, id)
	}
}

func (s *Service) publish(e *pb.Event) {
	s.subMu.Lock()
	defer s.subMu.Unlock()
	for ch := range s.subs {
		select {
		case ch <- e:
		default: // a slow client misses events, not the whole core
		}
	}
}

// --- state and events ----------------------------------------------------

func (s *Service) GetState(context.Context, *pb.Empty) (*pb.State, error) {
	return &pb.State{CoreVersion: Version, CoreBuild: Build, Platform: s.platform, Sync: syncState(s.sync.Status())}, nil
}

func (s *Service) Events(_ *pb.Empty, stream grpc.ServerStreamingServer[pb.Event]) error {
	ch := make(chan *pb.Event, 32)
	s.subMu.Lock()
	s.subs[ch] = struct{}{}
	s.subMu.Unlock()
	defer func() {
		s.subMu.Lock()
		delete(s.subs, ch)
		s.subMu.Unlock()
	}()
	for {
		select {
		case <-stream.Context().Done():
			return nil
		case e := <-ch:
			if err := stream.Send(e); err != nil {
				return err
			}
		}
	}
}

func syncState(st shard.Status) *pb.SyncState {
	return &pb.SyncState{
		Phase:         pb.SyncState_Phase(st.Phase),
		Enabled:       st.Enabled,
		Available:     st.Available,
		PairingCode:   st.PairingCode,
		Error:         st.Error,
		Pending:       st.Pending,
		LastSyncMs:    st.LastSyncMs,
		DeviceName:    st.DeviceName,
		SharedServers: st.SharedServers,
		SafeKeys:      st.SafeKeys,
	}
}

// --- hosts ---------------------------------------------------------------

func toPB(h hosts.Host) *pb.Host {
	return &pb.Host{
		Id: h.ID, Name: h.Name, Group: h.Group, Address: h.Address, Port: uint32(h.Port), User: h.User,
		Auth: authPB(h.Auth), Password: h.Password, PrivateKey: h.PrivateKey, Passphrase: h.Passphrase,
		HostKeys: h.HostKeys, UpdatedMs: h.UpdatedMs, Notes: h.Notes, StartDir: h.StartDir, KeyId: h.KeyID,
		Tags: h.Tags, JumpId: h.JumpID,
	}
}

func authPB(a string) pb.Host_Auth {
	switch a {
	case hosts.AuthPassword:
		return pb.Host_PASSWORD
	case hosts.AuthKey:
		return pb.Host_KEY
	case hosts.AuthAgent:
		return pb.Host_AGENT
	case hosts.AuthSafeKey:
		return pb.Host_SAFE_KEY
	}
	return pb.Host_AUTH_UNSPECIFIED
}

func authName(a pb.Host_Auth) string {
	switch a {
	case pb.Host_KEY:
		return hosts.AuthKey
	case pb.Host_AGENT:
		return hosts.AuthAgent
	case pb.Host_SAFE_KEY:
		return hosts.AuthSafeKey
	}
	return hosts.AuthPassword
}

func (s *Service) ListHosts(context.Context, *pb.Empty) (*pb.HostList, error) {
	out := &pb.HostList{}
	for _, h := range s.store.List() {
		out.Hosts = append(out.Hosts, toPB(h))
	}
	return out, nil
}

func (s *Service) SaveHost(_ context.Context, in *pb.Host) (*pb.Host, error) {
	h := hosts.Host{
		ID: in.Id, Name: strings.TrimSpace(in.Name), Group: strings.TrimSpace(in.Group),
		Address: strings.TrimSpace(in.Address), Port: int(in.Port), User: strings.TrimSpace(in.User),
		Auth: authName(in.Auth), Notes: in.Notes, StartDir: strings.TrimSpace(in.StartDir),
		Tags: in.Tags, JumpID: in.JumpId,
	}
	// Keep only the secret of the chosen method.
	switch h.Auth {
	case hosts.AuthPassword:
		h.Password = in.Password
	case hosts.AuthKey:
		h.PrivateKey, h.Passphrase = in.PrivateKey, in.Passphrase
	case hosts.AuthSafeKey:
		h.KeyID = in.KeyId
	}
	if old, err := s.store.Get(in.Id); err == nil {
		// Fields the form does not edit.
		h.HostKeys, h.Extra, h.CreatedMs = old.HostKeys, old.Extra, old.CreatedMs
		if old.Address != h.Address || old.Port != h.Port {
			h.HostKeys = nil // another machine: its key must be checked again
		}
		s.dropPool(in.Id)
	} else {
		h.CreatedMs = time.Now().UnixMilli()
	}
	saved, err := s.store.Save(h)
	if err != nil {
		return nil, mapErr(err)
	}
	return toPB(saved), nil
}

func (s *Service) DeleteHost(_ context.Context, in *pb.HostRef) (*pb.Empty, error) {
	s.dropPool(in.Id)
	if err := s.store.Delete(in.Id); err != nil {
		return nil, mapErr(err)
	}
	return &pb.Empty{}, nil
}

func (s *Service) ProbeHostKey(ctx context.Context, in *pb.HostRef) (*pb.HostKey, error) {
	h, err := s.store.Get(in.Id)
	if err != nil {
		return nil, mapErr(err)
	}
	r, err := sshc.Probe(ctx, h)
	if err != nil {
		return nil, status.Error(codes.Unavailable, err.Error())
	}
	return &pb.HostKey{Status: pb.HostKey_Status(r.Status), Key: r.Key, Fingerprint: r.Fingerprint, Type: r.Type}, nil
}

func (s *Service) TrustHostKey(_ context.Context, in *pb.TrustRequest) (*pb.Host, error) {
	key, err := sshc.NormalizeKey(in.Key)
	if err != nil {
		return nil, status.Error(codes.InvalidArgument, err.Error())
	}
	h, err := s.store.Get(in.Id)
	if err != nil {
		return nil, mapErr(err)
	}
	if in.Replace {
		h.HostKeys = nil
	}
	for _, k := range h.HostKeys {
		if k == key {
			return toPB(h), nil
		}
	}
	h.HostKeys = append(h.HostKeys, key)
	saved, err := s.store.Save(h)
	if err != nil {
		return nil, mapErr(err)
	}
	return toPB(saved), nil
}

func mapErr(err error) error {
	var exists fsys.ErrExists
	switch {
	case err == nil:
		return nil
	case status.Code(err) != codes.Unknown:
		return err
	case errors.Is(err, hosts.ErrNotFound), errors.Is(err, os.ErrNotExist):
		return status.Error(codes.NotFound, err.Error())
	case errors.Is(err, sshc.ErrHostKeyUnknown), errors.Is(err, sshc.ErrHostKeyChanged):
		// The app checks the key (ProbeHostKey) and asks the user.
		return status.Error(codes.FailedPrecondition, "hostkey: "+err.Error())
	case errors.As(err, &exists):
		return status.Error(codes.AlreadyExists, err.Error())
	case errors.Is(err, os.ErrPermission):
		return status.Error(codes.PermissionDenied, err.Error())
	case errors.Is(err, context.Canceled):
		return status.Error(codes.Canceled, "cancelled")
	case strings.Contains(err.Error(), "required"), strings.Contains(err.Error(), "must be"),
		strings.Contains(err.Error(), "pick a key"):
		return status.Error(codes.InvalidArgument, err.Error())
	}
	return status.Error(codes.Unknown, err.Error())
}

// --- connections -----------------------------------------------------

func (s *Service) fetchKey(ctx context.Context, id string) (string, string, error) {
	return s.sync.FetchKey(ctx, id)
}

func (s *Service) dial(ctx context.Context, id string) (*ssh.Client, error) {
	h, err := s.store.Get(id)
	if err != nil {
		return nil, err
	}
	if h.JumpID != "" {
		return nil, errors.New("connecting through a jump host is not supported yet")
	}
	return sshc.Dial(ctx, h, s.fetchKey)
}

// fs returns the file tree of a side: "" is this device.
func (s *Service) fs(ctx context.Context, side string) (fsys.FS, error) {
	if side == "" {
		return s.local, nil
	}
	s.poolMu.Lock()
	r, ok := s.pool[side]
	if ok {
		// A connection that died meanwhile is replaced.
		if _, err := r.sftp.Getwd(); err != nil {
			r.sftp.Close()
			r.ssh.Close()
			delete(s.pool, side)
			ok = false
		} else {
			r.used = time.Now()
		}
	}
	s.poolMu.Unlock()
	if ok {
		return fsys.Remote{C: r.sftp}, nil
	}
	c, err := s.dial(ctx, side)
	if err != nil {
		return nil, err
	}
	sc, err := sftp.NewClient(c, sftp.UseConcurrentReads(true), sftp.UseConcurrentWrites(true))
	if err != nil {
		c.Close()
		return nil, errors.New("the server has no SFTP: " + err.Error())
	}
	s.poolMu.Lock()
	if old, ok := s.pool[side]; ok { // another call won the race
		s.poolMu.Unlock()
		sc.Close()
		c.Close()
		old.used = time.Now()
		return fsys.Remote{C: old.sftp}, nil
	}
	s.pool[side] = &remote{ssh: c, sftp: sc, used: time.Now()}
	s.poolMu.Unlock()
	return fsys.Remote{C: sc}, nil
}

func (s *Service) dropPool(id string) {
	s.poolMu.Lock()
	r, ok := s.pool[id]
	delete(s.pool, id)
	s.poolMu.Unlock()
	if ok {
		r.sftp.Close()
		r.ssh.Close()
	}
}

// janitor closes file connections unused for 10 minutes.
func (s *Service) janitor() {
	for range time.Tick(time.Minute) {
		s.poolMu.Lock()
		for id, r := range s.pool {
			if time.Since(r.used) > 10*time.Minute {
				r.sftp.Close()
				r.ssh.Close()
				delete(s.pool, id)
			}
		}
		s.poolMu.Unlock()
	}
}

// --- terminal --------------------------------------------------------

func (s *Service) Shell(stream grpc.BidiStreamingServer[pb.ShellIn, pb.ShellOut]) error {
	first, err := stream.Recv()
	if err != nil {
		return err
	}
	open := first.GetOpen()
	if open == nil {
		return status.Error(codes.InvalidArgument, "the first message must be open")
	}
	ctx := stream.Context()
	c, err := s.dial(ctx, open.HostId)
	if err != nil {
		return mapErr(err)
	}
	defer c.Close()
	sh, err := sshc.OpenShell(c, int(open.Cols), int(open.Rows))
	if err != nil {
		return status.Error(codes.Unavailable, err.Error())
	}
	defer sh.Close()

	var sendMu sync.Mutex
	send := func(m *pb.ShellOut) error {
		sendMu.Lock()
		defer sendMu.Unlock()
		return stream.Send(m)
	}
	if err := send(&pb.ShellOut{Msg: &pb.ShellOut_Opened{Opened: true}}); err != nil {
		return err
	}
	// Keystrokes and resizes from the app.
	go func() {
		for {
			in, err := stream.Recv()
			if err != nil {
				sh.Close()
				return
			}
			switch m := in.Msg.(type) {
			case *pb.ShellIn_Data:
				if _, err := sh.Write(m.Data); err != nil {
					return
				}
			case *pb.ShellIn_Resize_:
				_ = sh.Resize(int(m.Resize.Cols), int(m.Resize.Rows))
			}
		}
	}()
	buf := make([]byte, 32<<10)
	for {
		n, err := sh.Read(buf)
		if n > 0 {
			if serr := send(&pb.ShellOut{Msg: &pb.ShellOut_Data{Data: append([]byte(nil), buf[:n]...)}}); serr != nil {
				return serr
			}
		}
		if err != nil {
			why := ""
			if err != io.EOF {
				why = err.Error()
			}
			if werr := sh.Wait(); werr != nil && why == "" {
				var exit *ssh.ExitError
				if !errors.As(werr, &exit) && !errors.Is(werr, io.EOF) {
					why = werr.Error()
				}
			}
			return send(&pb.ShellOut{Msg: &pb.ShellOut_Closed{Closed: why}})
		}
	}
}

// --- files -----------------------------------------------------------

func toEntry(e fsys.Entry) *pb.Entry {
	return &pb.Entry{Name: e.Name, Dir: e.Dir, Link: e.Link, Size: e.Size, ModifiedMs: e.Modified.UnixMilli(), Mode: uint32(e.Mode.Perm())}
}

func (s *Service) ListDir(ctx context.Context, in *pb.DirRequest) (*pb.DirListing, error) {
	f, err := s.fs(ctx, in.Side)
	if err != nil {
		return nil, mapErr(err)
	}
	p := in.Path
	if p == "" && in.Side != "" {
		if h, err := s.store.Get(in.Side); err == nil {
			p = h.StartDir
		}
	}
	if p == "" {
		if p, err = f.Home(); err != nil {
			return nil, mapErr(err)
		}
	}
	if p, err = f.Abs(p); err != nil {
		return nil, mapErr(err)
	}
	es, err := f.ReadDir(p)
	if err != nil {
		return nil, mapErr(err)
	}
	out := &pb.DirListing{Path: p}
	for _, e := range es {
		out.Entries = append(out.Entries, toEntry(e))
	}
	return out, nil
}

func (s *Service) MakeDir(ctx context.Context, in *pb.PathRequest) (*pb.Empty, error) {
	f, err := s.fs(ctx, in.Side)
	if err != nil {
		return nil, mapErr(err)
	}
	if _, err := f.Stat(in.Path); err == nil {
		return nil, status.Error(codes.AlreadyExists, in.Path+" already exists")
	}
	return &pb.Empty{}, mapErr(f.MkdirAll(in.Path))
}

func (s *Service) Remove(ctx context.Context, in *pb.PathsRequest) (*pb.Empty, error) {
	f, err := s.fs(ctx, in.Side)
	if err != nil {
		return nil, mapErr(err)
	}
	for _, p := range in.Paths {
		if p == "" || p == "/" || p == f.Dir(p) {
			return nil, status.Error(codes.InvalidArgument, "refusing to remove "+p)
		}
		if err := f.RemoveAll(p); err != nil {
			return nil, mapErr(err)
		}
	}
	return &pb.Empty{}, nil
}

func (s *Service) Rename(ctx context.Context, in *pb.RenameRequest) (*pb.Empty, error) {
	f, err := s.fs(ctx, in.Side)
	if err != nil {
		return nil, mapErr(err)
	}
	if _, err := f.Stat(in.To); err == nil {
		return nil, status.Error(codes.AlreadyExists, in.To+" already exists")
	}
	return &pb.Empty{}, mapErr(f.Rename(in.From, in.To))
}

func (s *Service) Transfer(in *pb.TransferRequest, stream grpc.ServerStreamingServer[pb.TransferProgress]) error {
	ctx := stream.Context()
	src, err := s.fs(ctx, in.SrcSide)
	if err != nil {
		return mapErr(err)
	}
	dst, err := s.fs(ctx, in.DstSide)
	if err != nil {
		return mapErr(err)
	}
	var sendErr error
	err = fsys.Transfer(ctx, src, in.SrcPaths, dst, in.DstDir, in.Move, in.Overwrite, in.SrcSide == in.DstSide,
		func(p fsys.Progress) {
			if sendErr == nil {
				sendErr = stream.Send(progress(p, false))
			}
		})
	if err != nil {
		return mapErr(err)
	}
	if sendErr != nil {
		return sendErr
	}
	return stream.Send(&pb.TransferProgress{Finished: true})
}

func progress(p fsys.Progress, done bool) *pb.TransferProgress {
	return &pb.TransferProgress{
		DoneBytes: p.DoneBytes, TotalBytes: p.TotalBytes,
		DoneFiles: int32(p.DoneFiles), TotalFiles: int32(p.TotalFiles),
		Current: p.Current, Finished: done,
	}
}

// --- Shard -------------------------------------------------------

func (s *Service) EnableSync(ctx context.Context, _ *pb.Empty) (*pb.SyncState, error) {
	st, err := s.sync.Enable(ctx)
	if err != nil {
		return nil, status.Error(codes.FailedPrecondition, err.Error())
	}
	return syncState(st), nil
}

func (s *Service) DisableSync(ctx context.Context, _ *pb.Empty) (*pb.SyncState, error) {
	return syncState(s.sync.Disable(ctx)), nil
}

func (s *Service) SyncNow(ctx context.Context, _ *pb.Empty) (*pb.SyncState, error) {
	s.sync.Round(ctx)
	return syncState(s.sync.Status()), nil
}

func (s *Service) RequestAccess(ctx context.Context, _ *pb.Empty) (*pb.SyncState, error) {
	st, err := s.sync.RequestAccess(ctx)
	if err != nil {
		return nil, status.Error(codes.FailedPrecondition, err.Error())
	}
	return syncState(st), nil
}

func (s *Service) SafeKeys(ctx context.Context, _ *pb.Empty) (*pb.SafeKeyList, error) {
	keys, err := s.sync.SafeKeys(ctx)
	if err != nil {
		return &pb.SafeKeyList{Unavailable: err.Error()}, nil
	}
	out := &pb.SafeKeyList{}
	for _, k := range keys {
		title := k.Title
		if k.Group != "" {
			title = k.Group + " / " + title
		}
		out.Keys = append(out.Keys, &pb.SafeKey{
			Id: k.Id, Title: title, KeyType: k.KeyType, Fingerprint: k.Fingerprint,
			PublicKey: k.PublicKey, Comment: k.Comment,
		})
	}
	return out, nil
}
