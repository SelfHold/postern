import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../data/native_core.dart';

/// Desktop window chrome: a frameless window drawn by the app (the header
/// is the title bar).
class DesktopWindow with WindowListener {
  DesktopWindow._();

  static final instance = DesktopWindow._();

  static bool get supported => Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  Future<void> init() async {
    if (!supported) return;
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      title: 'SSH Manager',
      size: Size(1440, 900),
      minimumSize: Size(420, 560),
      center: true,
      backgroundColor: Color(0xFF080C10), // --hm-bg before the first frame
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    // Alt+F4 and the like also go through close(), so the core stops first.
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
  }

  @override
  void onWindowClose() => close();

  /// Closes the window and the app; the core closes the SSH connections
  /// first (it lives in this process).
  Future<void> close() async {
    await windowManager.hide(); // gone at once; the core may take a moment
    NativeCore.stop();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  Future<void> minimize() => windowManager.minimize();

  Future<void> toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }
}
