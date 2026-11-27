# Contributing to Postern

Thanks for your interest. Postern is a small personal project, so please open an issue
to discuss larger changes before writing them. Security problems go through
[SECURITY.md](SECURITY.md), not public issues.

## Development

Prerequisites and build steps are in the [README](README.md#build-from-source).

```bash
make test            # Go tests (memory-capped, run one at a time)
make vet             # go vet
make app-test        # flutter analyze + flutter test
make app-run         # run the app in debug mode
make build-linux     # release build → builds/linux/
make core-lib        # only the core as a C archive (the Linux CMake build runs it)
make proto           # regenerate the gRPC code
go run ./tools/devsshd   # throwaway SSH server on 127.0.0.1:2222 (tester / secret)
```

Use the `make` targets rather than calling `go`, `flutter` or `protoc` by hand. Build
outputs go to `builds/`. Generated code (`core/rpc/pb`, `core/cloudsync/pb`,
`app/lib/data/rpc/gen`) is only changed by `make proto`, never by hand.

Pull requests go to `main`. Keep one topic per PR, and make sure `make vet test app-test`
passes.

## Language

- Everything in the repository is in **English**: docs, code comments, identifiers, log
  lines and error messages.
- Other languages appear only as translations. UI strings go through
  `tr('English', 'Русский')` (`app/lib/core/i18n.dart`); a translated doc (for example
  `README.ru.md`) must match its English original. Test data may use any script.
- The app starts in English and switches to Russian only when the user picks it. Never
  derive the language from the system locale.

## Naming

The product is Postern (formerly SSH Manager). Many identifiers still use the old name:
the Go module `sshmanager`, the proto package `sshm.v1`, `SshmStart/Stop/Free`, the app
and Android ids, the data directory `~/.config/sshmanager`, the record `hosts.json`, the
`Server.extra` prefix `sshmanager.*`. These are persisted on users' devices or shared with
other apps: **do not rename them** without a migration plan agreed in an issue first.

## Architecture rules

- **The core owns everything.** SSH, SFTP, host keys, transfers and sync live in the Go
  core (`core/`). The Flutter app (`app/`) only renders and calls the gRPC API
  (`proto/sshm.proto`).
- **No daemon.** `core/embed` runs the core inside the app's process (`desktopbind` on
  Linux, `mobilebind` on Android). Keep platform specifics behind these seams and in the
  data-dir lookup: no Linux-only assumptions in shared core code, so macOS and iOS stay
  possible.
- **Standalone first.** The local `hosts.json` is always the working copy. Shard is
  optional and may be missing, stopped or locked at any moment.
- **Two sync modes.** Either the app's own record `hosts.json` (compare-and-swap on the
  revision, deterministic merge of concurrent versions with tombstones), or Shard's
  shared server list (scope `servers`, per-server compare-and-swap, newest modified time
  wins). Never merge across vault ids. Moving to the shared list writes `migrated` (old
  id → server id) into the record, so other devices re-key instead of uploading
  duplicates.
- **Other apps' data.** In `Server.extra` only `sshmanager.*` keys are ours; keep
  everyone else's keys exactly as they are.
- **Private keys.** A key from the Shard safe (`SAFE_KEY`, scope `ssh_keys`) is fetched
  per connection and never stored. A pasted key is never put into the shared server
  list. Logs, errors and RPC errors carry no passwords, keys or tokens.
- **Host keys** are trusted explicitly: probe, then the user confirms the fingerprint. A
  changed key is never replaced without an explicit user action. Trusted keys live on the
  host (`host_keys`), so they sync and are shared with Cellar.
- **Per-device state** (pairing token, revisions, cursor, UI language) is never synced.
- **Connector contract.** `proto/connector.proto` is a byte-for-byte copy of
  [Shard's](https://github.com/SelfHold/shard/blob/main/proto/connector.proto). Don't edit
  it here: changes go to Shard first and are copied over. Postern must keep working
  against an older Shard that lacks newer fields or scopes. The integration guide is
  [CONNECTOR.md](https://github.com/SelfHold/shard/blob/main/docs/CONNECTOR.md).

## UI rules

- Dark theme only. Colours come from `HmColors`, text styles from `HmText` (the design
  tokens and type scale); no raw colours, no Material elevation. Fonts are bundled.
- Screens are built only from the widgets in `app/lib/presentation/common`.
- Every screen must also work in the phone layout (windows below 768 px, touch targets
  of at least 44 px).
- The Linux window is undecorated (`app/linux/runner/my_application.cc`): the app's
  header is the title bar. Don't bring the GTK header bar back.

## Platforms

Linux now, Android next, macOS and iOS planned. Windows is not a target: don't add or
fix Windows-specific code.

## License

By contributing you agree that your contributions are licensed under the
[GNU General Public License v3.0](LICENSE), like the rest of the project.
