import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grpc/grpc.dart';
import 'package:intl/intl.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/core.dart';
import '../../data/rpc/gen/postern.pb.dart' as pb;
import '../common/hm.dart';
import '../hosts/trust.dart';
import 'files_model.dart';

export 'files_model.dart' show files;

/// Two-panel file manager (in the spirit of Midnight Commander): each panel
/// shows this device or a host; F5 copies and F6 moves the selection into
/// the other panel.
class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    files.start();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  // --- operations ---------------------------------------------------------

  Future<void> _copy(bool move) async {
    final paths = files.a.targets();
    if (paths.isEmpty) return;
    final what = paths.length == 1 ? paths.first.split('/').last : tr('${paths.length} items', '${paths.length} объектов');
    final ok = await confirm(
      context,
      title: move ? tr('Move $what?', 'Перенести $what?') : tr('Copy $what?', 'Копировать $what?'),
      message: '${files.a.title()} → ${files.other.title()}\n${files.other.path}',
      action: move ? tr('Move', 'Перенести') : tr('Copy', 'Копировать'),
    );
    if (!ok) return;
    await _runCopy(move, false);
  }

  Future<void> _runCopy(bool move, bool overwrite) async {
    try {
      await files.copy(move: move, overwrite: overwrite);
      Toasts.success(move ? tr('Moved', 'Перенесено') : tr('Copied', 'Скопировано'));
    } on GrpcError catch (e) {
      if (e.code == StatusCode.cancelled) return Toasts.show(tr('Cancelled', 'Отменено'));
      if (e.code == StatusCode.alreadyExists && mounted) {
        final again = await confirm(
          context,
          title: tr('Replace existing?', 'Заменить существующее?'),
          message: errorText(e),
          action: tr('Replace', 'Заменить'),
          destructive: true,
        );
        if (again) await _runCopy(move, true);
        return;
      }
      Toasts.error(tr('Copy failed', 'Ошибка копирования'), errorText(e));
    } catch (e) {
      Toasts.error(tr('Copy failed', 'Ошибка копирования'), errorText(e));
    }
  }

  Future<String?> _ask(String title, String label, {String initial = '', required String action}) {
    final c = TextEditingController(text: initial);
    return showHmModal<String>(
      context,
      title: title,
      size: HmModalSize.sm,
      body: (ctx) => HmTextField(label: label, controller: c, autofocus: true, identifier: true, onSubmitted: (v) => Navigator.pop(ctx, v.trim())),
      actions: (ctx) => [
        HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, onPressed: () => Navigator.pop(ctx)),
        HmButton(action, variant: HmVariant.primary, onPressed: () => Navigator.pop(ctx, c.text.trim())),
      ],
    );
  }

  Future<void> _mkdir() async {
    final pnl = files.a;
    final name = await _ask(tr('New folder', 'Новая папка'), tr('Name', 'Имя'), action: tr('Create', 'Создать'));
    if (name == null || name.isEmpty) return;
    try {
      await core.api.makeDir(pb.PathRequest(side: pnl.side, path: pnl.join(name)));
      await pnl.load(null, name);
    } catch (e) {
      Toasts.error(tr('Could not create', 'Не удалось создать'), errorText(e));
    }
  }

  Future<void> _rename() async {
    final pnl = files.a;
    final e = pnl.current;
    if (e == null || identical(e, parentEntry)) return;
    final name = await _ask(tr('Rename', 'Переименовать'), tr('New name', 'Новое имя'), initial: e.name, action: tr('Rename', 'Переименовать'));
    if (name == null || name.isEmpty || name == e.name) return;
    try {
      await core.api.rename(pb.RenameRequest(side: pnl.side, from: pnl.join(e.name), to: pnl.join(name)));
      await pnl.load(null, name);
    } catch (err) {
      Toasts.error(tr('Could not rename', 'Не удалось переименовать'), errorText(err));
    }
  }

  Future<void> _delete() async {
    final pnl = files.a;
    final paths = pnl.targets();
    if (paths.isEmpty) return;
    final ok = await confirm(
      context,
      title: tr('Delete ${paths.length == 1 ? paths.first.split('/').last : '${paths.length} items'}?',
          'Удалить ${paths.length == 1 ? paths.first.split('/').last : '${paths.length} объектов'}?'),
      message: tr('Folders are deleted with everything in them. This cannot be undone.', 'Папки удаляются со всем содержимым. Отменить нельзя.'),
      action: tr('Delete', 'Удалить'),
      destructive: true,
    );
    if (!ok) return;
    try {
      await core.api.remove(pb.PathsRequest(side: pnl.side, paths: paths));
      pnl.selected.clear();
      await pnl.load();
    } catch (e) {
      Toasts.error(tr('Could not delete', 'Не удалось удалить'), errorText(e));
    }
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final pnl = files.a;
    final k = e.logicalKey;
    void act(VoidCallback f) => f();
    switch (k) {
      case LogicalKeyboardKey.arrowDown:
        act(() => pnl.move(1));
      case LogicalKeyboardKey.arrowUp:
        act(() => pnl.move(-1));
      case LogicalKeyboardKey.pageDown:
        act(() => pnl.move(20));
      case LogicalKeyboardKey.pageUp:
        act(() => pnl.move(-20));
      case LogicalKeyboardKey.home:
        act(() => pnl.setCursor(0));
      case LogicalKeyboardKey.end:
        act(() => pnl.setCursor(pnl.entries.length - 1));
      case LogicalKeyboardKey.enter:
        if (pnl.current != null) pnl.open(pnl.current!);
      case LogicalKeyboardKey.backspace:
        pnl.up();
      case LogicalKeyboardKey.tab:
        files.focus(1 - files.active);
      case LogicalKeyboardKey.insert:
      case LogicalKeyboardKey.space:
        if (pnl.current != null) {
          pnl.toggle(pnl.current!);
          pnl.move(1);
        }
      case LogicalKeyboardKey.f2:
        _rename();
      case LogicalKeyboardKey.f5:
        _copy(false);
      case LogicalKeyboardKey.f6:
        _copy(true);
      case LogicalKeyboardKey.f7:
        _mkdir();
      case LogicalKeyboardKey.f8:
      case LogicalKeyboardKey.delete:
        _delete();
      default:
        if (k == LogicalKeyboardKey.keyR && HardwareKeyboard.instance.isControlPressed) {
          pnl.load();
        } else {
          return KeyEventResult.ignored;
        }
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([files, core]),
      builder: (context, _) {
        final t = files.transfer;
        final panels = hm.mobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HmSegmented<int>(
                    options: {0: files.left.title(), 1: files.right.title()},
                    value: files.active,
                    onChanged: files.focus,
                  ),
                  const SizedBox(height: Hm.gapXxs),
                  Expanded(child: _Panel(index: files.active, onFocus: _focus.requestFocus)),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _Panel(index: 0, onFocus: _focus.requestFocus)),
                  SizedBox(width: hm.gapSm),
                  Expanded(child: _Panel(index: 1, onFocus: _focus.requestFocus)),
                ],
              );
        return Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: Padding(
            padding: EdgeInsets.fromLTRB(hm.pageX, hm.mobile ? 8 : 20, hm.pageX, hm.mobile ? 8 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: panels),
                if (t != null) ...[const SizedBox(height: Hm.gapXxs), _TransferBar(t: t)],
                const SizedBox(height: Hm.gapXxs),
                _ActionBar(
                  busy: t != null,
                  mobile: hm.mobile,
                  onCopy: () => _copy(false),
                  onMove: () => _copy(true),
                  onMkdir: _mkdir,
                  onRename: _rename,
                  onDelete: _delete,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.index, required this.onFocus});

  final int index;
  final VoidCallback onFocus;

  PanelModel get pnl => index == 0 ? files.left : files.right;

  Future<void> _pickSide(BuildContext context) async {
    final options = <String, String>{'': tr('This device', 'Это устройство'), for (final h in core.hosts) h.id: h.name};
    final v = await pickOption<String>(context, options: options, value: pnl.side, title: tr('Show in panel', 'Показать в панели'));
    if (v == null) return;
    if (v.isNotEmpty) {
      final h = core.host(v);
      if (h == null || !context.mounted || !await ensureTrusted(context, h)) return;
    }
    pnl.setSide(v);
  }

  @override
  Widget build(BuildContext context) {
    final active = files.active == index;
    final p = pnl;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) {
        files.focus(index);
        onFocus();
      },
      child: Container(
        decoration: BoxDecoration(
          color: HmColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? HmColors.tint(HmColors.accent, HmColors.ring) : HmColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Side and path.
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: HmColors.border))),
              child: Row(
                children: [
                  // Builder: the dropdown anchors to the button, not to the whole panel.
                  Builder(
                    builder: (btn) => HmButton(p.title(), small: true, icon: p.remote ? Icons.dns_outlined : Icons.computer, variant: active ? HmVariant.cyan : HmVariant.neutral, onPressed: () => _pickSide(btn)),
                  ),
                  const SizedBox(width: Hm.gapXxs),
                  Expanded(
                    child: Text(p.path, style: HmText.small, overflow: TextOverflow.ellipsis),
                  ),
                  HmIconButton(icon: Icons.arrow_upward, label: tr('Up (Backspace)', 'Вверх (Backspace)'), onPressed: p.atRoot ? null : p.up),
                  HmIconButton(icon: Icons.refresh, label: tr('Refresh (Ctrl+R)', 'Обновить (Ctrl+R)'), onPressed: () => p.load()),
                ],
              ),
            ),
            // Column headers.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: HmColors.border))),
              child: Row(
                children: [
                  Expanded(child: Text(tr('NAME', 'ИМЯ'), style: HmText.th)),
                  SizedBox(width: 80, child: Text(tr('SIZE', 'РАЗМЕР'), style: HmText.th, textAlign: TextAlign.right)),
                  if (!Hm.of(context).mobile) SizedBox(width: 130, child: Text(tr('MODIFIED', 'ИЗМЕНЁН'), style: HmText.th, textAlign: TextAlign.right)),
                ],
              ),
            ),
            Expanded(child: _list(context, p, active)),
            // Summary.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: HmColors.border))),
              child: Text(
                p.selected.isEmpty
                    ? tr('${p.entries.where((e) => !identical(e, parentEntry)).length} items', '${p.entries.where((e) => !identical(e, parentEntry)).length} объектов')
                    : tr('${p.selected.length} selected · ${fmtSize(p.selectedSize)}', 'выбрано ${p.selected.length} · ${fmtSize(p.selectedSize)}'),
                style: HmText.footer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, PanelModel p, bool active) {
    if (p.loading && p.entries.isEmpty) return const HmLoading();
    if (p.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: HmEmptyState(
            p.error!,
            icon: Icons.error_outline,
            action: HmButton(
              p.hostKeyProblem ? tr('Check server key', 'Проверить ключ сервера') : tr('Retry', 'Повторить'),
              onPressed: () async {
                final h = core.host(p.side);
                if (p.hostKeyProblem && (h == null || !await ensureTrusted(context, h))) return;
                p.load();
              },
            ),
          ),
        ),
      );
    }
    final mobile = Hm.of(context).mobile;
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    return ListView.builder(
      itemCount: p.entries.length,
      itemExtent: mobile ? 44 : 26,
      itemBuilder: (context, i) {
        final e = p.entries[i];
        final cur = active && i == p.cursor;
        final sel = p.selected.contains(e.name);
        final color = sel ? HmColors.warning : (e.dir ? HmColors.accent : HmColors.text);
        return GestureDetector(
          onTap: () {
            files.focus(index);
            onFocus();
            if (mobile && i == p.cursor) {
              p.open(e);
            } else {
              p.setCursor(i);
            }
          },
          onDoubleTap: () => p.open(e),
          onLongPress: () => p.toggle(e),
          onSecondaryTap: () => p.toggle(e),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: cur ? HmColors.tint(HmColors.accent, 0.15) : Colors.transparent,
            child: Row(
              children: [
                Icon(
                  identical(e, parentEntry) ? Icons.subdirectory_arrow_left : (e.dir ? Icons.folder_outlined : (e.link ? Icons.link : Icons.description_outlined)),
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.name, style: HmText.body.copyWith(color: color, fontWeight: sel ? FontWeight.w600 : null), overflow: TextOverflow.ellipsis),
                ),
                SizedBox(
                  width: 80,
                  child: Text(e.dir ? (identical(e, parentEntry) ? '' : 'DIR') : fmtSize(e.size.toInt()), style: HmText.small, textAlign: TextAlign.right),
                ),
                if (!mobile)
                  SizedBox(
                    width: 130,
                    child: Text(
                      e.modifiedMs == 0 ? '' : fmt.format(DateTime.fromMillisecondsSinceEpoch(e.modifiedMs.toInt())),
                      style: HmText.small,
                      textAlign: TextAlign.right,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TransferBar extends StatelessWidget {
  const _TransferBar({required this.t});

  final TransferState t;

  @override
  Widget build(BuildContext context) {
    final p = t.progress;
    final frac = p.totalBytes == 0 ? 0.0 : p.doneBytes.toInt() / p.totalBytes.toInt();
    return HmCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${t.label}: ${p.doneFiles}/${p.totalFiles} · ${fmtSize(p.doneBytes.toInt())} / ${fmtSize(p.totalBytes.toInt())}',
                  style: HmText.small,
                ),
                const SizedBox(height: 6),
                HmProgress(value: frac),
                if (p.current.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(p.current, style: HmText.footer, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          HmButton(tr('Cancel', 'Отмена'), small: true, variant: HmVariant.red, onPressed: files.cancelTransfer),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.busy,
    required this.mobile,
    required this.onCopy,
    required this.onMove,
    required this.onMkdir,
    required this.onRename,
    required this.onDelete,
  });

  final bool busy;
  final bool mobile;
  final VoidCallback onCopy, onMove, onMkdir, onRename, onDelete;

  @override
  Widget build(BuildContext context) {
    String k(String key, String label) => mobile ? label : '$key $label';
    final buttons = [
      HmButton(k('F2', tr('Rename', 'Имя')), small: true, variant: HmVariant.neutral, onPressed: busy ? null : onRename),
      HmButton(k('F5', tr('Copy', 'Копировать')), small: true, icon: Icons.content_copy, onPressed: busy ? null : onCopy),
      HmButton(k('F6', tr('Move', 'Перенести')), small: true, variant: HmVariant.purple, icon: Icons.drive_file_move_outline, onPressed: busy ? null : onMove),
      HmButton(k('F7', tr('Folder', 'Папка')), small: true, variant: HmVariant.green, icon: Icons.create_new_folder_outlined, onPressed: busy ? null : onMkdir),
      HmButton(k('F8', tr('Delete', 'Удалить')), small: true, variant: HmVariant.red, icon: Icons.delete_outline, onPressed: busy ? null : onDelete),
    ];
    return SizedBox(
      height: Hm.of(context).buttonSm,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final b in buttons) Padding(padding: const EdgeInsets.only(right: Hm.gapXxs), child: b),
          if (!mobile)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Center(
                child: Text(
                  tr('Tab panel · Ins select · Enter open · Backspace up', 'Tab панель · Ins выбор · Enter открыть · Backspace вверх'),
                  style: HmText.footer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
