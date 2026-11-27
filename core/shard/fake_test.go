package shard

import (
	"context"
	"fmt"
	"io"
	"slices"
	"strconv"
	"sync"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"

	"github.com/SelfHold/postern/core/shard/pb"
)

// fakeVault is one Shard vault shared by several fake devices.
type fakeVault struct {
	mu      sync.Mutex
	seq     int
	records map[string]*pb.Item
	servers map[string]*pb.Server
	changes []fakeChange
	keys    []*pb.SshKey
	scopes  []string // granted on approval
	paired  map[string]bool
	pending map[string]string // ticket → token, approved at once
}

type fakeChange struct {
	seq     int
	id, rev string
	deleted bool
}

func newVault(scopes ...string) *fakeVault {
	return &fakeVault{records: map[string]*pb.Item{}, servers: map[string]*pb.Server{},
		scopes: scopes, paired: map[string]bool{}, pending: map[string]string{}}
}

func (v *fakeVault) rev() string { v.seq++; return "r" + strconv.Itoa(v.seq) }

// fakeDevice is Shard on one device.
type fakeDevice struct {
	v       *fakeVault
	name    string
	offline bool
}

func (d *fakeDevice) Dial(context.Context) (pb.ConnectorClient, io.Closer, error) {
	return &fakeClient{d: d}, io.NopCloser(nil), nil
}

type fakeClient struct {
	pb.ConnectorClient // unused methods panic
	d                  *fakeDevice
}

func token(ctx context.Context) string {
	md, _ := metadata.FromOutgoingContext(ctx)
	if v := md.Get("authorization"); len(v) > 0 {
		return v[0][len("Bearer "):]
	}
	return ""
}

func (c *fakeClient) auth(ctx context.Context) error {
	if !c.d.v.paired[token(ctx)] {
		return status.Error(codes.Unauthenticated, "not paired")
	}
	return nil
}

func (c *fakeClient) write() error {
	if c.d.offline {
		return status.Error(codes.Unavailable, "offline")
	}
	return nil
}

func (c *fakeClient) Hello(ctx context.Context, _ *pb.HelloRequest, _ ...grpc.CallOption) (*pb.HelloReply, error) {
	v := c.d.v
	v.mu.Lock()
	defer v.mu.Unlock()
	st := pb.VaultState_READY
	if c.d.offline {
		st = pb.VaultState_OFFLINE
	}
	r := &pb.HelloReply{ApiVersion: 1, State: st, VaultId: "vault", DeviceName: c.d.name, Paired: v.paired[token(ctx)]}
	if r.Paired {
		r.Scopes = v.scopes
	}
	return r, nil
}

func (c *fakeClient) RequestPairing(_ context.Context, in *pb.PairingRequest, _ ...grpc.CallOption) (*pb.PairingTicket, error) {
	v := c.d.v
	v.mu.Lock()
	defer v.mu.Unlock()
	t := "t" + v.rev()
	v.pending[t] = "tok-" + c.d.name + t
	return &pb.PairingTicket{Ticket: t, Code: "123456", ExpiresUnixMs: time.Now().Add(time.Minute).UnixMilli()}, nil
}

func (c *fakeClient) AwaitPairing(_ context.Context, in *pb.AwaitPairingRequest, _ ...grpc.CallOption) (*pb.PairingResult, error) {
	v := c.d.v
	v.mu.Lock()
	defer v.mu.Unlock()
	tok, ok := v.pending[in.Ticket]
	if !ok {
		return &pb.PairingResult{Status: pb.PairingStatus_EXPIRED}, nil
	}
	delete(v.pending, in.Ticket)
	v.paired[tok] = true
	return &pb.PairingResult{Status: pb.PairingStatus_APPROVED, Token: tok, Scopes: v.scopes}, nil
}

func (c *fakeClient) Unpair(ctx context.Context, _ *pb.UnpairRequest, _ ...grpc.CallOption) (*pb.UnpairReply, error) {
	c.d.v.mu.Lock()
	delete(c.d.v.paired, token(ctx))
	c.d.v.mu.Unlock()
	return &pb.UnpairReply{}, nil
}

