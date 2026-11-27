import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/core.dart';
import '../../data/rpc/gen/sshm.pb.dart' as pb;
import '../../data/sessions.dart';
import '../common/hm.dart';
import '../files/files_screen.dart';
import '../shell/app_shell.dart';
import 'host_editor.dart';
import 'trust.dart';

/// Opens a terminal to [h] (after the host key check).
Future<void> openTerminal(BuildContext context, Host h) async {
  if (!await ensureTrusted(context, h)) return;
  sessions.open(core.host(h.id) ?? h);
  if (context.mounted) AppShell.go(context, Section.terminal);
}

/// Shows [h] in the right panel of the file manager.
Future<void> openFiles(BuildContext context, Host h) async {
  if (!await ensureTrusted(context, h)) return;
  files.showHost(h.id);
  if (context.mounted) AppShell.go(context, Section.files);
}

class HostsScreen extends StatefulWidget {
  const HostsScreen({super.key});

  @override
  State<HostsScreen> createState() => _HostsScreenState();
}

class _HostsScreenState extends State<HostsScreen> {
  final _q = TextEditingController();

  Future<void> _delete(Host h) async {
    final shared = core.sync.sharedServers;
    final ok = await confirm(
      context,
      title: tr('Delete ${h.name}?', 'Удалить ${h.name}?'),
      message: shared
          ? tr('The server is removed from CloudSync\'s shared list: your other devices and DB Manager lose it too.',
              'Сервер удалится из общего списка CloudSync: он пропадёт и на других устройствах, и в DB Manager.')
          : tr('The host is removed on every synced device.', 'Хост удалится на всех синхронизированных устройствах.'),
      action: tr('Delete', 'Удалить'),
      destructive: true,
    );
    if (!ok) return;
    try {
      await core.api.deleteHost(pb.HostRef(id: h.id));
      await core.refresh();
    } catch (e) {
      Toasts.error(tr('Could not delete', 'Не удалось удалить'), errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([core, _q]),
      builder: (context, _) {
        final q = _q.text.trim().toLowerCase();
        final items = core.hosts
            .where((h) => q.isEmpty || '${h.name} ${h.group} ${h.address} ${h.user} ${h.notes}'.toLowerCase().contains(q))
            .toList();
        return HmPage(
          onRefresh: core.refresh,
          children: [
            if (!hm.mobile) HmPageTitle(tr('Hosts', 'Хосты')),
            if (core.sync.phase == SyncState_Phase.OFF && core.sync.available)
              HmBanner(
                tr('CloudSync is on this device: switch sync on to have these hosts on every device.',
                    'На устройстве есть CloudSync: включите синхронизацию, чтобы хосты были на всех устройствах.'),
                action: HmButton(tr('Set up', 'Настроить'), small: true, onPressed: () => AppShell.go(context, Section.sync)),
              ),
            HmTable<Host>(
              items: items,
              search: HmSearchField(controller: _q, placeholder: tr('Search hosts', 'Поиск хостов')),
              controls: [HmButton(tr('Add host', 'Добавить хост'), icon: Icons.add, variant: HmVariant.primary, onPressed: () => editHost(context))],
              onRefresh: core.refresh,
              emptyText: core.hosts.isEmpty ? tr('No hosts yet', 'Хостов пока нет') : null,
              emptyIcon: Icons.dns_outlined,
              emptyAction: core.hosts.isEmpty ? HmButton(tr('Add host', 'Добавить хост'), icon: Icons.add, onPressed: () => editHost(context)) : null,
              onTap: (h) => openTerminal(context, h),
              columns: [
                HmColumn(label: tr('Name', 'Название'), flex: 2, sortKey: (h) => h.name.toLowerCase(), cell: (h) => Text(h.name, style: HmText.bodyStrong)),
                HmColumn(label: tr('Group', 'Группа'), sortKey: (h) => h.group.toLowerCase(), cardIf: (h) => h.group.isNotEmpty, cell: (h) => h.group.isEmpty ? const SizedBox() : Align(alignment: Alignment.centerLeft, child: HmBadge(h.group))),
                HmColumn(label: tr('Address', 'Адрес'), flex: 3, sortKey: (h) => h.address, cell: (h) => Text(hostLine(h), style: hostLineStyle, overflow: TextOverflow.ellipsis)),
                HmColumn(label: tr('Login', 'Вход'), sortKey: (h) => h.auth.value, cell: (h) => Text(authLabel(h), style: HmText.small)),
                HmColumn(
                  label: tr('Server key', 'Ключ сервера'),
                  mobile: false,
                  cell: (h) => Align(
                    alignment: Alignment.centerLeft,
                    child: h.hostKeys.isEmpty ? HmBadge(tr('not checked', 'не проверен'), tone: HmTone.warning) : HmBadge(tr('trusted', 'доверен'), tone: HmTone.ok),
                  ),
                ),
              ],
              actions: (h) => [
                HmActionButton(icon: Icons.terminal, label: tr('Terminal', 'Терминал'), kind: HmAction.success, onPressed: () => openTerminal(context, h)),
                HmActionButton(icon: Icons.folder_copy_outlined, label: tr('Files', 'Файлы'), kind: HmAction.neutral, onPressed: () => openFiles(context, h)),
                HmActionButton(icon: Icons.edit_outlined, label: tr('Edit', 'Изменить'), onPressed: () => editHost(context, h)),
                HmActionButton(icon: Icons.delete_outline, label: tr('Delete', 'Удалить'), kind: HmAction.delete, onPressed: () => _delete(h)),
              ],
            ),
          ],
        );
      },
    );
  }
}
