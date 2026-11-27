package shard

import (
	"context"
	"path/filepath"
	"testing"
	"time"

	"github.com/SelfHold/postern/core/hosts"
	"github.com/SelfHold/postern/core/shard/pb"
)

type dev struct {
	s     *Syncer
	store *hosts.Store
	fd    *fakeDevice
}

func newDev(t *testing.T, v *fakeVault, name string) *dev {
	t.Helper()
	dir := t.TempDir()
	store, err := hosts.Open(filepath.Join(dir, "hosts.json"))
	if err != nil {
		t.Fatal(err)
	}
	fd := &fakeDevice{v: v, name: name}
	s, err := New(fd, store, filepath.Join(dir, "shard.json"), "test")
	if err != nil {
		t.Fatal(err)
	}
	return &dev{s: s, store: store, fd: fd}
}

func (d *dev) enable(t *testing.T) {
	t.Helper()
	if _, err := d.s.Enable(context.Background()); err != nil {
		t.Fatal(err)
	}
	deadline := time.Now().Add(5 * time.Second)
	for !d.s.Status().Enabled {
		if time.Now().After(deadline) {
			t.Fatalf("pairing did not finish: %+v", d.s.Status())
		}
		time.Sleep(5 * time.Millisecond)
	}
}

func (d *dev) round(t *testing.T) Status {
	t.Helper()
	d.s.Round(context.Background())
	return d.s.Status()
}

func (d *dev) add(t *testing.T, name string) hosts.Host {
	t.Helper()
	h, err := d.store.Save(hosts.Host{Name: name, Address: name + ".example", User: "root", Auth: hosts.AuthPassword, Password: "pw-" + name})
	if err != nil {
		t.Fatal(err)
	}
	return h
}

func names(s *hosts.Store) map[string]hosts.Host {
	out := map[string]hosts.Host{}
	for _, h := range s.List() {
		out[h.Name] = h
	}
	return out
}

func TestRecordSyncBetweenDevices(t *testing.T) {
	v := newVault() // Shard without the new scopes
	a, b := newDev(t, v, "a"), newDev(t, v, "b")
	a.add(t, "web")
	db := a.add(t, "db")
	a.enable(t)
	if st := a.round(t); st.Phase != PhaseSynced || st.Pending || st.SharedServers {
		t.Fatalf("a: %+v", st)
	}
	b.add(t, "laptop") // b had its own host before sync
	b.enable(t)
	b.round(t)
	if got := names(b.store); len(got) != 3 {
		t.Fatalf("b after first sync: %v", got)
	}
	a.round(t)
	if got := names(a.store); len(got) != 3 {
		t.Fatalf("a did not get b's host: %v", got)
	}

	// Removal on a, edit on b of another host.
	if err := a.store.Delete(db.ID); err != nil {
		t.Fatal(err)
	}
	web := names(b.store)["web"]
	web.User = "admin"
	b.store.Save(web)
	a.round(t)
	b.round(t)
	a.round(t)
	for _, d := range []*dev{a, b} {
		got := names(d.store)
		if _, ok := got["db"]; ok || got["web"].User != "admin" || len(got) != 2 {
			t.Fatalf("not converged: %v", got)
		}
	}
}

func TestConcurrentVersionsAreMerged(t *testing.T) {
	v := newVault()
	a := newDev(t, v, "a")
	a.enable(t)
	a.round(t)
	x := hosts.Encode(hosts.File{Hosts: []hosts.Host{{ID: "x", Name: "x", Address: "x", User: "u", Auth: hosts.AuthPassword, UpdatedMs: 1}}})
	y := hosts.Encode(hosts.File{Hosts: []hosts.Host{{ID: "y", Name: "y", Address: "y", User: "u", Auth: hosts.AuthPassword, UpdatedMs: 1}}})
	v.concurrent(RecordKey, x, y)
	a.round(t)
	if got := names(a.store); len(got) != 2 {
		t.Fatalf("want both versions merged, got %v", got)
	}
	if it := v.records[RecordKey]; len(it.Versions) != 1 {
		t.Fatalf("the merge must be written back as one version, got %d", len(it.Versions))
	}
}

func TestOfflineKeepsChangesPending(t *testing.T) {
	v := newVault()
	a := newDev(t, v, "a")
	a.enable(t)
	a.round(t)
	a.fd.offline = true
	a.add(t, "late")
	if st := a.round(t); st.Phase != PhaseOffline || !st.Pending {
		t.Fatalf("offline: %+v", st)
	}
	a.fd.offline = false
	if st := a.round(t); st.Phase != PhaseSynced || st.Pending {
		t.Fatalf("back online: %+v", st)
	}
}

