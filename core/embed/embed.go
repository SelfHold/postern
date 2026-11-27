// Package embed runs the core inside the app's own process: the Flutter
// app on desktops (desktopbind, linked into the executable) and on Android
// (mobilebind). The app talks to it over the gRPC API through a private
// unix socket and a bearer token. There is no separate daemon: sessions and
// transfers live as long as the app.
package embed

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"google.golang.org/grpc"

	"github.com/SelfHold/postern/core/fsys"
	"github.com/SelfHold/postern/core/hosts"
	"github.com/SelfHold/postern/core/rpc"
	"github.com/SelfHold/postern/core/rpc/pb"
	"github.com/SelfHold/postern/core/shard"
)

// Options say where the core keeps its files and listens.
type Options struct {
	Dir      string // hosts.json, shard.json
	Platform string // runtime.GOOS when empty
	Listen   string // unix:PATH
	// Endpoint, when set, is where address and token are written
	// ({"address": "unix:///…", "token": "…"}, readable only by the user).
	// An endpoint there that still answers means another app instance runs
	// the core: Start returns ErrRunning.
	Endpoint string
	// Home is the first folder of the file manager on this device (""
	// = the user's home).
	Home string
	// Shard reaches Shard (CONNECTOR.md); nil: its desktop daemon.
	Shard shard.Dialer
}

// Core is a running core.
type Core struct {
	Service *rpc.Service
	Address string // unix:///path
	Token   string

	srv    *grpc.Server
	cancel context.CancelFunc
	opts   Options
}

// ErrRunning: another process of this user already runs the core.
var ErrRunning = errors.New("Postern is already running")

// Start opens the socket and serves the API.
func Start(o Options) (*Core, error) {
	if o.Platform == "" {
		o.Platform = runtime.GOOS
	}
	if err := os.MkdirAll(o.Dir, 0o700); err != nil {
		return nil, err
	}
	if o.Endpoint != "" {
		if _, _, ok := ReadEndpoint(o.Endpoint); ok {
			return nil, ErrRunning
		}
	}
	lis, err := listenOn(o.Listen)
	if err != nil {
		return nil, err
	}
	fail := func(err error) (*Core, error) {
		lis.Close()
		return nil, err
	}
	store, err := hosts.Open(filepath.Join(o.Dir, "hosts.json"))
	if err != nil {
		return fail(err)
	}
	d := o.Shard
	if d == nil {
		d = shard.DesktopDialer{}
	}
	desc := fmt.Sprintf("%s %s on %s", shard.AppName, rpc.Version, o.Platform)
	syncer, err := shard.New(d, store, filepath.Join(o.Dir, "shard.json"), desc)
	if err != nil {
		return fail(err)
	}
	var b [32]byte
	if _, err := rand.Read(b[:]); err != nil {
		return fail(err)
	}
	c := &Core{
		Service: rpc.New(store, syncer, fsys.Local{HomeDir: o.Home}, o.Platform),
		Address: "unix://" + lis.Addr().String(),
		Token:   hex.EncodeToString(b[:]),
		opts:    o,
	}
	if o.Endpoint != "" {
		if err := writeEndpoint(o.Endpoint, c.Address, c.Token); err != nil {
			return fail(err)
		}
	}
	c.srv = grpc.NewServer(rpc.TokenAuth(c.Token)...)
	pb.RegisterCoreServer(c.srv, c.Service)
	var ctx context.Context
	ctx, c.cancel = context.WithCancel(context.Background())
	go syncer.Run(ctx)
	go c.srv.Serve(lis)
	return c, nil
}

// Stop closes the connections and stops the server.
func (c *Core) Stop() {
	c.cancel()
	c.Service.Close()
	// Open Events/Shell streams would hold GracefulStop forever.
	stopped := make(chan struct{})
	go func() { c.srv.GracefulStop(); close(stopped) }()
	select {
	case <-stopped:
	case <-time.After(3 * time.Second):
		c.srv.Stop()
	}
	if c.opts.Endpoint != "" {
		if addr, _, _ := readEndpointFile(c.opts.Endpoint); addr == c.Address {
			os.Remove(c.opts.Endpoint)
		}
	}
	os.Remove(strings.TrimPrefix(c.opts.Listen, "unix:"))
}

// DefaultDir is where the desktop core keeps its files: the user's config
// dir/selfhold/postern (~/.config/selfhold/postern).
func DefaultDir() string {
	cfg, err := os.UserConfigDir()
	if err != nil {
		cfg = "."
	}
	return filepath.Join(cfg, "selfhold", "postern")
}

// DefaultListen is the desktop socket: $XDG_RUNTIME_DIR/selfhold-postern.sock.
func DefaultListen(dir string) string {
	d := os.Getenv("XDG_RUNTIME_DIR")
	if d == "" {
		d = dir
	}
	return "unix:" + filepath.Join(d, "selfhold-postern.sock")
}

// ReadEndpoint reads an endpoint file and says whether the core there
// answers.
func ReadEndpoint(path string) (address, token string, ok bool) {
	address, token, err := readEndpointFile(path)
	if err != nil || !strings.HasPrefix(address, "unix://") {
		return "", "", false
	}
	conn, err := net.DialTimeout("unix", strings.TrimPrefix(address, "unix://"), 2*time.Second)
	if err != nil {
		return address, token, false
	}
	conn.Close()
	return address, token, true
}

func readEndpointFile(path string) (address, token string, err error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", "", err
	}
	var ep struct{ Address, Token string }
	if err := json.Unmarshal(data, &ep); err != nil {
		return "", "", err
	}
	return ep.Address, ep.Token, nil
}

func listenOn(addr string) (net.Listener, error) {
	p, ok := strings.CutPrefix(addr, "unix:")
	if !ok {
		return nil, fmt.Errorf("bad listen address %q", addr)
	}
	if len(p) > 100 {
		return nil, fmt.Errorf("socket path too long for unix sockets (%d bytes): %s", len(p), p)
	}
	if err := os.MkdirAll(filepath.Dir(p), 0o700); err != nil {
		return nil, err
	}
	if c, err := net.Dial("unix", p); err == nil {
		c.Close()
		return nil, ErrRunning
	}
	os.Remove(p)
	l, err := net.Listen("unix", p)
	if err == nil {
		os.Chmod(p, 0o600)
	}
	return l, err
}

func writeEndpoint(path, address, token string) error {
	data, _ := json.MarshalIndent(map[string]string{"address": address, "token": token}, "", "  ")
	return hosts.WriteAtomic(path, data)
}