func (c *fakeClient) Watch(context.Context, *pb.WatchRequest, ...grpc.CallOption) (grpc.ServerStreamingClient[pb.Change], error) {
	return nil, status.Error(codes.Unimplemented, "no watch in the fake")
}

func (c *fakeClient) Get(ctx context.Context, in *pb.GetRequest, _ ...grpc.CallOption) (*pb.Item, error) {
	if err := c.auth(ctx); err != nil {
		return nil, err
	}
	v := c.d.v
	v.mu.Lock()
	defer v.mu.Unlock()
	if it, ok := v.records[in.Key]; ok {
		return proto.Clone(it).(*pb.Item), nil
	}
	return &pb.Item{Key: in.Key}, nil
}

func (c *fakeClient) Put(ctx context.Context, in *pb.PutRequest, _ ...grpc.CallOption) (*pb.Item, error) {
	if err := c.auth(ctx); err != nil {
		return nil, err
	}
	if err := c.write(); err != nil {
		return nil, err
	}
	v := c.d.v
	v.mu.Lock()
	defer v.mu.Unlock()
	cur := v.records[in.Key]
	if (cur == nil && in.Base != "") || (cur != nil && cur.Revision != in.Base) {
		return nil, status.Error(codes.Aborted, "stale base")
	}
	r := v.rev()
	it := &pb.Item{Key: in.Key, Revision: r, Versions: []*pb.Version{{Id: r, Data: in.Data, DeviceName: c.d.name}}}
	v.records[in.Key] = it
	return proto.Clone(it).(*pb.Item), nil
}

// concurrent puts two versions as if two devices wrote offline.
func (v *fakeVault) concurrent(key string, a, b []byte) {
	v.mu.Lock()
	defer v.mu.Unlock()
	r := v.rev()
	v.records[key] = &pb.Item{Key: key, Revision: r, Versions: []*pb.Version{{Id: r + "a", Data: a}, {Id: r + "b", Data: b}}}
}

func (c *fakeClient) scope(ctx context.Context, s string) error {
	if err := c.auth(ctx); err != nil {
		return err
	}
	if !slices.Contains(c.d.v.scopes, s) {
		return status.Error(codes.PermissionDenied, "no scope")
	}
	return nil
}

func (v *fakeVault) logChange(id, rev string, deleted bool) {
	v.changes = append(v.changes, fakeChange{seq: v.seq, id: id, rev: rev, deleted: deleted})
}

func (c *fakeClient) ListServers(ctx context.Context, in *pb.ListServersRequest, _ ...grpc.CallOption) (*pb.ListServersReply, error) {
	if err := c.scope(ctx, ScopeServers); err != nil {
		return nil, err
	}
	v := c.d.v
	v.mu.Lock()
	defer v.mu.Unlock()
	r := &pb.ListServersReply{Cursor: strconv.Itoa(v.seq)}
	for _, id := range slices.Sorted(mapKeys(v.servers)) {
		r.Servers = append(r.Servers, proto.Clone(v.servers[id]).(*pb.Server))
	}
	return r, nil
}

func (c *fakeClient) GetServers(ctx context.Context, in *pb.GetServersRequest, _ ...grpc.CallOption) (*pb.ListServersReply, error) {
	if err := c.scope(ctx, ScopeServers); err != nil {
		return nil, err
	}
	v := c.d.v
	v.mu.Lock()
	defer v.mu.Unlock()
	r := &pb.ListServersReply{}
	for _, id := range in.Ids {
		if sv, ok := v.servers[id]; ok {
			r.Servers = append(r.Servers, proto.Clone(sv).(*pb.Server))
		}
	}
	return r, nil
}

