// Package cloudsync keeps the host list in CloudSync through its Connector
// API (CONNECTOR.md): one record, "hosts.json", whose bytes are the local
// hosts file. The local file stays the working copy; CloudSync is optional
// and may come and go at any time.
package cloudsync

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"path/filepath"
	"strings"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	"sshmanager/core/cloudsync/pb"
)

// ErrNotRunning means CloudSync is not installed or its daemon is stopped.
var ErrNotRunning = errors.New("CloudSync is not running")

// APIVersion this client speaks.
const APIVersion = 1

// Dialer opens a connection to CloudSync. Desktop: the gRPC socket named
// in connector.json. Android: the bound service, adapted in mobilebind.
type Dialer interface {
	Dial(ctx context.Context) (pb.ConnectorClient, io.Closer, error)
}

// DesktopDialer finds cloudsyncd through connector.json.
type DesktopDialer struct {
	// Path of connector.json; "" = <user config dir>/cloudsync/connector.json.
	Path string
}

// DefaultConnectorFile is where cloudsyncd writes its address.
func DefaultConnectorFile() string {
	dir, err := os.UserConfigDir()
	if err != nil {
		dir = filepath.Join(os.Getenv("HOME"), ".config")
	}
	return filepath.Join(dir, "cloudsync", "connector.json")
}

type connectorFile struct {
	Address    string `json:"address"`
	APIVersion int    `json:"api_version"`
}

// Dial implements Dialer.
func (d DesktopDialer) Dial(ctx context.Context) (pb.ConnectorClient, io.Closer, error) {
	path := d.Path
	if path == "" {
		path = DefaultConnectorFile()
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, nil, ErrNotRunning
	}
	var f connectorFile
	if err := json.Unmarshal(data, &f); err != nil || f.Address == "" {
		return nil, nil, ErrNotRunning
	}
	if f.APIVersion > APIVersion {
		return nil, nil, fmt.Errorf("CloudSync speaks API v%d, this app v%d: update the app", f.APIVersion, APIVersion)
	}
	network, addr := "tcp", f.Address
	if p, ok := strings.CutPrefix(f.Address, "unix://"); ok {
		network, addr = "unix", p
	}
	// A socket that refuses connections = not running; find out now rather
	// than on the first call.
	c, err := (&net.Dialer{}).DialContext(ctx, network, addr)
	if err != nil {
		return nil, nil, ErrNotRunning
	}
	c.Close()
	cc, err := grpc.NewClient("passthrough:///cloudsync",
		grpc.WithTransportCredentials(insecure.NewCredentials()),
		grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) {
			return (&net.Dialer{}).DialContext(ctx, network, addr)
		}))
	if err != nil {
		return nil, nil, err
	}
	return pb.NewConnectorClient(cc), cc, nil
}
