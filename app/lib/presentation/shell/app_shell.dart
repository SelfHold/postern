import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/config/app_config.dart';
import '../../core/desktop/desktop_window.dart';
import '../../core/i18n.dart';
import '../../core/settings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/core.dart';
import '../../data/sessions.dart';
import '../common/hm.dart';
import '../files/files_screen.dart';
import '../hosts/hosts_screen.dart';
import '../sync/sync_screen.dart';
import '../terminal/terminal_screen.dart';

enum Section { hosts, terminal, files, sync }

extension on Section {
  String get label => switch (this) {
    Section.hosts => tr('Hosts', 'Хосты'),
    Section.terminal => tr('Terminal', 'Терминал'),
    Section.files => tr('Files', 'Файлы'),
    Section.sync => 'CloudSync',
  };

  IconData get icon => switch (this) {
    Section.hosts => Icons.dns_outlined,
    Section.terminal => Icons.terminal,
    Section.files => Icons.folder_copy_outlined,
    Section.sync => Icons.cloud_sync_outlined,
  };
}

/// The page shell (desktop and phone layouts): header, canvas and footer
/// on desktops, a header and a tab bar on phones.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initial = Section.hosts});

  final Section initial;

  static _AppShellState? _of(BuildContext c) => c.findAncestorStateOfType<_AppShellState>();

  /// Opens a section.
  static void go(BuildContext context, Section s) => _of(context)?._go(s);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late Section _section = widget.initial;

  void _go(Section s) {
    if (s != _section) HapticFeedback.selectionClick();
    setState(() => _section = s);
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    return ListenableBuilder(
      listenable: core,
      builder: (context, _) {
        final Widget page = switch (core.conn) {
          Conn.ready => switch (_section) {
            Section.hosts => const HostsScreen(),
            Section.terminal => const TerminalScreen(),
            Section.files => const FilesScreen(),
            Section.sync => const SyncScreen(),
          },
          _ when core.state != null && core.conn == Conn.connecting => const HmLoading(),
          Conn.connecting => const HmLoading(),
          Conn.failed => _CoreDown(error: core.error),
        };
        final body = Stack(
          children: [
            const Positioned.fill(child: _GridBackground()),
            Positioned.fill(
              child: KeyedSubtree(key: ValueKey(_section), child: page),
            ),
          ],
        );
        if (hm.mobile) {
          return Scaffold(
            backgroundColor: HmColors.bg,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const _MobileHeader(),
                  Expanded(child: body),
                ],
              ),
            ),
            bottomNavigationBar: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: HmColors.border)),
              ),
              child: NavigationBar(
                selectedIndex: _section.index,
                onDestinationSelected: (i) => _go(Section.values[i]),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [for (final s in Section.values) NavigationDestination(icon: Icon(s.icon), label: s.label, tooltip: '')],
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: HmColors.bezel,
          body: Container(
            margin: const EdgeInsets.all(8), // viewport bezel
            color: HmColors.bg,
            child: Column(
              children: [
                _Header(section: _section, onGo: _go),
                Expanded(child: body),
                const _Footer(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CoreDown extends StatelessWidget {
  const _CoreDown({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) => HmPage(
    children: [
      HmEmptyState(
        error ?? tr('No connection to the core', 'Нет связи с ядром'),
        icon: Icons.power_off_outlined,
        action: HmButton(tr('Retry', 'Повторить'), icon: Icons.refresh, onPressed: core.connect),
      ),
    ],
  );
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: RepaintBoundary(child: CustomPaint(painter: _GridPainter())),
  );
}

/// Fixed 40 px cyan grid at 3 %; it does not scroll with content.
class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HmColors.tint(HmColors.accent, HmColors.subtle)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final _headerGradient = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [HmColors.tint(HmColors.accent, 0.04), HmColors.tint(HmColors.accent, 0)]);

/// Desktop header: logo and nav links. There is no sign-in, so the
/// identity anchors are hidden.
class _Header extends StatelessWidget {
  const _Header({required this.section, required this.onGo});

  final Section section;
  final ValueChanged<Section> onGo;

  @override
  Widget build(BuildContext context) => _TitleBar(
    child: Container(
      padding: const EdgeInsets.fromLTRB(32, 14, 12, 14),
      decoration: BoxDecoration(
        gradient: _headerGradient,
        border: const Border(bottom: BorderSide(color: HmColors.border)),
      ),
      child: Row(
        children: [
          Text('SSH Manager', style: HmText.logo),
          const Spacer(),
          for (final s in Section.values) ...[
            ListenableBuilder(
              listenable: sessions,
              builder: (context, _) =>
                  _NavLink(label: s == Section.terminal && sessions.list.isNotEmpty ? '${s.label} · ${sessions.list.length}' : s.label, active: section == s, onTap: () => onGo(s)),
            ),
            const SizedBox(width: 12),
          ],
          Container(width: 1, height: 18, margin: const EdgeInsets.symmetric(horizontal: 4), color: HmColors.border),
          const SizedBox(width: 12),
          const _LangSwitch(),
          if (DesktopWindow.supported) ...[const SizedBox(width: 12), const _WindowButtons()],
        ],
      ),
    ),
  );
}

/// The header doubles as the window title bar: drag to move, double-click
/// to maximize.
class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DesktopWindow.supported ? DragToMoveArea(child: child) : child;
}

class _LangSwitch extends StatelessWidget {
  const _LangSwitch();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final l in Lang.values) _WindowButton(label: l.name.toUpperCase(), tooltip: l == Lang.en ? 'English' : 'Русский', active: lang.value == l, onTap: () => AppSettings.setLanguage(l)),
    ],
  );
}

