import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';
import 'package:xterm/xterm.dart';

import '../core/i18n.dart';
import 'core.dart';
import 'rpc/gen/sshm.pbgrpc.dart' as pb;

enum SessionStatus { connecting, open, closed }

/// One terminal: an xterm buffer and the Shell stream behind it. It lives
/// while its tab is open, across screen switches.
class Session extends ChangeNotifier {
  Session(this.hostId, this.title) {
    terminal.onOutput = (data) => _send(pb.ShellIn(data: utf8.encode(data)));
    terminal.onResize = (w, h, _, _) => _send(pb.ShellIn(resize: pb.ShellIn_Resize(cols: w, rows: h)));
    start();
  }

  static int _seq = 0;
  final int id = ++_seq;
  String hostId;
  final String title;
  final terminal = Terminal(maxLines: 10000);

  SessionStatus status = SessionStatus.connecting;
  String? error;
  bool hostKeyProblem = false;

  StreamController<pb.ShellIn>? _out;
  ResponseStream<pb.ShellOut>? _in;
  StreamSubscription<pb.ShellOut>? _sub;

  void _send(pb.ShellIn m) {
    if (status == SessionStatus.open) _out?.add(m);
  }

  /// Opens (or re-opens) the shell.
  void start() {
    _closeStreams();
    status = SessionStatus.connecting;
    error = null;
    hostKeyProblem = false;
    notifyListeners();
    final out = StreamController<pb.ShellIn>();
    _out = out;
    out.add(pb.ShellIn(open: pb.ShellIn_Open(hostId: hostId, cols: terminal.viewWidth, rows: terminal.viewHeight)));
    final decoder = const Utf8Decoder(allowMalformed: true).startChunkedConversion(_TerminalSink(terminal));
    try {
      _in = core.api.shell(out.stream);
    } catch (e) {
      _fail(e);
      return;
    }
    _sub = _in!.listen(
      (m) {
        if (m.hasOpened()) {
          status = SessionStatus.open;
          notifyListeners();
          // The view may have been laid out before the shell was open.
          out.add(pb.ShellIn(resize: pb.ShellIn_Resize(cols: terminal.viewWidth, rows: terminal.viewHeight)));
        } else if (m.hasData()) {
          decoder.add(m.data);
        } else if (m.hasClosed()) {
          _end(m.closed.isEmpty ? null : m.closed);
        }
      },
      onError: _fail,
      onDone: () {
        if (status != SessionStatus.closed) _end(null);
      },
    );
  }

  void _fail(Object e) {
    hostKeyProblem = isHostKeyError(e);
    _end(errorText(e));
  }

  void _end(String? why) {
    status = SessionStatus.closed;
    error = why;
    terminal.write('\r\n\x1b[2m${tr('[session closed]', '[сеанс закрыт]')}${why == null ? '' : ' $why'}\x1b[0m\r\n');
    _closeStreams();
    notifyListeners();
  }

  void _closeStreams() {
    _sub?.cancel();
    _sub = null;
    _out?.close();
    _out = null;
    _in = null;
  }

  @override
  void dispose() {
    _closeStreams();
    super.dispose();
  }
}

class _TerminalSink implements Sink<String> {
  _TerminalSink(this.t);
  final Terminal t;

  @override
  void add(String data) => t.write(data);

  @override
  void close() {}
}

/// The open terminal tabs.
class Sessions extends ChangeNotifier {
  final List<Session> list = [];
  int active = 0;

  Session? get current => list.isEmpty ? null : list[active.clamp(0, list.length - 1)];

  Sessions() {
    core.rekeys.stream.listen((r) {
      for (final s in list) {
        if (s.hostId == r.$1) s.hostId = r.$2;
      }
    });
  }

  Session open(pb.Host h) {
    final s = Session(h.id, h.name);
    s.addListener(notifyListeners);
    list.add(s);
    active = list.length - 1;
    notifyListeners();
    return s;
  }

  void select(int i) {
    active = i;
    notifyListeners();
  }

  void close(Session s) {
    final i = list.indexOf(s);
    if (i < 0) return;
    list.removeAt(i);
    s.dispose();
    if (active >= list.length) active = list.length - 1;
    if (active < 0) active = 0;
    notifyListeners();
  }
}

final sessions = Sessions();
