// Command devsshd is a throwaway SSH server for trying the app without a
// real server: 127.0.0.1 only, user "tester", password "secret", an echo
// shell and SFTP over this machine's files. Never expose it.
package main

import (
	"crypto/ed25519"
	"crypto/rand"
	"encoding/binary"
	"flag"
	"io"
	"log"
	"net"

	"github.com/pkg/sftp"
	"golang.org/x/crypto/ssh"
)

func main() {
	addr := flag.String("listen", "127.0.0.1:2222", "address (keep it on localhost)")
	flag.Parse()
	_, priv, _ := ed25519.GenerateKey(rand.Reader)
	signer, err := ssh.NewSignerFromKey(priv)
	if err != nil {
		log.Fatal(err)
	}
	cfg := &ssh.ServerConfig{
		PasswordCallback: func(c ssh.ConnMetadata, pw []byte) (*ssh.Permissions, error) {
			if c.User() == "tester" && string(pw) == "secret" {
				return nil, nil
			}
			return nil, io.EOF
		},
	}
	cfg.AddHostKey(signer)
	lis, err := net.Listen("tcp", *addr)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("devsshd on %s (tester / secret), key %s", *addr, ssh.FingerprintSHA256(signer.PublicKey()))
	for {
		c, err := lis.Accept()
		if err != nil {
			log.Fatal(err)
		}
		go serveConn(c, cfg)
	}
}

func serveConn(c net.Conn, cfg *ssh.ServerConfig) {
	_, chans, reqs, err := ssh.NewServerConn(c, cfg)
	if err != nil {
		return
	}
	go ssh.DiscardRequests(reqs)
	for nc := range chans {
		if nc.ChannelType() != "session" {
			nc.Reject(ssh.UnknownChannelType, "no")
			continue
		}
		ch, in, err := nc.Accept()
		if err != nil {
			continue
		}
		go func() {
			for req := range in {
				switch req.Type {
				case "pty-req", "window-change", "env":
					req.Reply(true, nil)
				case "shell":
					req.Reply(true, nil)
					go func() {
						ch.Write([]byte("welcome\r\n"))
						io.Copy(ch, ch) // echo
						ch.SendRequest("exit-status", false, binary.BigEndian.AppendUint32(nil, 0))
						ch.Close()
					}()
				case "subsystem":
					if len(req.Payload) > 4 && string(req.Payload[4:]) == "sftp" {
						req.Reply(true, nil)
						go func() {
							srv, _ := sftp.NewServer(ch)
							srv.Serve()
							ch.Close()
						}()
					} else {
						req.Reply(false, nil)
					}
				default:
					req.Reply(false, nil)
				}
			}
		}()
	}
}
