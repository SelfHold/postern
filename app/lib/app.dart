import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import 'core/desktop/desktop_window.dart';
import 'core/i18n.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/layout.dart';
import 'presentation/common/overlays.dart';
import 'presentation/shell/app_shell.dart';

class SshManagerApp extends StatefulWidget {
  const SshManagerApp({super.key, this.home = const AppShell(), this.frame});

  final Widget home;

  /// Wraps the whole app (tool/screenshots.dart renders it at a fixed size).
  final TransitionBuilder? frame;

  @override
  State<SshManagerApp> createState() => _SshManagerAppState();
}

class _SshManagerAppState extends State<SshManagerApp> {
  @override
  void initState() {
    super.initState();
    lang.addListener(_relabel);
  }

  @override
  void dispose() {
    lang.removeListener(_relabel);
    super.dispose();
  }

  /// Strings come from tr() in build methods, so a language switch
  /// rebuilds every element; state (current page, forms) is kept.
  void _relabel() {
    setState(() {});
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    (context as Element).visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SSH Manager',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.dark,
    locale: currentLocale,
    supportedLocales: const [Locale('en'), Locale('ru')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: widget.home,
    // Toasts after the navigator: above modals.
    builder: (context, child) {
      final app = Stack(children: [?child, ToastHost(bottomOffset: Hm.of(context).mobile ? 56 : 0)]);
      if (widget.frame != null) return widget.frame!(context, app);
      return DesktopWindow.supported && Platform.isLinux ? DragToResizeArea(resizeEdgeSize: 6, child: app) : app;
    },
  );
}