class _WindowButtons extends StatelessWidget {
  const _WindowButtons();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _WindowButton(icon: Icons.remove, tooltip: tr('Minimize', 'Свернуть'), onTap: DesktopWindow.instance.minimize),
      _WindowButton(icon: Icons.crop_square, tooltip: tr('Maximize', 'Развернуть'), onTap: DesktopWindow.instance.toggleMaximize),
      _WindowButton(icon: Icons.close, tooltip: tr('Close', 'Закрыть'), danger: true, onTap: DesktopWindow.instance.close),
    ],
  );
}

class _WindowButton extends StatefulWidget {
  const _WindowButton({required this.tooltip, required this.onTap, this.icon, this.label, this.danger = false, this.active = false});

  final IconData? icon;
  final String? label;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;
  final bool active;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.danger ? HmColors.error : HmColors.accent;
    final color = _hot || widget.active ? base : HmColors.muted;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hot = true),
        onExit: (_) => setState(() => _hot = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.label == null ? 32 : null,
            height: 28,
            margin: const EdgeInsets.only(left: 2),
            padding: widget.label == null ? null : const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HmColors.tint(base, (_hot ? 0.10 : 0.0) + (widget.active ? 0.08 : 0.0)),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: widget.active ? HmColors.tint(base, HmColors.ring) : Colors.transparent),
            ),
            child: widget.label != null ? Text(widget.label!, style: HmText.nav.copyWith(color: color)) : Icon(widget.icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({required this.label, required this.onTap, this.active = false});

  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    const base = HmColors.accent;
    final alpha = (widget.active ? 0.08 : 0.0) + (_hot ? 0.10 : 0.0);
    return Semantics(
      button: true,
      selected: widget.active,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hot = true),
        onExit: (_) => setState(() => _hot = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: HmColors.tint(base, alpha),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.active ? HmColors.tint(base, HmColors.ring) : Colors.transparent),
            ),
            child: Text(widget.label.toUpperCase(), style: HmText.nav.copyWith(color: widget.active || _hot ? base : HmColors.muted)),
          ),
        ),
      ),
    );
  }
}

/// Phone header: logo and the live connection dot.
class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) => _TitleBar(
    child: Container(
      height: 56,
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        gradient: _headerGradient,
        border: const Border(bottom: BorderSide(color: HmColors.border)),
      ),
      child: Row(
        children: [
          // Takes the free space and gives way first in a narrow window.
          Expanded(
            child: Text('SSH Manager', style: HmText.logo.copyWith(fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          HmDot(ok: core.conn == Conn.ready, label: core.conn == Conn.ready ? tr('Online', 'В сети') : tr('Offline', 'Не в сети')),
          const SizedBox(width: 8),
          const _LangSwitch(),
          if (DesktopWindow.supported) ...[const SizedBox(width: 8), const _WindowButtons()],
        ],
      ),
    ),
  );
}

/// Desktop status bar: version and build, connection and env pills.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final st = core.state;
    final same = st == null || (st.coreVersion == AppConfig.version && st.coreBuild == AppConfig.buildId);
    const dot = Opacity(opacity: 0.4, child: Text('  ·  '));
    final sync = core.sync;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [HmColors.tint(HmColors.accent, 0.04), HmColors.tint(HmColors.accent, 0)]),
        border: const Border(top: BorderSide(color: HmColors.border)),
      ),
      child: DefaultTextStyle(
        style: HmText.footer,
        child: Row(
          children: [
            Text('SSH MANAGER V${AppConfig.version}'),
            dot,
            Text('BUILD ${AppConfig.shortSha}'.toUpperCase()),
            if (st != null) ...[
              dot,
              Text(
                'CORE ${st.coreVersion} ${st.coreBuild}${same ? '' : tr(' — differs from the app', ' — не совпадает с приложением')}'.toUpperCase(),
                style: same ? null : const TextStyle(color: HmColors.warning),
              ),
            ],
            const Spacer(),
            HmPill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HmDot(ok: core.conn == Conn.ready),
                  const SizedBox(width: 6),
                  Text((core.conn == Conn.ready ? tr('core online', 'ядро в сети') : tr('core offline', 'ядро не в сети')).toUpperCase()),
                ],
              ),
            ),
            const SizedBox(width: 12),
            HmPill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Off is a choice, not a failure: no dot then.
                  if (sync.enabled) ...[HmDot(ok: sync.phase == SyncState_Phase.SYNCED), const SizedBox(width: 6)],
                  Text(syncLabel(sync).toUpperCase()),
                ],
              ),
            ),
            const SizedBox(width: 12),
            HmPill(tone: HmTone.accent, child: Text('ENV: ${AppConfig.env}'.toUpperCase())),
            const Spacer(),
            if (sync.deviceName.isNotEmpty) Text(sync.deviceName.toUpperCase()),
          ],
        ),
      ),
    );
  }
}