func (c *fakeClient) PutServer(ctx context.Context, in *pb.PutServerRequest, _ ...grpc.CallOption) (*pb.Server, error) {
	if err := c.scope(ctx, ScopeServers); err != nil {
		return nil, err
	}
	if err := c.write(); err != nil {
		return nil, err
	}
	v := c.d.v
	v.mu.Lock()
	defer v.mu.Unlock()
	sv := proto.Clone(in.Server).(*pb.Server)
	if sv.Id == "" {
		if in.Base != "" {
			return nil, status.Error(codes.Aborted, "stale base")
		}
		sv.Id = fmt.Sprintf("srv%d", v.seq+1)
	} else if cur, ok := v.servers[sv.Id]; !ok || cur.Revision != in.Base {
		return nil, status.Error(codes.Aborted, "stale base")
	}
	sv.Revision = v.rev()
	sv.ModifiedMs = time.Now().UnixMilli()
	sv.DeviceName = c.d.name
	v.servers[sv.Id] = sv
	v.logChange(sv.Id, sv.Revision, false)
	return proto.Clone(sv).(*pb.Server), nil
}

func (c *fakeClient) DeleteServer(ctx context.Context, in *pb.DeleteServerRequest, _ ...grpc.CallOption) (*pb.DeleteServerReply, error) {
	if err := c.scope(ctx, ScopeServers); err != nil {
		return nil, err
	}
	if err := c.write(); err != nil {
		return nil, err
	}
	v := c.d.v
	v.mu.Lock()
	defer v.mu.Unlock()
	cur, ok := v.servers[in.Id]
	if !ok {
		return nil, status.Error(codes.NotFound, "no such server")
	}
	if cur.Revision != in.Base {
		return nil, status.Error(codes.Aborted, "stale base")
	}
	delete(v.servers, in.Id)
	v.logChange(in.Id, v.rev(), true)
	return &pb.DeleteServerReply{}, nil
}

func (c *fakeClient) ListServerChanges(ctx context.Context, in *pb.ListChangesRequest, _ ...grpc.CallOption) (*pb.ListChangesReply, error) {
	if err := c.scope(ctx, ScopeServers); err != nil {
		return nil, err
	}
	v := c.d.v
	v.mu.Lock()
	defer v.mu.Unlock()
	from, err := strconv.Atoi(in.Cursor)
	if err != nil {
		return &pb.ListChangesReply{Reset_: true}, nil
	}
	r := &pb.ListChangesReply{Cursor: strconv.Itoa(v.seq)}
	for _, ch := range v.changes {
		if ch.seq > from {
			r.Changes = append(r.Changes, &pb.LoginChange{Id: ch.id, Revision: ch.rev, Deleted: ch.deleted})
		}
	}
	return r, nil
}

func (c *fakeClient) ListSshKeys(ctx context.Context, _ *pb.ListSshKeysRequest, _ ...grpc.CallOption) (*pb.ListSshKeysReply, error) {
	if err := c.scope(ctx, ScopeSSHKeys); err != nil {
		return nil, err
	}
	r := &pb.ListSshKeysReply{}
	for _, k := range c.d.v.keys {
		k := proto.Clone(k).(*pb.SshKey)
		k.PrivateKey, k.Passphrase = "", ""
		r.Keys = append(r.Keys, k)
	}
	return r, nil
}

func (c *fakeClient) GetSshKeys(ctx context.Context, in *pb.GetSshKeysRequest, _ ...grpc.CallOption) (*pb.ListSshKeysReply, error) {
	if err := c.scope(ctx, ScopeSSHKeys); err != nil {
		return nil, err
	}
	r := &pb.ListSshKeysReply{}
	for _, k := range c.d.v.keys {
		if slices.Contains(in.Ids, k.Id) {
			r.Keys = append(r.Keys, proto.Clone(k).(*pb.SshKey))
		}
	}
	return r, nil
}

func mapKeys[M ~map[K]V, K comparable, V any](m M) func(func(K) bool) {
	return func(yield func(K) bool) {
		for k := range m {
			if !yield(k) {
				return
			}
		}
	}
}
