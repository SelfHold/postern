// Command desktopbind is the core of the desktop app, built as a C archive
// and linked into the app's executable (app/linux/CMakeLists.txt). Dart
// calls it through FFI (app/lib/data/native_core.dart) and then talks to it
// over the gRPC API, like the Android app does with mobilebind.
//
// It writes endpoint.json to the config dir, so a second instance of the
// app connects to the core of the first one.
package main

/*
#include <stdlib.h>
*/
import "C"

import (
	"encoding/json"
	"errors"
	"path/filepath"
	"sync"
	"time"
	"unsafe"

	"github.com/SelfHold/postern/core/embed"
)

var (
	mu   sync.Mutex
	core *embed.Core
)

type reply struct {
	Address string `json:"address,omitempty"`
	Token   string `json:"token,omitempty"`
	// The core runs in another instance of the app; address and token are its.
	External bool   `json:"external,omitempty"`
	Error    string `json:"error,omitempty"`
}

// PosternStart starts the core (again: returns the running one) and returns
// JSON {"address","token"} or {"error"}; free it with PosternFree.
//
//export PosternStart
func PosternStart() *C.char {
	return cjson(start())
}

func start() reply {
	mu.Lock()
	defer mu.Unlock()
	if core != nil {
		return reply{Address: core.Address, Token: core.Token}
	}
	dir := embed.DefaultDir()
	endpoint := filepath.Join(dir, "endpoint.json")
	c, err := embed.Start(embed.Options{Dir: dir, Listen: embed.DefaultListen(dir), Endpoint: endpoint})
	if errors.Is(err, embed.ErrRunning) {
		if addr, token, ok := embed.ReadEndpoint(endpoint); ok {
			return reply{Address: addr, Token: token, External: true}
		}
	}
	if err != nil {
		return reply{Error: err.Error()}
	}
	core = c
	return reply{Address: c.Address, Token: c.Token}
}

// PosternStop closes the SSH connections and stops the server. It is called
// right before the process exits and never waits longer than 5 s.
//
//export PosternStop
func PosternStop() {
	mu.Lock()
	defer mu.Unlock()
	if core == nil {
		return
	}
	c := core
	core = nil
	done := make(chan struct{})
	go func() { c.Stop(); close(done) }()
	select {
	case <-done:
	case <-time.After(5 * time.Second):
	}
}

// PosternFree frees a string returned by PosternStart.
//
//export PosternFree
func PosternFree(p *C.char) {
	C.free(unsafe.Pointer(p))
}

func cjson(r reply) *C.char {
	b, _ := json.Marshal(r)
	return C.CString(string(b))
}

func main() {}