func TestMigrationToSharedServers(t *testing.T) {
	v := newVault()
	a, b := newDev(t, v, "a"), newDev(t, v, "b")
	a.add(t, "web")
	key, _ := a.store.Save(hosts.Host{Name: "pasted", Address: "p", User: "u", Auth: hosts.AuthKey, PrivateKey: "PRIVATE", StartDir: "/srv"})
	a.enable(t)
	a.round(t)
	b.enable(t)
	b.round(t)

	// Shard learns the scopes; both devices move to the shared list.
	v.scopes = []string{ScopeServers, ScopeSSHKeys}
	if st := a.round(t); !st.SharedServers || st.Phase != PhaseSynced {
		t.Fatalf("a: %+v", st)
	}
	b.round(t)
	a.round(t)
	if len(v.servers) != 2 {
		t.Fatalf("want 2 shared servers (no duplicates), got %d", len(v.servers))
	}
	for _, sv := range v.servers {
		if sv.Name == "pasted" {
			if sv.Auth != pb.Server_SSH_KEY || sv.SshKeyId != "" || string(sv.Extra[extraStartDir]) != "/srv" {
				t.Fatalf("pasted server: %+v", sv)
			}
		}
	}
	// The pasted key stays on the device that has it, under the new id.
	p := names(a.store)["pasted"]
	if p.PrivateKey != "PRIVATE" || p.ID == key.ID || v.servers[p.ID] == nil {
		t.Fatalf("a's pasted host: %+v", p)
	}
	if bp := names(b.store)["pasted"]; bp.ID != p.ID {
		t.Fatalf("b must re-key to the same server id: %q vs %q", bp.ID, p.ID)
	}

	// Edits and removals travel through the shared list.
	web := names(b.store)["web"]
	web.Port = 2222
	b.store.Save(web)
	b.round(t)
	a.round(t)
	if names(a.store)["web"].Port != 2222 {
		t.Fatal("a did not get b's edit")
	}
	a.store.Delete(p.ID)
	a.round(t)
	b.round(t)
	if _, ok := names(b.store)["pasted"]; ok || len(v.servers) != 1 {
		t.Fatalf("removal did not travel: %v, %d servers", names(b.store), len(v.servers))
	}

	// Another app's extra fields survive our writes.
	for _, sv := range v.servers {
		sv.Extra = map[string][]byte{"cellar.dbs": []byte("x")}
		sv.Revision = v.rev()
		v.logChange(sv.Id, sv.Revision, false)
	}
	a.round(t)
	w := names(a.store)["web"]
	w.Notes = "edited"
	a.store.Save(w)
	a.round(t)
	for _, sv := range v.servers {
		if string(sv.Extra["cellar.dbs"]) != "x" || sv.Notes != "edited" {
			t.Fatalf("server after edit: %+v", sv)
		}
	}
	// New hosts get Shard's id.
	n := a.add(t, "new")
	a.round(t)
	if got := names(a.store)["new"]; got.ID == n.ID || v.servers[got.ID] == nil {
		t.Fatalf("new host not re-keyed: %+v", got)
	}
}

func TestSafeKeys(t *testing.T) {
	v := newVault(ScopeServers, ScopeSSHKeys)
	v.keys = []*pb.SshKey{{Id: "k1", Title: "work", PrivateKey: "SECRET", Passphrase: "pp"}}
	a := newDev(t, v, "a")
	if _, err := a.s.SafeKeys(context.Background()); err == nil {
		t.Fatal("keys must need sync on")
	}
	a.enable(t)
	keys, err := a.s.SafeKeys(context.Background())
	if err != nil || len(keys) != 1 || keys[0].PrivateKey != "" {
		t.Fatalf("list: %v %+v", err, keys)
	}
	priv, pass, err := a.s.FetchKey(context.Background(), "k1")
	if err != nil || priv != "SECRET" || pass != "pp" {
		t.Fatalf("fetch: %v %q %q", err, priv, pass)
	}
	if _, _, err := a.s.FetchKey(context.Background(), "gone"); err == nil {
		t.Fatal("a missing key must fail")
	}
}

func TestRevokedPairingTurnsSyncOff(t *testing.T) {
	v := newVault()
	a := newDev(t, v, "a")
	a.add(t, "web")
	a.enable(t)
	a.round(t)
	v.paired = map[string]bool{}
	st := a.round(t)
	if st.Enabled || st.Phase != PhaseOff || st.Error == "" {
		t.Fatalf("after revoke: %+v", st)
	}
	if len(a.store.List()) != 1 {
		t.Fatal("the local list must stay")
	}
}
