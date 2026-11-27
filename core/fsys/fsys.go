// Package fsys gives the file manager one view of this device's files and
// of a server's files (SFTP), and copies between any two of them.
package fsys

import (
	"context"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"slices"
	"strings"
	"time"

	"github.com/pkg/sftp"
)

// Entry is one item of a folder.
type Entry struct {
	Name     string
	Dir      bool
	Link     bool
	Size     int64
	Modified time.Time
	Mode     fs.FileMode
}

// FS is a file tree: this device or a server.
type FS interface {
	Home() (string, error)
	ReadDir(p string) ([]Entry, error)
	Stat(p string) (Entry, error)
	MkdirAll(p string) error
	RemoveAll(p string) error
	Rename(from, to string) error
	Open(p string) (io.ReadCloser, error)
	Create(p string, mode fs.FileMode) (io.WriteCloser, error)
	SetModified(p string, t time.Time) error
	// Join, Dir, Base and Clean use the tree's separator.
	Join(elem ...string) string
	Dir(p string) string
	Base(p string) string
	Abs(p string) (string, error)
}

func entry(fi fs.FileInfo) Entry {
	return Entry{
		Name:     fi.Name(),
		Dir:      fi.IsDir(),
		Link:     fi.Mode()&fs.ModeSymlink != 0,
		Size:     fi.Size(),
		Modified: fi.ModTime(),
		Mode:     fi.Mode(),
	}
}

func sortEntries(es []Entry) {
	slices.SortFunc(es, func(a, b Entry) int {
		if a.Dir != b.Dir {
			if a.Dir {
				return -1
			}
			return 1
		}
		return strings.Compare(strings.ToLower(a.Name), strings.ToLower(b.Name))
	})
}

// Local is this device's file system.
type Local struct {
	// HomeDir overrides the home folder (Android: the app's storage).
	HomeDir string
}

func (l Local) Home() (string, error) {
	if l.HomeDir != "" {
		return l.HomeDir, nil
	}
	return os.UserHomeDir()
}

func (Local) ReadDir(p string) ([]Entry, error) {
	des, err := os.ReadDir(p)
	if err != nil {
		return nil, err
	}
	out := make([]Entry, 0, len(des))
	for _, d := range des {
		fi, err := d.Info()
		if err != nil {
			continue // vanished meanwhile
		}
		e := entry(fi)
		if e.Link {
			// Show a link to a folder as a folder (like mc).
			if st, err := os.Stat(filepath.Join(p, d.Name())); err == nil && st.IsDir() {
				e.Dir = true
			}
		}
		out = append(out, e)
	}
	sortEntries(out)
	return out, nil
}

func (Local) Stat(p string) (Entry, error) {
	fi, err := os.Stat(p)
	if err != nil {
		return Entry{}, err
	}
	return entry(fi), nil
}

func (Local) MkdirAll(p string) error  { return os.MkdirAll(p, 0o755) }
func (Local) RemoveAll(p string) error { return os.RemoveAll(p) }
func (Local) Rename(a, b string) error { return os.Rename(a, b) }
func (Local) Open(p string) (io.ReadCloser, error) {
	return os.Open(p)
}
func (Local) Create(p string, mode fs.FileMode) (io.WriteCloser, error) {
	return os.OpenFile(p, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, mode.Perm()|0o600)
}
func (Local) SetModified(p string, t time.Time) error { return os.Chtimes(p, t, t) }
func (Local) Join(e ...string) string                 { return filepath.Join(e...) }
func (Local) Dir(p string) string                     { return filepath.Dir(p) }
func (Local) Base(p string) string                    { return filepath.Base(p) }
func (Local) Abs(p string) (string, error)            { return filepath.Abs(p) }

// Remote is a server's file system over SFTP.
type Remote struct {
	C *sftp.Client
}

func (r Remote) Home() (string, error) { return r.C.Getwd() }

func (r Remote) ReadDir(p string) ([]Entry, error) {
	fis, err := r.C.ReadDir(p)
	if err != nil {
		return nil, err
	}
	out := make([]Entry, 0, len(fis))
	for _, fi := range fis {
		e := entry(fi)
		if e.Link {
			if st, err := r.C.Stat(path.Join(p, fi.Name())); err == nil && st.IsDir() {
				e.Dir = true
			}
		}
		out = append(out, e)
	}
	sortEntries(out)
	return out, nil
}

func (r Remote) Stat(p string) (Entry, error) {
	fi, err := r.C.Stat(p)
	if err != nil {
		return Entry{}, err
	}
	return entry(fi), nil
}

