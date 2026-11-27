# SSH Manager

A simple SSH manager for Linux (Android later):

- **Hosts**: a list of servers with password, pasted key, ssh-agent or a key from the
  CloudSync safe. The server's key is checked on the first connection and when it changes.
- **Terminal**: tabs of SSH sessions (xterm-256color). Ctrl+Shift+C / Ctrl+Shift+V copy
  and paste; on phones there is a bar with Esc, Tab, Ctrl and arrow keys.
- **Files**: two panels in the spirit of Midnight Commander. Each panel shows this device
  or any host, so you can copy between this device and a server, or between two servers.
  Keys: `Tab` switches panels, `Enter` opens, `Backspace` goes up, `Ins`/`Space` selects,
  `F5` copies, `F6` moves, `F7` makes a folder, `F8` deletes, `F2` renames, `Ctrl+R`
  refreshes.
- **CloudSync**: the host list syncs through [CloudSync](../cloud-storage) when it is
  installed. The app works without it.

## How it is built

Like CloudSync:

- a Go core does SSH, SFTP, transfers and sync;
- a Flutter app draws the UI (`DESIGN_MANIFEST.md`: dark only, design tokens only);
- the two talk gRPC (`proto/sshm.proto`) over a unix socket.

There is no daemon: as in MegaChat, the core runs inside the app's process. On Linux it
is a C archive (`desktopbind`) linked into the executable, which Dart starts through FFI.
The app then talks to it over a private socket (`$XDG_RUNTIME_DIR/sshmanager.sock`).
When the window closes, the core closes the SSH connections. A second instance of the
app connects to the first one's core through `~/.config/sshmanager/endpoint.json`. On
Android the same core runs inside the app (`mobilebind`, gomobile).

## Sync through CloudSync

On the CloudSync screen, press **Sync via CloudSync**. The app shows a 6-digit code;
allow the request in CloudSync if CloudSync shows the same code. After that:

- **Shared server list** (CloudSync with the `servers` scope): hosts are CloudSync's own
  server entries. DB Manager uses the same list. Trusted server keys are shared too.
  Extra data of each app lives in `Server.extra` under its own prefix
  (`sshmanager.start_dir`).
- **Fallback** (older CloudSync): the list is one record of this app, `hosts.json`.
  Concurrent offline edits are merged by host, and deletions are kept as tombstones.
  When CloudSync later gains the scope, the hosts move to the shared list once. The
  record keeps a map of old id → server id, so other devices don't upload duplicates.
- **SSH keys of the CloudSync safe** (scope `ssh_keys`): pick one as the login method.
  The private key is fetched for each connection and never stored by this app.
  A key pasted into the app stays on this device.

If the pairing was made before CloudSync knew these scopes, use **Ask for servers and
keys**.

Device-local state (token, revisions, cursor) is in `~/.config/sshmanager/cloudsync.json`,
and the host list in `hosts.json` next to it (mode 0600). Both are on this device only.

## Build

```bash
make build-linux        # builds/linux/sshmanager (the core is linked in)
make test               # Go tests, incl. an end-to-end SSH/SFTP test on a built-in server
make app-test
go run ./tools/devsshd  # a throwaway server on 127.0.0.1:2222 (tester / secret; -listen to move it)
```

Needs Go 1.27 with cgo (gcc), Flutter 3.41, `protoc` with `protoc-gen-go`, `protoc-gen-go-grpc` and
`protoc-gen-dart` (only for `make proto`).

## Android (not done yet)

The Go side is ready: `mobilebind.Start(dataDir, filesDir, socket)` runs the core and
returns the token. `mobilebind.SetConnector(c)` takes CloudSync's bound service; a
Kotlin object with `call(method, bytes)` is enough, and `core/cloudsync/binder.go`
adapts it. What's missing:

1. `make aar` (gomobile + NDK) → `app/android/app/libs/sshmanager.aar`, and the
   dependency in `build.gradle.kts`.
2. Kotlin: a foreground `CoreService` that calls `Mobilebind.start`, and a
   `MethodChannel("dev.sshmanager/core")` whose `start` returns `{socket, token}` (the
   Dart side, `AndroidLauncher`, is written).
3. Kotlin: binding to `dev.cloudsync.connector.BIND` with the AIDL files of CONNECTOR.md
   Appendix B, passed to `Mobilebind.setConnector`. Also `<queries>` for
   `dev.cloudsync.cloudsync` in the manifest.
4. `make build-apk`.

## Not supported yet

- Jump hosts (`jump_server_id` is kept and synced, but connecting through one is refused).
- Port forwarding, SCP fallback for servers without SFTP, file viewing and editing.
- Sealing the local `hosts.json` with CloudSync's `AppKey` (CONNECTOR.md § 8). It is a
  0600 file, like `~/.ssh`.
# postern
