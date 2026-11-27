package hosts

import (
	"bytes"
	"path/filepath"
	"testing"
	"time"
)

func h(id string, t int64, name string) Host {
	return Host{ID: id, Name: name, Address: "a", User: "u", Auth: AuthPassword, UpdatedMs: t}
}

func TestMergeIsOrderFree(t *testing.T) {
	a := File{Hosts: []Host{h("1", 10, "a1"), h("2", 10, "a2")}}
	b := File{Hosts: []Host{h("1", 20, "b1"), h("3", 5, "b3")}, Removed: []Removed{{ID: "2", AtMs: 15}}}
	c := File{Hosts: []Host{h("1", 20, "c1")}}
	x := Encode(Merge(a, b, c))
	for _, order := range [][]File{{c, b, a}, {b, a, c}, {a, c, b}} {
		if y := Encode(Merge(order...)); !bytes.Equal(x, y) {
			t.Fatalf("merge depends on order:\n%s\n%s", x, y)
		}
	}
	m := Merge(a, b, c)
	if len(m.Hosts) != 2 {
		t.Fatalf("want hosts 1 and 3, got %+v", m.Hosts)
	}
	if m.Hosts[0].Name != "c1" { // tie on time: larger encoding wins
		t.Fatalf("tie: got %q", m.Hosts[0].Name)
	}
}

func TestEditAfterRemovalWins(t *testing.T) {
	a := File{Removed: []Removed{{ID: "1", AtMs: 10}}}
	b := File{Hosts: []Host{h("1", 11, "back")}}
	if m := Merge(a, b); len(m.Hosts) != 1 {
		t.Fatal("an edit made after the removal must bring the host back")
	}
	b.Hosts[0].UpdatedMs = 9
	if m := Merge(a, b); len(m.Hosts) != 0 {
		t.Fatal("a removal after the edit must win")
	}
}

func TestOldTombstonesArePruned(t *testing.T) {
	now := int64(1000) * TombstoneTTL.Milliseconds()
	f := File{Hosts: []Host{h("1", now, "x")}, Removed: []Removed{{ID: "old", AtMs: now - TombstoneTTL.Milliseconds() - 1}, {ID: "new", AtMs: now - 1}}}
	m := Merge(f)
	if len(m.Removed) != 1 || m.Removed[0].ID != "new" {
		t.Fatalf("got %+v", m.Removed)
	}
}

func TestStore(t *testing.T) {
	path := filepath.Join(t.TempDir(), "hosts.json")
	s, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	changes := 0
	s.OnChange(func() { changes++ })
	saved, err := s.Save(Host{Name: "web", Address: "10.0.0.1", User: "root", Auth: AuthPassword, Password: "pw"})
	if err != nil {
		t.Fatal(err)
	}
	if saved.ID == "" || saved.UpdatedMs == 0 {
		t.Fatal("id and time must be set")
	}
	// A clock that went back still moves the host forward.
	s.now = func() time.Time { return time.UnixMilli(1) }
	again, _ := s.Save(saved)
	if again.UpdatedMs <= saved.UpdatedMs {
		t.Fatal("UpdatedMs must grow")
	}
	if _, err := s.Save(Host{Name: "x", Address: "a", User: "u", Auth: AuthKey}); err == nil {
		t.Fatal("a key host without a key must be refused")
	}
	old := s.Bytes()
	if err := s.Delete(saved.ID); err != nil {
		t.Fatal(err)
	}
	if ok, _ := s.ReplaceIf(old, File{}); ok {
		t.Fatal("ReplaceIf must refuse after a change")
	}
	r, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	if len(r.List()) != 0 || len(r.File().Removed) != 1 {
		t.Fatalf("reopened: %+v", r.File())
	}
	if changes != 3 {
		t.Fatalf("changes = %d, want 3", changes)
	}
}
