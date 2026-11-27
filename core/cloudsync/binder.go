package cloudsync

import (
	"context"
	"io"
	"strings"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"

	"sshmanager/core/cloudsync/pb"
)

// Caller is CloudSync's bound service on Android (CONNECTOR.md § 3.2),
// implemented in Kotlin: method is "Get", "Put", ...; the request and the
// result are serialized messages, the result always a CallReply.
type Caller interface {
	Call(method string, request []byte) ([]byte, error)
}

// BinderDialer reaches CloudSync through a Caller. Watch is not offered
// (it needs a callback interface); the 30 s rounds cover it.
type BinderDialer struct {
	// Get returns the bound service, or nil when CloudSync is missing.
	Get func() Caller
}

// Dial implements Dialer.
func (d BinderDialer) Dial(context.Context) (pb.ConnectorClient, io.Closer, error) {
	c := d.Get()
	if c == nil {
		return nil, nil, ErrNotRunning
	}
	return pb.NewConnectorClient(binderConn{c}), io.NopCloser(nil), nil
}

// binderConn carries unary gRPC calls over Caller.Call.
type binderConn struct{ c Caller }

func (b binderConn) Invoke(ctx context.Context, method string, args, reply any, _ ...grpc.CallOption) error {
	req, ok := args.(proto.Message)
	if !ok {
		return status.Error(codes.Internal, "not a proto message")
	}
	data, err := proto.Marshal(req)
	if err != nil {
		return err
	}
	name := method[strings.LastIndex(method, "/")+1:]
	type result struct {
		out []byte
		err error
	}
	done := make(chan result, 1)
	go func() {
		out, err := b.c.Call(name, data)
		done <- result{out, err}
	}()
	var r result
	select {
	case <-ctx.Done():
		return status.FromContextError(ctx.Err()).Err()
	case r = <-done:
	}
	if r.err != nil {
		// DeadObjectException and the like: CloudSync went away.
		return status.Error(codes.Unavailable, r.err.Error())
	}
	var cr pb.CallReply
	if err := proto.Unmarshal(r.out, &cr); err != nil {
		return status.Error(codes.Internal, "bad reply from CloudSync: "+err.Error())
	}
	if cr.Code != 0 {
		return status.Error(codes.Code(cr.Code), cr.Message)
	}
	return proto.Unmarshal(cr.Payload, reply.(proto.Message))
}

func (binderConn) NewStream(context.Context, *grpc.StreamDesc, string, ...grpc.CallOption) (grpc.ClientStream, error) {
	return nil, status.Error(codes.Unimplemented, "streams are not carried over the bound service")
}

var _ grpc.ClientConnInterface = binderConn{}
