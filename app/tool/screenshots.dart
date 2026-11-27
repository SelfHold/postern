// ignore_for_file: use_build_context_synchronously
// Renders every section at a desktop and a phone width against a running
// core and writes PNGs, for checking the UI against the design rules.
// Needs a trusted-or-not host "devsshd" (go run ./tools/devsshd):
//
//   SHOTS=/tmp/shots flutter run -d linux -t tool/screenshots.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sshmanager/app.dart';
import 'package:sshmanager/core/settings.dart';
import 'package:sshmanager/data/core.dart';
import 'package:sshmanager/data/endpoint.dart';
import 'package:sshmanager/data/rpc/gen/sshm.pb.dart' as pb;
import 'package:sshmanager/data/sessions.dart';
import 'package:sshmanager/presentation/files/files_screen.dart';
import 'package:sshmanager/presentation/hosts/host_editor.dart';
import 'package:sshmanager/presentation/hosts/trust.dart';
import 'package:sshmanager/presentation/shell/app_shell.dart';

final _boundary = GlobalKey();
// One key per frame: a shared GlobalKey would carry the shell's state (the
// section) from frame to frame.
final _shells = <int, GlobalKey>{};
BuildContext get _shell => _shells[_shells.keys.reduce((a, b) => a > b ? a : b)]!.currentContext!;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load();
  final out = Directory(Platform.environment['SHOTS'] ?? 'shots')..createSync(recursive: true);
  core = Core(CoreLauncher.forPlatform());
  await core.connect();

  // A live session and a remote panel, so Terminal and Files have content.
  final dev = core.hosts.where((h) => h.name == 'devsshd').firstOrNull;
  if (dev != null) {
    final k = await core.api.probeHostKey(pb.HostRef(id: dev.id));
    await core.api.trustHostKey(pb.TrustRequest(id: dev.id, key: k.key, replace: true));
    await core.refresh();
    final s = sessions.open(core.host(dev.id)!);
    await Future<void>.delayed(const Duration(seconds: 1));
    s.terminal.textInput('echo hello from SSH Manager\r');
    files.showHost(dev.id);
    files.right.load('/usr');
    files.left.load('/etc');
  }

  final frame = ValueNotifier<(Size, Section, int)>((const Size(1440, 900), Section.hosts, 0));
  runApp(
    ValueListenableBuilder(
      valueListenable: frame,
      builder: (_, f, _) => SshManagerApp(
        key: ValueKey(f),
        home: AppShell(key: _shells.putIfAbsent(f.$3, GlobalKey.new), initial: f.$2),
        frame: (context, child) {
          final mq = MediaQuery.of(context);
          return RepaintBoundary(
            key: _boundary,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: f.$1.width,
              maxWidth: f.$1.width,
              minHeight: f.$1.height,
              maxHeight: f.$1.height,
              child: MediaQuery(
                data: mq.copyWith(size: f.$1, padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero),
                child: child!,
              ),
            ),
          );
        },
      ),
    ),
  );

  const sizes = {'desktop': Size(1280, 720), 'phone': Size(390, 844)};
  Future<void> shot(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    final ro = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await ro.toImage(pixelRatio: 1);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    await File('${out.path}/$name.png').writeAsBytes(png!.buffer.asUint8List());
    stdout.writeln('shot $name');
  }

  for (final s in Section.values) {
    for (final e in sizes.entries) {
      frame.value = (e.value, s, frame.value.$3 + 1);
      await shot('${s.name}-${e.key}');
    }
  }
  // Dialogs: the host editor and the first-connection key check.
  for (final e in sizes.entries) {
    frame.value = (e.value, Section.hosts, frame.value.$3 + 1);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    editHost(_shell, core.hosts.firstWhere((h) => h.name == 'web-1'));
    await shot('editor-${e.key}');
  }
  if (dev != null) {
    // Another address = another machine: the core forgets the trusted key.
    await core.api.saveHost(core.host(dev.id)!..address = 'localhost');
    await core.refresh();
    frame.value = (sizes['desktop']!, Section.hosts, frame.value.$3 + 1);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    ensureTrusted(_shell, core.host(dev.id)!);
    await shot('trust-desktop');
  }
  exit(0);
}
