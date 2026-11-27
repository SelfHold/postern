# Postern

An SSH terminal and a two-panel file manager in the spirit of Midnight Commander, for
Linux (Android later). Postern was formerly called SSH Manager.

**Status:** a personal project at an early stage (0.1.0). It works for daily use on Linux,
but expect rough edges and breaking changes. There are no releases yet: build it from
source.

Postern is part of [SelfHold](https://github.com/SelfHold), a set of self-hosted apps
that work on their own and can optionally sync through
[Shard](https://github.com/SelfHold/shard).

## Features

- **Hosts**: a list of servers with a name, group, tags, notes and a start folder.
  Login by password, a pasted private key (with an optional passphrase), ssh-agent
  (desktops only) or an SSH key from the Shard safe.
- **Host-key trust**: the server's key is shown with its SHA256 fingerprint on the first
  connection and must be confirmed. A changed key is reported as such and is never
  replaced without an explicit action.
- **Terminal**: tabs of SSH sessions (xterm-256color). Ctrl+Shift+C / Ctrl+Shift+V copy
  and paste; on phones there is a bar with Esc, Tab, Ctrl and arrow keys.
- **Files**: two panels. Each panel shows this device or any host, so you can copy
  between this device and a server, or between two servers. Keys: `Tab` switches panels,
  `Enter` opens, `Backspace` goes up, `Ins`/`Space` selects, `F5` copies, `F6` moves,
  `F7` makes a folder, `F8`/`Delete` deletes, `F2` renames, `Ctrl+R` refreshes.
- **Sync through Shard** (optional): the host list, trusted host keys and the SSH keys of
  the Shard safe. See [below](#sync-through-shard).
- **UI languages**: English (default) and Russian, switched in the header. The choice is
  kept on this device.

## Platforms

- **Linux**: the current target.
- **Android**: the Go side is ready, the Kotlin glue is not (see
  [Android](#android-not-done-yet)).
- **macOS and iOS**: planned, not built yet.

Windows is not a target.

## Security model in brief

- **Host keys are trusted explicitly.** Before the first connection the app probes the
  server's key and the user confirms the fingerprint. A key that differs from the trusted
  one blocks the connection until the user decides to replace it.
- **Private keys from the Shard safe are never stored.** A key picked from the safe
  (scope `ssh_keys`) is fetched from Shard for each connection and only kept in memory
  while connecting. A key pasted into the app is not put into Shard's shared server list:
  with the shared list it stays on this device. (In the fallback mode with the app's own
  `hosts.json` record, the whole host list, pasted keys included, is that record, which
  Shard stores encrypted. Passwords are part of a server entry in both modes.)
- **Local files are private to the user.** The host list (`hosts.json`) and the sync
  state (`shard.json`) are written with mode 0600 in the config directory, like
  `~/.ssh`. They are **not encrypted yet**: a password or pasted key in a host is stored
  in plain text in that file. Sealing it is on the list below. When synced, Shard stores
  the data encrypted.
- **The core is reachable only by this user.** It listens on a private unix socket and
  every call needs a random bearer token. `endpoint.json` (address and token) is readable
  only by the user.

## How it is built

- A **Go core** (`core/`) does SSH, SFTP, transfers and sync:
  `hosts` (list and deterministic merge), `sshc` (SSH, host keys), `fsys` (local and SFTP
  trees, transfers), `shard` (Connector client, sync), `rpc` (the gRPC API), `embed`
  (runs the core inside the app).
- A **Flutter app** (`app/`) draws the UI and holds no logic of its own: dark theme only,
  colours and type from the design tokens only.
- The two talk gRPC (`proto/postern.proto`) over a unix socket.

There is no daemon: the core runs inside the app's process. On Linux it is a C archive
(`desktopbind`) linked into the executable, which Dart starts through FFI. The app then
talks to it over a private socket (`$XDG_RUNTIME_DIR/selfhold-postern.sock`). When the window
closes, the core closes the SSH connections. A second instance of the app connects to the
first one's core through `~/.config/selfhold/postern/endpoint.json`. On Android the same core
runs inside the app (`mobilebind`, gomobile).

## Build from source

Prerequisites:

- Go 1.27 with cgo (gcc)
- Flutter 3.41 with the Linux desktop toolchain (clang, CMake, Ninja, GTK 3 headers)
- only for `make proto`: `protoc` with `protoc-gen-go`, `protoc-gen-go-grpc` and
  `protoc-gen-dart` (expected in `~/.pub-cache/bin`)
- only for `make aar` / `make build-apk`: `gomobile` and the Android NDK (by default the
  newest one in `~/Android/Sdk/ndk`, or set `NDK=`)

```bash
make build-linux     # the app with the core linked in → builds/linux/postern
make app-run         # run the app in debug mode
make test            # Go tests, incl. an end-to-end SSH/SFTP test on a built-in server
make vet             # go vet
make app-test        # flutter analyze + flutter test
make proto           # regenerate core/rpc/pb, core/shard/pb, app/lib/data/rpc/gen
make clean
```

`make test` and `make app-test` run under `systemd-run --user` with a 1 GB memory cap.
All build outputs go to `builds/`.

### A throwaway SSH server for trying it out

```bash
go run ./tools/devsshd   # 127.0.0.1:2222, user "tester", password "secret"
```

`tools/devsshd` is a minimal SSH server for manual tests: a fresh host key on every
start, an echo shell and SFTP over this machine's files. Add a host `127.0.0.1`, port
`2222`, in the app and connect. `-listen` moves it to another address. Keep it on
localhost: it serves your files to anyone who knows the password.

## Sync through Shard

Sync is optional: the app works without Shard, and Shard may be missing, stopped or
locked at any time. The local file is always the working copy. Postern uses Shard's
Connector API; the integration guide is
[CONNECTOR.md](https://github.com/SelfHold/shard/blob/main/docs/CONNECTOR.md).

On the Shard screen, press **Sync via Shard**. The app shows a 6-digit code;
allow the request in Shard if Shard shows the same code. After that:

- **Shared server list** (Shard with the `servers` scope): hosts are Shard's own server
  entries. [Cellar](https://github.com/SelfHold/cellar) uses the
  same list, and trusted host keys are shared too. Extra data of each app lives in
  `Server.extra` under its own prefix (here `postern.start_dir`).
- **Fallback** (an older Shard): the list is one record of this app, `hosts.json`.
  Concurrent offline edits are merged by host, and deletions are kept as tombstones.
  When Shard later gains the scope, the hosts move to the shared list once. The record
  keeps a map of old id → server id, so other devices don't upload duplicates.
- **SSH keys of the Shard safe** (scope `ssh_keys`): pick one as the login method. The
  private key is fetched for each connection and never stored by this app.
  A key pasted into the app is not uploaded to the shared server list.

If the pairing was made before Shard knew these scopes, use **Ask for servers and keys**.

Device-local state (token, revisions, cursor) is in `~/.config/selfhold/postern/shard.json`,
and the host list in `hosts.json` next to it (mode 0600). Both stay on this device; the
pairing token is never synced.

## Android (not done yet)

The Go side is ready: `mobilebind.Start(dataDir, filesDir, socket)` runs the core and
returns the token. `mobilebind.SetConnector(c)` takes Shard's bound service; a Kotlin
object with `call(method, bytes)` is enough, and `core/shard/binder.go` adapts it.
What's missing:

1. `make aar` (gomobile + NDK) → `app/android/app/libs/postern.aar`, and the
   dependency in `build.gradle.kts`.
2. Kotlin: a foreground `CoreService` that calls `Mobilebind.start`, and a
   `MethodChannel("dev.selfhold.postern/core")` whose `start` returns `{socket, token}` (the
   Dart side, `AndroidLauncher`, is written).
3. Kotlin: binding to `dev.selfhold.shard.connector.BIND` with the AIDL files of the
   Connector guide (Appendix B), passed to `Mobilebind.setConnector`. Also `<queries>`
   for `dev.selfhold.shard` in the manifest.
4. `make build-apk`.

## Not supported yet

- Jump hosts (`jump_id` is kept and synced, but connecting through one is refused).
- Port forwarding, SCP fallback for servers without SFTP, file viewing and editing.
- Sealing the local `hosts.json` (for example with Shard's `AppKey`, Connector guide
  § 8). Today it is a 0600 file, like `~/.ssh`.

## Contributing and security

See [CONTRIBUTING.md](CONTRIBUTING.md). Report vulnerabilities privately, as described in
[SECURITY.md](SECURITY.md).

## License

Postern is free software under the GNU General Public License v3.0. See
[LICENSE](LICENSE).
