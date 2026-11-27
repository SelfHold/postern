// Package sshc opens SSH connections to hosts of the list: host key check
// against the key on record, the host's auth method, interactive shells.
package sshc

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"golang.org/x/crypto/ssh"
	"golang.org/x/crypto/ssh/agent"

	"github.com/SelfHold/postern/core/hosts"
)

// KeyFetcher returns the private key (and its passphrase) of a Shard
// safe entry, for hosts with hosts.AuthSafeKey.
type KeyFetcher func(ctx context.Context, keyID string) (private, passphrase string, err error)

// ErrHostKeyUnknown: the host has no trusted key on record yet.
var ErrHostKeyUnknown = errors.New("the server's key is not trusted yet")

// ErrHostKeyChanged: the server shows another key than the one on record.
var ErrHostKeyChanged = errors.New("the server's key has CHANGED since it was trusted")

// HostKeyStatus of a probe.
type HostKeyStatus int

const (
	KeyKnown HostKeyStatus = iota + 1
	KeyUnknown
	KeyChanged
)

// ProbeResult is the server key seen by Probe.
type ProbeResult struct {
	Status      HostKeyStatus
	Key         string // authorized_keys format
	Fingerprint string
	Type        string
}

const dialTimeout = 15 * time.Second

func addr(h hosts.Host) string {
	port := h.Port
	if port == 0 {
		port = 22
	}
	return net.JoinHostPort(strings.TrimSpace(h.Address), strconv.Itoa(port))
}

// Probe connects only far enough to see the server's host key.
func Probe(ctx context.Context, h hosts.Host) (ProbeResult, error) {
	known, err := parseKnown(h.HostKeys)
	if err != nil {
		return ProbeResult{}, fmt.Errorf("a trusted key on record is damaged: %w", err)
	}
	var seen ssh.PublicKey
	stop := errors.New("probe done")
	cfg := &ssh.ClientConfig{
		User: h.User,
		HostKeyCallback: func(_ string, _ net.Addr, key ssh.PublicKey) error {
			seen = key
			return stop
		},
		// Ask for the algorithms on record first, so a server with several
		// keys shows one we know.
		HostKeyAlgorithms: algorithmsFor(known),
		Timeout:           dialTimeout,
	}
	conn, err := dialTCP(ctx, addr(h))
	if err != nil {
		return ProbeResult{}, err
	}
	defer conn.Close()
	_, _, _, err = ssh.NewClientConn(conn, addr(h), cfg)
	if seen == nil {
		if err == nil {
			err = errors.New("the server sent no host key")
		}
		return ProbeResult{}, err
	}
	r := ProbeResult{
		Key:         strings.TrimSpace(string(ssh.MarshalAuthorizedKey(seen))),
		Fingerprint: ssh.FingerprintSHA256(seen),
		Type:        seen.Type(),
		Status:      KeyUnknown,
	}
	if len(known) > 0 {
		r.Status = KeyChanged
		if matches(known, seen) {
			r.Status = KeyKnown
		}
	}
	return r, nil
}

// NormalizeKey checks an authorized_keys line and returns it without a
// comment.
func NormalizeKey(line string) (string, error) {
	if strings.TrimSpace(line) == "" {
		return "", errors.New("empty key")
	}
	k, _, _, _, err := ssh.ParseAuthorizedKey([]byte(line))
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(ssh.MarshalAuthorizedKey(k))), nil
}

func parseKnown(lines []string) ([]ssh.PublicKey, error) {
	var out []ssh.PublicKey
	for _, l := range lines {
		if strings.TrimSpace(l) == "" {
			continue
		}
		k, _, _, _, err := ssh.ParseAuthorizedKey([]byte(l))
		if err != nil {
			return nil, err
		}
		out = append(out, k)
	}
	return out, nil
}

func matches(known []ssh.PublicKey, k ssh.PublicKey) bool {
	for _, w := range known {
		if w.Type() == k.Type() && string(w.Marshal()) == string(k.Marshal()) {
			return true
		}
	}
	return false
}

// algorithmsFor lists host key algorithms of the known keys first, then
// nil (= the library's defaults) when nothing is known.
func algorithmsFor(known []ssh.PublicKey) []string {
	var out []string
	for _, k := range known {
		if k.Type() == ssh.KeyAlgoRSA {
			out = append(out, ssh.KeyAlgoRSASHA512, ssh.KeyAlgoRSASHA256, ssh.KeyAlgoRSA)
		} else {
			out = append(out, k.Type())
		}
	}
	return out
}

func dialTCP(ctx context.Context, address string) (net.Conn, error) {
	ctx, cancel := context.WithTimeout(ctx, dialTimeout)
	defer cancel()
	return (&net.Dialer{KeepAlive: 30 * time.Second}).DialContext(ctx, "tcp", address)
}

// Dial connects and authenticates. The host key must match the key on
// record (Probe + trust first).
func Dial(ctx context.Context, h hosts.Host, fetch KeyFetcher) (*ssh.Client, error) {
	known, err := parseKnown(h.HostKeys)
	if err != nil {
		return nil, fmt.Errorf("a trusted key on record is damaged: %w", err)
	}
	if len(known) == 0 {
		return nil, ErrHostKeyUnknown
	}
	auth, closeAuth, err := authMethods(ctx, h, fetch)
	if err != nil {
		return nil, err
	}
	defer closeAuth()
	cfg := &ssh.ClientConfig{
		User: h.User,
		Auth: auth,
		HostKeyCallback: func(_ string, _ net.Addr, key ssh.PublicKey) error {
			if !matches(known, key) {
				return ErrHostKeyChanged
			}
			return nil
		},
		HostKeyAlgorithms: algorithmsFor(known),
		Timeout:           dialTimeout,
	}
	conn, err := dialTCP(ctx, addr(h))
	if err != nil {
		return nil, err
	}
	// The handshake has its own deadline; ctx cancels it too.
	conn.SetDeadline(time.Now().Add(dialTimeout))
	stop := context.AfterFunc(ctx, func() { conn.Close() })
	c, chans, reqs, err := ssh.NewClientConn(conn, addr(h), cfg)
	stop()
	if err != nil {
		conn.Close()
		if errors.Is(err, ErrHostKeyChanged) {
			return nil, ErrHostKeyChanged
		}
		return nil, friendly(err)
	}
	conn.SetDeadline(time.Time{})
	client := ssh.NewClient(c, chans, reqs)
	go keepAlive(client)
	return client, nil
}

