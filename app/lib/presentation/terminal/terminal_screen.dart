import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/core.dart';
import '../../data/sessions.dart';
import '../common/hm.dart';
import '../hosts/trust.dart';
import '../shell/app_shell.dart';

/// The terminal palette, from the design tokens only.
const _theme = TerminalTheme(
  cursor: HmColors.accent,
  selection: Color(0x4D00D4FF), // --hm-accent @ 30 %
  foreground: HmColors.text,
  background: HmColors.bg,
  black: HmColors.bg,
  red: HmColors.error,
  green: HmColors.ok,
  yellow: HmColors.warning,
  blue: HmColors.active,
  magenta: HmColors.purpleLight,
  cyan: HmColors.accent,
  white: HmColors.text,
  brightBlack: HmColors.paused,
  brightRed: HmColors.error,
  brightGreen: HmColors.ok,
  brightYellow: HmColors.warning,
  brightBlue: HmColors.active,
  brightMagenta: HmColors.purpleLight,
  brightCyan: HmColors.accent,
  brightWhite: HmColors.text,
  searchHitBackground: HmColors.warning,
  searchHitBackgroundCurrent: HmColors.accent,
  searchHitForeground: HmColors.bg,
);

class TerminalScreen extends StatelessWidget {
  const TerminalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    return ListenableBuilder(
      listenable: sessions,
      builder: (context, _) {
        final s = sessions.current;
        if (s == null) {
          return HmPage(
            children: [
              if (!hm.mobile) HmPageTitle(tr('Terminal', 'Терминал')),
              HmEmptyState(
                tr('No open sessions. Open one from the host list.', 'Нет открытых сеансов. Откройте сеанс из списка хостов.'),
                icon: Icons.terminal,
                action: HmButton(tr('Hosts', 'Хосты'), icon: Icons.dns_outlined, onPressed: () => AppShell.go(context, Section.hosts)),
              ),
            ],
          );
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(hm.pageX, hm.mobile ? 8 : 20, hm.pageX, hm.mobile ? 8 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Tabs(),
              const SizedBox(height: Hm.gapXxs),
              Expanded(child: _SessionView(key: ValueKey(s.id), session: s)),
              if (hm.mobile) ...[const SizedBox(height: Hm.gapXxs), _KeyBar(session: s)],
            ],
          ),
        );
      },
    );
  }
}

class _Tabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 32,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (final (i, s) in sessions.list.indexed) ...[
          _Tab(session: s, active: i == sessions.active, onTap: () => sessions.select(i), onClose: () => sessions.close(s)),
          const SizedBox(width: Hm.gapXxs),
        ],
      ],
    ),
  );
}

class _Tab extends StatefulWidget {
  const _Tab({required this.session, required this.active, required this.onTap, required this.onClose});

  final Session session;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _hot = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final alpha = (widget.active ? 0.08 : 0.0) + (_hot ? 0.10 : 0.0);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hot = true),
      onExit: (_) => setState(() => _hot = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.only(left: 12, right: 4),
          decoration: BoxDecoration(
            color: HmColors.tint(HmColors.accent, alpha),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.active ? HmColors.tint(HmColors.accent, HmColors.ring) : HmColors.border),
          ),
          child: Row(
            children: [
              HmDot(ok: s.status == SessionStatus.open),
              const SizedBox(width: 8),
              Text(s.title, style: HmText.nav.copyWith(color: widget.active ? HmColors.accent : HmColors.muted)),
              const SizedBox(width: 4),
              HmIconButton(icon: Icons.close, label: tr('Close', 'Закрыть'), onPressed: widget.onClose),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionView extends StatefulWidget {
  const _SessionView({super.key, required this.session});

  final Session session;

  @override
  State<_SessionView> createState() => _SessionViewState();
}

class _SessionViewState extends State<_SessionView> {
  final _focus = FocusNode();
  final _controller = TerminalController();

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _reconnect() async {
    final s = widget.session;
    if (s.hostKeyProblem) {
      final h = core.host(s.hostId);
      if (h == null || !await ensureTrusted(context, h)) return;
    }
    s.start();
    _focus.requestFocus();
  }

  Future<void> _copy() async {
    final sel = _controller.selection;
    if (sel == null) return;
    await Clipboard.setData(ClipboardData(text: widget.session.terminal.buffer.getText(sel)));
    _controller.clearSelection();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) widget.session.terminal.paste(data!.text!);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          color: HmColors.bg,
          border: Border.all(color: HmColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true): _copy,
                  const SingleActivator(LogicalKeyboardKey.keyV, control: true, shift: true): _paste,
                },
                child: TerminalView(
                  s.terminal,
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  theme: _theme,
                  padding: const EdgeInsets.all(8),
                  textStyle: const TerminalStyle(fontFamily: HmText.mono, fontSize: 13),
                  readOnly: s.status != SessionStatus.open,
                  onSecondaryTapDown: (_, _) => _controller.selection == null ? _paste() : _copy(),
                ),
              ),
            ),
            if (s.status != SessionStatus.open)
              Positioned(
                right: 12,
                top: 12,
                child: s.status == SessionStatus.connecting
                    ? HmBadge(tr('connecting…', 'подключение…'), tone: HmTone.info)
                    : HmButton(tr('Reconnect', 'Переподключить'), icon: Icons.refresh, small: true, onPressed: _reconnect),
              ),
          ],
        ),
      ),
    );
  }
}

/// Keys a phone keyboard lacks (touch targets ≥ 36 px).
class _KeyBar extends StatefulWidget {
  const _KeyBar({required this.session});

  final Session session;

  @override
  State<_KeyBar> createState() => _KeyBarState();
}

class _KeyBarState extends State<_KeyBar> {
  bool _ctrl = false;

  void _key(TerminalKey k) => widget.session.terminal.keyInput(k, ctrl: _ctrl);

  @override
  Widget build(BuildContext context) {
    final t = widget.session.terminal;
    Widget b(String label, VoidCallback f, {bool active = false}) => Padding(
      padding: const EdgeInsets.only(right: Hm.gapXxs),
      child: HmButton(label, small: true, variant: active ? HmVariant.primary : HmVariant.neutral, onPressed: f),
    );
    return SizedBox(
      height: Hm.of(context).buttonSm,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          b('ESC', () => _key(TerminalKey.escape)),
          b('TAB', () => _key(TerminalKey.tab)),
          b('CTRL', () => setState(() => _ctrl = !_ctrl), active: _ctrl),
          b('^C', () => t.charInput(99, ctrl: true)),
          b('←', () => _key(TerminalKey.arrowLeft)),
          b('↑', () => _key(TerminalKey.arrowUp)),
          b('↓', () => _key(TerminalKey.arrowDown)),
          b('→', () => _key(TerminalKey.arrowRight)),
          b('|', () => t.textInput('|')),
          b('~', () => t.textInput('~')),
          b('/', () => t.textInput('/')),
        ],
      ),
    );
  }
}