func (r Remote) MkdirAll(p string) error  { return r.C.MkdirAll(p) }
func (r Remote) RemoveAll(p string) error { return r.C.RemoveAll(p) }
func (r Remote) Rename(a, b string) error {
	if err := r.C.PosixRename(a, b); err != nil {
		return r.C.Rename(a, b) // servers without posix-rename@openssh.com
	}
	return nil
}
func (r Remote) Open(p string) (io.ReadCloser, error) {
	f, err := r.C.Open(p)
	if err != nil {
		return nil, err
	}
	return f, nil
}
func (r Remote) Create(p string, mode fs.FileMode) (io.WriteCloser, error) {
	f, err := r.C.OpenFile(p, os.O_WRONLY|os.O_CREATE|os.O_TRUNC)
	if err != nil {
		return nil, err
	}
	_ = f.Chmod(mode.Perm() | 0o600)
	return f, nil
}
func (r Remote) SetModified(p string, t time.Time) error { return r.C.Chtimes(p, t, t) }
func (Remote) Join(e ...string) string                   { return path.Join(e...) }
func (Remote) Dir(p string) string                       { return path.Dir(p) }
func (Remote) Base(p string) string                      { return path.Base(p) }
func (r Remote) Abs(p string) (string, error) {
	if path.IsAbs(p) {
		return path.Clean(p), nil
	}
	return r.C.RealPath(p)
}

// Progress of a transfer.
type Progress struct {
	DoneBytes, TotalBytes int64
	DoneFiles, TotalFiles int
	Current               string
}

// ErrExists: the target exists and overwrite is off.
type ErrExists struct{ Path string }

func (e ErrExists) Error() string { return fmt.Sprintf("%s already exists", e.Path) }

type item struct {
	src, dst string
	dir      bool
	size     int64
	mode     fs.FileMode
	modified time.Time
}

// Transfer copies (or moves) srcPaths into the folder dstDir. Folders are
// copied with everything in them. sameTree says that src and dst are the
// same tree (a move there is a rename).
func Transfer(ctx context.Context, src FS, srcPaths []string, dst FS, dstDir string, move, overwrite, sameTree bool, report func(Progress)) error {
	if len(srcPaths) == 0 {
		return errors.New("nothing to copy")
	}
	if sameTree {
		for _, p := range srcPaths {
			target := dst.Join(dstDir, src.Base(p))
			if target == p {
				return fmt.Errorf("%s: source and target are the same", p)
			}
			if strings.HasPrefix(dstDir+"/", strings.TrimSuffix(p, "/")+"/") {
				return fmt.Errorf("cannot copy %s into itself", p)
			}
		}
	}
	if move && sameTree {
		for _, p := range srcPaths {
			target := dst.Join(dstDir, src.Base(p))
			if _, err := dst.Stat(target); err == nil {
				if !overwrite {
					return ErrExists{target}
				}
				if err := dst.RemoveAll(target); err != nil {
					return err
				}
			}
			if err := src.Rename(p, target); err != nil {
				return err
			}
		}
		report(Progress{DoneFiles: len(srcPaths), TotalFiles: len(srcPaths)})
		return nil
	}

	// Plan: every folder and file, and the total size.
	var plan []item
	var pr Progress
	var walk func(s, d string) error
	walk = func(s, d string) error {
		if err := ctx.Err(); err != nil {
			return err
		}
		e, err := src.Stat(s)
		if err != nil {
			return err
		}
		if !e.Dir {
			plan = append(plan, item{src: s, dst: d, size: e.Size, mode: e.Mode, modified: e.Modified})
			pr.TotalBytes += e.Size
			pr.TotalFiles++
			return nil
		}
		plan = append(plan, item{src: s, dst: d, dir: true})
		kids, err := src.ReadDir(s)
		if err != nil {
			return err
		}
		for _, k := range kids {
			if err := walk(src.Join(s, k.Name), dst.Join(d, k.Name)); err != nil {
				return err
			}
		}
		return nil
	}
	for _, p := range srcPaths {
		target := dst.Join(dstDir, src.Base(p))
		if _, err := dst.Stat(target); err == nil && !overwrite {
			return ErrExists{target}
		}
		if err := walk(p, target); err != nil {
			return err
		}
	}
	report(pr)

	buf := make([]byte, 256<<10)
	last := time.Now()
	for _, it := range plan {
		if err := ctx.Err(); err != nil {
			return err
		}
		if it.dir {
			if err := dst.MkdirAll(it.dst); err != nil {
				return err
			}
			continue
		}
		pr.Current = it.src
		if err := copyFile(ctx, src, dst, it, buf, func(n int64) {
			pr.DoneBytes += n
			if time.Since(last) > 150*time.Millisecond {
				last = time.Now()
				report(pr)
			}
		}); err != nil {
			return err
		}
		pr.DoneFiles++
		report(pr)
	}
	if move {
		for _, p := range srcPaths {
			if err := src.RemoveAll(p); err != nil {
				return fmt.Errorf("copied, but the source was not removed: %w", err)
			}
		}
	}
	return nil
}

func copyFile(ctx context.Context, src, dst FS, it item, buf []byte, add func(int64)) error {
	in, err := src.Open(it.src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := dst.Create(it.dst, it.mode)
	if err != nil {
		return err
	}
	for {
		if err := ctx.Err(); err != nil {
			out.Close()
			return err
		}
		n, rerr := in.Read(buf)
		if n > 0 {
			if _, err := out.Write(buf[:n]); err != nil {
				out.Close()
				return err
			}
			add(int64(n))
		}
		if rerr == io.EOF {
			break
		}
		if rerr != nil {
			out.Close()
			return rerr
		}
	}
	if err := out.Close(); err != nil {
		return err
	}
	if !it.modified.IsZero() {
		_ = dst.SetModified(it.dst, it.modified)
	}
	return nil
}
