// Package mobilebind runs the core inside the Android app ("gomobile
// bind" → AAR, like CloudSync's and MegaChat's). Kotlin starts it from a
// foreground service and hands the socket path and token to Flutter, which
// talks to it over the same gRPC API as on desktops (core/embed). CloudSync
// is reached through its bound service: Kotlin implements Connector (one
// call() per method, CONNECTOR.md § 3.2).
package mobilebind

import (
	"os"
	"sync"

	"sshmanager/core/cloudsync"
	"sshmanager/core/embed"
)

// Connector is ICloudSyncConnector.call, implemented in Kotlin. It returns
// the serialized CallReply.
type Connector interface {
	Call(method string, request []byte) ([]byte, error)
}

var (
	mu   sync.Mutex
	core *embed.Core
	conn Connector
)

// SetConnector gives the core CloudSync's bound service (nil when it is
// not installed or got unbound).
func SetConnector(c Connector) {
	mu.Lock()
	conn = c
	mu.Unlock()
}

func caller() cloudsync.Caller {
	mu.Lock()
	defer mu.Unlock()
	if conn == nil {
		return nil
	}
	return conn
}

// Start runs the core: hosts and sync state live in dataDir, the file
// manager starts in filesDir, gRPC listens on the unix socket sock. It
// returns the bearer token; calling it again returns the same token.
func Start(dataDir, filesDir, sock string) (string, error) {
	mu.Lock()
	defer mu.Unlock()
	if core != nil {
		return core.Token, nil
	}
	os.Setenv("HOME", dataDir) // Android has none
	c, err := embed.Start(embed.Options{
		Dir:       dataDir,
		Platform:  "android",
		Listen:    "unix:" + sock,
		Home:      filesDir,
		CloudSync: cloudsync.BinderDialer{Get: caller},
	})
	if err != nil {
		return "", err
	}
	core = c
	return c.Token, nil
}

// Stop ends the core (the service is being destroyed).
func Stop() {
	mu.Lock()
	c := core
	core = nil
	mu.Unlock()
	if c != nil {
		c.Stop()
	}
}