// keepAlive pings the server so idle connections (NAT, firewalls) live on
// and dead ones are noticed.
func keepAlive(c *ssh.Client) {
	t := time.NewTicker(30 * time.Second)
	defer t.Stop()
	for range t.C {
		if _, _, err := c.SendRequest("keepalive@openssh.com", true, nil); err != nil {
			c.Close()
			return
		}
	}
}

func friendly(err error) error {
	s := err.Error()
	if strings.Contains(s, "unable to authenticate") {
		return errors.New("the server refused the login (wrong user, password or key)")
	}
	return err
}

func authMethods(ctx context.Context, h hosts.Host, fetch KeyFetcher) ([]ssh.AuthMethod, func(), error) {
	none := func() {}
	switch h.Auth {
	case hosts.AuthPassword:
		pw := h.Password
		return []ssh.AuthMethod{
			ssh.Password(pw),
			ssh.KeyboardInteractive(func(_, _ string, qs []string, _ []bool) ([]string, error) {
				ans := make([]string, len(qs))
				for i := range qs {
					ans[i] = pw
				}
				return ans, nil
			}),
		}, none, nil
	case hosts.AuthKey:
		s, err := signer(h.PrivateKey, h.Passphrase)
		if err != nil {
			return nil, none, err
		}
		return []ssh.AuthMethod{ssh.PublicKeys(s)}, none, nil
	case hosts.AuthSafeKey:
		if fetch == nil {
			return nil, none, errors.New("keys from Shard are not available on this device")
		}
		priv, pass, err := fetch(ctx, h.KeyID)
		if err != nil {
			return nil, none, fmt.Errorf("key from Shard: %w", err)
		}
		s, err := signer(priv, pass)
		if err != nil {
			return nil, none, err
		}
		return []ssh.AuthMethod{ssh.PublicKeys(s)}, none, nil
	case hosts.AuthAgent:
		sock := os.Getenv("SSH_AUTH_SOCK")
		if sock == "" {
			return nil, none, errors.New("no ssh-agent: SSH_AUTH_SOCK is not set")
		}
		c, err := net.Dial("unix", sock)
		if err != nil {
			return nil, none, fmt.Errorf("ssh-agent: %w", err)
		}
		return []ssh.AuthMethod{ssh.PublicKeysCallback(agent.NewClient(c).Signers)}, func() { c.Close() }, nil
	}
	return nil, none, fmt.Errorf("unknown auth %q", h.Auth)
}

func signer(private, passphrase string) (ssh.Signer, error) {
	b := []byte(strings.TrimSpace(private) + "\n")
	s, err := ssh.ParsePrivateKey(b)
	var missing *ssh.PassphraseMissingError
	if errors.As(err, &missing) {
		if passphrase == "" {
			return nil, errors.New("the key is encrypted: enter its passphrase")
		}
		s, err = ssh.ParsePrivateKeyWithPassphrase(b, []byte(passphrase))
	}
	if err != nil {
		return nil, fmt.Errorf("private key: %w", err)
	}
	return s, nil
}

// Shell is an interactive session with a PTY.
type Shell struct {
	sess   *ssh.Session
	stdin  io.WriteCloser
	stdout io.Reader
	once   sync.Once
}

// OpenShell starts a login shell on c with a PTY of cols×rows.
func OpenShell(c *ssh.Client, cols, rows int) (*Shell, error) {
	sess, err := c.NewSession()
	if err != nil {
		return nil, err
	}
	modes := ssh.TerminalModes{ssh.ECHO: 1, ssh.TTY_OP_ISPEED: 115200, ssh.TTY_OP_OSPEED: 115200}
	if cols <= 0 || rows <= 0 {
		cols, rows = 80, 24
	}
	if err := sess.RequestPty("xterm-256color", rows, cols, modes); err != nil {
		sess.Close()
		return nil, err
	}
	in, err := sess.StdinPipe()
	if err != nil {
		sess.Close()
		return nil, err
	}
	out, err := sess.StdoutPipe()
	if err != nil {
		sess.Close()
		return nil, err
	}
	sess.Stderr = nil // with a PTY, stderr comes on stdout
	if err := sess.Shell(); err != nil {
		sess.Close()
		return nil, err
	}
	return &Shell{sess: sess, stdin: in, stdout: out}, nil
}

// Read reads terminal output.
func (s *Shell) Read(p []byte) (int, error) { return s.stdout.Read(p) }

// Write sends keystrokes.
func (s *Shell) Write(p []byte) (int, error) { return s.stdin.Write(p) }

// Resize changes the PTY size.
func (s *Shell) Resize(cols, rows int) error { return s.sess.WindowChange(rows, cols) }

// Wait waits for the shell to exit.
func (s *Shell) Wait() error { return s.sess.Wait() }

// Close ends the session.
func (s *Shell) Close() error {
	s.once.Do(func() { s.sess.Close() })
	return nil
}
