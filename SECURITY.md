# Security policy

Postern is an SSH client: it handles passwords, private keys and host keys. Please report
vulnerabilities privately.

## Reporting a vulnerability

Open a private advisory at
<https://github.com/SelfHold/postern/security/advisories/new>. Do not open a public
issue or pull request for a security problem.

Please include what you found, the version or commit, steps to reproduce, and the impact
you expect. This is a personal project: there is no bounty and no fixed response time,
but reports are read and answered.

## Scope

In scope:

- **Private keys and passphrases**: a key or passphrase leaking to disk, logs, error
  messages, the gRPC API or another app; a key from the Shard safe being stored instead
  of fetched per connection.
- **Host-key verification**: connecting without a trusted key, a changed key being
  accepted or replaced without an explicit user action, fingerprint spoofing in the UI.
- **The local endpoint**: the core's unix socket, its bearer token and `endpoint.json`
  (another local user or process reaching the core, token leaks).
- **Sync through Shard**: host data or keys reaching Shard or other apps outside the
  scopes the user allowed, another app's `Server.extra` data being changed.

Known limitations (not vulnerabilities, but tracked): the local `hosts.json` is a 0600
file, not encrypted yet; jump hosts are not supported. See the README.

Out of scope: `tools/devsshd`, a test server with a fixed password that is meant for
localhost only; the leftover Windows code paths (Windows is not a supported platform).
