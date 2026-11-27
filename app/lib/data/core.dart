import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';

import '../core/i18n.dart';
import 'endpoint.dart';
import 'rpc/gen/postern.pbgrpc.dart' as pb;

export 'rpc/gen/postern.pbgrpc.dart' show Host, Host_Auth, SyncState, SyncState_Phase, Entry, HostKey_Status, SafeKey;

enum Conn { connecting, ready, failed }

/// The connection to the core and what the app shows from it: state, the
/// host list, change events. Screens listen to [core].
class Core extends ChangeNotifier {
  Core(this._launcher);

  final CoreLauncher _launcher;
  ClientChannel? _channel;
  pb.CoreClient? _api;
  StreamSubscription<pb.Event>? _events;
  Timer? _retry;

  Conn conn = Conn.connecting;
  String? error;
  pb.State? state;
  List<pb.Host> hosts = const [];

  /// A host got the id Shard chose for it: (old id, new id).
  final rekeys = StreamController<(String, String)>.broadcast();

  pb.CoreClient get api {
    final a = _api;
    if (a == null) throw StateError(tr('No connection to the core', 'Нет связи с ядром'));
    return a;
  }

  pb.SyncState get sync => state?.sync ?? pb.SyncState();

  pb.Host? host(String id) {
    for (final h in hosts) {
      if (h.id == id) return h;
    }
    return null;
  }

  Future<void> connect() async {
    _retry?.cancel();
    conn = Conn.connecting;
    notifyListeners();
    try {
      final e = await _launcher.endpoint();
      await _channel?.shutdown();
      final ch = ClientChannel(
        e.address,
        port: e.port,
        options: const ChannelOptions(credentials: ChannelCredentials.insecure(), idleTimeout: Duration(hours: 12)),
      );
      _channel = ch;
      _api = pb.CoreClient(ch, options: CallOptions(metadata: {'authorization': 'Bearer ${e.token}'}));
      // Change events: hosts, sync state; a broken stream means the core is gone.
      await _events?.cancel();
      _events = _api!.events(pb.Empty()).listen(_onEvent, onError: (_) => _lost(), onDone: _lost);
      await refresh();
      conn = Conn.ready;
      error = null;
    } catch (e) {
      conn = Conn.failed;
      error = errorText(e);
      _retry = Timer(const Duration(seconds: 5), connect);
    }
    notifyListeners();
  }

  void _lost() {
    if (conn == Conn.connecting) return;
    conn = Conn.failed;
    error = tr('Connection to the core lost', 'Связь с ядром потеряна');
    notifyListeners();
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 1), connect);
  }

  void _onEvent(pb.Event e) {
    if (e.message.startsWith('rekey ')) {
      final parts = e.message.split(' ');
      if (parts.length == 3) rekeys.add((parts[1], parts[2]));
    }
    unawaited(refresh().catchError((_) {}));
  }

  Future<void> refresh() async {
    final a = api;
    final results = await Future.wait([a.getState(pb.Empty()), a.listHosts(pb.Empty())]);
    state = results[0] as pb.State;
    hosts = (results[1] as pb.HostList).hosts;
    notifyListeners();
  }

  /// Applies a sync state answered by a call without waiting for the event.
  void setSync(pb.SyncState s) {
    state = (state?.deepCopy() ?? pb.State())..sync = s;
    notifyListeners();
  }
}

/// The one core of the app.
late final Core core;

/// The core refused to connect because the server's key is not trusted.
bool isHostKeyError(Object e) => e is GrpcError && e.code == StatusCode.failedPrecondition && (e.message ?? '').startsWith('hostkey:');

/// A short human message for a failed call.
String errorText(Object e) {
  if (e is GrpcError) {
    var m = e.message ?? '';
    if (m.startsWith('hostkey: ')) m = m.substring(9);
    return switch (e.code) {
      StatusCode.unavailable when m.isEmpty || m.contains('connection') && m.contains('refused') && m.contains('sock') =>
        tr('No connection to the core', 'Нет связи с ядром'),
      StatusCode.deadlineExceeded => tr('Timed out', 'Превышено время ожидания'),
      StatusCode.cancelled => tr('Cancelled', 'Отменено'),
      _ => m.isEmpty ? e.codeName : m,
    };
  }
  return e.toString();
}
