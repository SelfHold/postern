package embed

import (
	"context"
	"errors"
	"io"
	"os"
	"path/filepath"
	"testing"

	"sshmanager/core/cloudsync"
	"sshmanager/core/cloudsync/pb"
)

// noCloudSync keeps tests away from a CloudSync running on this machine.
type noCloudSync struct{}

func (noCloudSync) Dial(context.Context) (pb.ConnectorClient, io.Closer, error) {
	return nil, nil, cloudsync.ErrNotRunning
}

func TestStartStop(t *testing.T) {
	dir := t.TempDir()
	o := Options{Dir: dir, Listen: "unix:" + filepath.Join(dir, "s.sock"), Endpoint: filepath.Join(dir, "endpoint.json"), CloudSync: noCloudSync{}}
	c, err := Start(o)
	if err != nil {
		t.Fatal(err)
	}
	if addr, tok, ok := ReadEndpoint(o.Endpoint); !ok || addr != c.Address || tok != c.Token {
		t.Fatalf("endpoint: %q %v", addr, ok)
	}
	// A second instance finds the first one.
	if _, err := Start(o); !errors.Is(err, ErrRunning) {
		t.Fatalf("second start: %v", err)
	}
	c.Stop()
	if _, err := os.Stat(o.Endpoint); !os.IsNotExist(err) {
		t.Fatal("endpoint.json must go with the core")
	}
	// After it stopped, a new core starts.
	c2, err := Start(o)
	if err != nil {
		t.Fatal(err)
	}
	c2.Stop()
}
