import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';
import 'package:path/path.dart' as p;

import '../../core/i18n.dart';
import '../../data/core.dart';
import '../../data/rpc/gen/sshm.pb.dart' as pb;

/// ".." at the top of a listing.
final Entry parentEntry = Entry(name: '..', dir: true);

/// One panel: a side ("" = this device, otherwise a host id) and a folder.
class PanelModel extends ChangeNotifier {
  String side = '';
  String path = '';
  List<Entry> entries = [];
  final Set<String> selected = {};
  int cursor = 0;
  bool loading = false;
  String? error;

  /// The listing failed because the server's key is not trusted.
  bool hostKeyProblem = false;

  bool get remote => side.isNotEmpty;

  p.Context get _ctx => remote ? p.posix : (Platform.isWindows ? p.windows : p.posix);

  String join(String name) => _ctx.join(path, name);

  bool get atRoot => _ctx.rootPrefix(path) == path;

  String title() {
    if (!remote) return tr('This device', 'Это устройство');
    return core.host(side)?.name ?? side;
  }

  Entry? get current => entries.isEmpty ? null : entries[cursor.clamp(0, entries.length - 1)];

  /// The items an operation works on: the selection, else the cursor.
  List<String> targets() {
    if (selected.isNotEmpty) return [for (final n in selected) join(n)];
    final c = current;
    if (c == null || identical(c, parentEntry)) return [];
    return [join(c.name)];
  }

  int _seq = 0;

  Future<void> load([String? to, String? focus]) async {
    // Only the newest listing counts: a slow answer to an older request
    // (a click before) must not replace it.
    final seq = ++_seq;
    loading = true;
    error = null;
    hostKeyProblem = false;
    notifyListeners();
    try {
      final r = await core.api.listDir(pb.DirRequest(side: side, path: to ?? path));
      if (seq != _seq) return;
      final moved = r.path != path;
      path = r.path;
      entries = [if (!atRoot) parentEntry, ...r.entries];
      selected.removeWhere((n) => !entries.any((e) => e.name == n));
      if (moved) selected.clear();
      if (focus != null) {
        final i = entries.indexWhere((e) => e.name == focus);
        cursor = i < 0 ? 0 : i;
      } else if (moved) {
        cursor = 0;
      }
      cursor = cursor.clamp(0, entries.isEmpty ? 0 : entries.length - 1);
    } catch (e) {
      if (seq != _seq) return;
      error = errorText(e);
      hostKeyProblem = isHostKeyError(e);
    } finally {
      if (seq == _seq) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void setSide(String s) {
    side = s;
    path = '';
    entries = [];
    selected.clear();
    cursor = 0;
    load();
  }

  Future<void> open(Entry e) async {
    if (identical(e, parentEntry)) return up();
    if (e.dir) await load(join(e.name));
  }

  Future<void> up() async {
    if (atRoot) return;
    final from = _ctx.basename(path);
    await load(_ctx.dirname(path), from);
  }

  void move(int delta) {
    if (entries.isEmpty) return;
    cursor = (cursor + delta).clamp(0, entries.length - 1);
    notifyListeners();
  }

  void setCursor(int i) {
    cursor = i;
    notifyListeners();
  }

  void toggle(Entry e) {
    if (identical(e, parentEntry)) return;
    if (!selected.remove(e.name)) selected.add(e.name);
    notifyListeners();
  }

  int get selectedSize {
    var n = 0;
    for (final e in entries) {
      if (selected.contains(e.name) && !e.dir) n += e.size.toInt();
    }
    return n;
  }
}

/// A running copy or move.
class TransferState {
  TransferState(this.label);

  final String label;
  pb.TransferProgress progress = pb.TransferProgress();
  ResponseStream<pb.TransferProgress>? stream;
}

/// The two panels and the running transfer; kept across screen switches.
class FilesModel extends ChangeNotifier {
  FilesModel() {
    left.addListener(notifyListeners);
    right.addListener(notifyListeners);
    core.rekeys.stream.listen((r) {
      for (final pnl in [left, right]) {
        if (pnl.side == r.$1) pnl.side = r.$2;
      }
    });
  }

  final left = PanelModel();
  final right = PanelModel();
  int active = 0;
  bool started = false;
  TransferState? transfer;

  PanelModel get a => active == 0 ? left : right;
  PanelModel get other => active == 0 ? right : left;

  void start() {
    if (started) return;
    started = true;
    left.load();
    right.load();
  }

  void focus(int i) {
    if (active == i) return;
    active = i;
    notifyListeners();
  }

  /// Shows a host in the right panel (from the host list).
  void showHost(String id) {
    started = true;
    if (left.entries.isEmpty && left.error == null) left.load();
    right.setSide(id);
    active = 1;
    notifyListeners();
  }

  /// Copies (or moves) the active panel's targets into the other panel.
  Future<void> copy({required bool move, bool overwrite = false}) async {
    final src = a, dst = other;
    final paths = src.targets();
    if (paths.isEmpty || transfer != null) return;
    final t = TransferState(move ? tr('Moving', 'Перенос') : tr('Copying', 'Копирование'));
    transfer = t;
    notifyListeners();
    try {
      final s = core.api.transfer(pb.TransferRequest(
        srcSide: src.side,
        srcPaths: paths,
        dstSide: dst.side,
        dstDir: dst.path,
        move: move,
        overwrite: overwrite,
      ));
      t.stream = s;
      await for (final p in s) {
        t.progress = p;
        notifyListeners();
      }
      src.selected.clear();
    } finally {
      transfer = null;
      notifyListeners();
      unawaited(src.load());
      unawaited(dst.load());
    }
  }

  void cancelTransfer() => transfer?.stream?.cancel();
}

final files = FilesModel();

/// "1.2 MB".
String fmtSize(num n) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = n.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return i == 0 ? '${n.toInt()} B' : '${v.toStringAsFixed(v < 10 ? 1 : 0)} ${units[i]}';
}
