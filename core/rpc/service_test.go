package rpc

import (
	"bytes"
	"context"
	"crypto/ed25519"
	"crypto/rand"
	"encoding/binary"
	"io"
	"net"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/pkg/sftp"
	"golang.org/x/crypto/ssh"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"sshmanager/core/cloudsync"
	cpb "sshmanager/core/cloudsync/pb"
	"sshmanager/core/fsys"
	"sshmanager/core/hosts"
	"sshmanager/core/rpc/pb"
)

// testSSHD is a tiny SSH server: password "secret", an echo shell and the
// sftp subsystem over the real file system.
func testSSHD(t *testing.T) (addr string, port int) {
	t.Helper()
	_, priv, _ := ed25519.GenerateKey(rand.Reader)
	signer, err := ssh.NewSignerFromKey(priv)
	if err != nil {
		t.Fatal(err)
	}
	cfg := &ssh.ServerConfig{
		PasswordCallback: func(c ssh.ConnMetadata, pw []byte) (*ssh.Permissions, error) {
			if c.User() == "tester" && string(pw) == "secret" {
				return nil, nil
			}
			return nil, io.EOF
		},
	}
	cfg.AddHostKey(signer)
	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { lis.Close() })
	go func() {
		for {
			c, err := lis.Accept()
			if err != nil {
				return
			}
			go serveConn(c, cfg)
		}
	}()
	host, p, _ := net.SplitHostPort(lis.Addr().String())
	port, _ = strconv.Atoi(p)
	return host, port
}

func serveConn(c net.Conn, cfg *ssh.ServerConfig) {
	_, chans, reqs, err := ssh.NewServerConn(c, cfg)
	if err != nil {
		return
	}
	go ssh.DiscardRequests(reqs)
	for nc := range chans {
		if nc.ChannelType() != "session" {
			nc.Reject(ssh.UnknownChannelType, "no")
			continue
		}
		ch, in, err := nc.Accept()
		if err != nil {
			continue
		}
		go func() {
			for req := range in {
				switch req.Type {
				case "pty-req", "window-change", "env":
					req.Reply(true, nil)
				case "shell":
					req.Reply(true, nil)
					go func() {
						ch.Write([]byte("welcome\r\n"))
						io.Copy(ch, ch) // echo
						ch.SendRequest("exit-status", false, binary.BigEndian.AppendUint32(nil, 0))
						ch.Close()
					}()
				case "subsystem":
					if len(req.Payload) > 4 && string(req.Payload[4:]) == "sftp" {
						req.Reply(true, nil)
						go func() {
							srv, _ := sftp.NewServer(ch)
							srv.Serve()
							ch.Close()
						}()
					} else {
						req.Reply(false, nil)
					}
				default:
					req.Reply(false, nil)
				}
			}
		}()
	}
}

type noCloudSync struct{}

func (noCloudSync) Dial(context.Context) (cpb.ConnectorClient, io.Closer, error) {
	return nil, nil, cloudsync.ErrNotRunning
}

func client(t *testing.T) (pb.CoreClient, context.Context) {
	t.Helper()
	dir := t.TempDir()
	store, err := hosts.Open(filepath.Join(dir, "hosts.json"))
	if err != nil {
		t.Fatal(err)
	}
	syncer, err := cloudsync.New(noCloudSync{}, store, filepath.Join(dir, "cs.json"), "test")
	if err != nil {
		t.Fatal(err)
	}
	svc := New(store, syncer, fsys.Local{HomeDir: dir}, "test")
	t.Cleanup(svc.Close)
	sock := filepath.Join(dir, "core.sock")
	lis, err := net.Listen("unix", sock)
	if err != nil {
		t.Fatal(err)
	}
	srv := grpc.NewServer(TokenAuth("tok")...)
	pb.RegisterCoreServer(srv, svc)
	go srv.Serve(lis)
	t.Cleanup(srv.Stop)
	cc, err := grpc.NewClient("unix://"+sock, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { cc.Close() })
	ctx := metadata.AppendToOutgoingContext(context.Background(), "authorization", "Bearer tok")
	return pb.NewCoreClient(cc), ctx
}

func TestEndToEnd(t *testing.T) {
	addr, port := testSSHD(t)
	c, ctx := client(t)

	if _, err := c.ListHosts(context.Background(), &pb.Empty{}); status.Code(err) != codes.Unauthenticated {
		t.Fatalf("a call without the token must fail, got %v", err)
	}
	h, err := c.SaveHost(ctx, &pb.Host{Name: "test", Address: addr, Port: uint32(port), User: "tester", Auth: pb.Host_PASSWORD, Password: "secret"})
	if err != nil {
		t.Fatal(err)
	}

	// Unknown key: connections are refused until the user trusts it.
	if _, err := c.ListDir(ctx, &pb.DirRequest{Side: h.Id, Path: "/"}); status.Code(err) != codes.FailedPrecondition {
		t.Fatalf("untrusted host: %v", err)
	}
	k, err := c.ProbeHostKey(ctx, &pb.HostRef{Id: h.Id})
	if err != nil || k.Status != pb.HostKey_UNKNOWN || !strings.HasPrefix(k.Fingerprint, "SHA256:") {
		t.Fatalf("probe: %v %+v", err, k)
	}
	if _, err := c.TrustHostKey(ctx, &pb.TrustRequest{Id: h.Id, Key: k.Key}); err != nil {
		t.Fatal(err)
	}
	if k, _ := c.ProbeHostKey(ctx, &pb.HostRef{Id: h.Id}); k.Status != pb.HostKey_KNOWN {
		t.Fatalf("after trust: %+v", k)
	}

	// Files: copy a local folder to the server, list it, move it back.
	src := filepath.Join(t.TempDir(), "proj")
	os.MkdirAll(filepath.Join(src, "sub"), 0o755)
	os.WriteFile(filepath.Join(src, "a.txt"), []byte("hello"), 0o644)
	os.WriteFile(filepath.Join(src, "sub", "b.bin"), bytes.Repeat([]byte{7}, 1<<20), 0o644)
	remoteDir := t.TempDir() // the test server serves this machine's files
	stream, err := c.Transfer(ctx, &pb.TransferRequest{SrcSide: "", SrcPaths: []string{src}, DstSide: h.Id, DstDir: remoteDir})
	if err != nil {
		t.Fatal(err)
	}
	var last *pb.TransferProgress
	for {
		p, err := stream.Recv()
		if err == io.EOF {
			break
		}
		if err != nil {
			t.Fatal(err)
		}
		last = p
	}
	if !last.Finished {
		t.Fatal("transfer did not finish")
	}
	got, err := os.ReadFile(filepath.Join(remoteDir, "proj", "sub", "b.bin"))
	if err != nil || len(got) != 1<<20 {
		t.Fatalf("copied file: %v %d", err, len(got))
	}
	ls, err := c.ListDir(ctx, &pb.DirRequest{Side: h.Id, Path: filepath.Join(remoteDir, "proj")})
	if err != nil || len(ls.Entries) != 2 || !ls.Entries[0].Dir || ls.Entries[0].Name != "sub" {
		t.Fatalf("remote listing: %v %+v", err, ls)
	}
	// Copying again without overwrite is refused.
	stream, _ = c.Transfer(ctx, &pb.TransferRequest{SrcPaths: []string{src}, DstSide: h.Id, DstDir: remoteDir})
	if _, err := stream.Recv(); status.Code(err) != codes.AlreadyExists {
		t.Fatalf("second copy: %v", err)
	}
	if _, err := c.Rename(ctx, &pb.RenameRequest{Side: h.Id, From: filepath.Join(remoteDir, "proj", "a.txt"), To: filepath.Join(remoteDir, "proj", "c.txt")}); err != nil {
		t.Fatal(err)
	}
	if _, err := c.Remove(ctx, &pb.PathsRequest{Side: h.Id, Paths: []string{filepath.Join(remoteDir, "proj")}}); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(remoteDir, "proj")); !os.IsNotExist(err) {
		t.Fatal("remove did not remove")
	}

	// Terminal.
	sh, err := c.Shell(ctx)
	if err != nil {
		t.Fatal(err)
	}
	sh.Send(&pb.ShellIn{Msg: &pb.ShellIn_Open_{Open: &pb.ShellIn_Open{HostId: h.Id, Cols: 80, Rows: 24}}})
	first, err := sh.Recv()
	if err != nil || !first.GetOpened() {
		t.Fatalf("open: %v %+v", err, first)
	}
	sh.Send(&pb.ShellIn{Msg: &pb.ShellIn_Resize_{Resize: &pb.ShellIn_Resize{Cols: 100, Rows: 30}}})
	sh.Send(&pb.ShellIn{Msg: &pb.ShellIn_Data{Data: []byte("ping")}})
	var out []byte
	deadline := time.Now().Add(5 * time.Second)
	for !bytes.Contains(out, []byte("ping")) && time.Now().Before(deadline) {
		m, err := sh.Recv()
		if err != nil {
			t.Fatal(err)
		}
		out = append(out, m.GetData()...)
	}
	if !bytes.Contains(out, []byte("welcome")) || !bytes.Contains(out, []byte("ping")) {
		t.Fatalf("shell output %q", out)
	}
	sh.CloseSend()

	// Wrong password.
	h.Password = "nope"
	h, _ = c.SaveHost(ctx, h)
	c.TrustHostKey(ctx, &pb.TrustRequest{Id: h.Id, Key: k.Key})
	if _, err := c.ListDir(ctx, &pb.DirRequest{Side: h.Id}); err == nil || !strings.Contains(err.Error(), "refused the login") {
		t.Fatalf("wrong password: %v", err)
	}
}
