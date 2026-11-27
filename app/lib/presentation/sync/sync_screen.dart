import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/core.dart';
import '../../data/rpc/gen/postern.pb.dart' as pb;
import '../common/hm.dart';

/// One word for the sync state (footer, phone header).
String syncLabel(SyncState s) => switch (s.phase) {
  SyncState_Phase.OFF => tr('sync off', 'синхр. выкл'),
  SyncState_Phase.NOT_RUNNING => tr('Shard not running', 'Shard не запущен'),
  SyncState_Phase.NO_VAULT => tr('Shard not set up', 'Shard не настроен'),
  SyncState_Phase.LOCKED => tr('Shard locked', 'Shard заблокирован'),
  SyncState_Phase.PAIRING => tr('waiting for Shard', 'ждём Shard'),
  SyncState_Phase.OFFLINE => tr('sync offline', 'синхр. офлайн'),
  SyncState_Phase.SYNCED => s.pending ? tr('syncing…', 'синхронизация…') : tr('synced', 'синхронизировано'),
  SyncState_Phase.ERROR => tr('sync error', 'ошибка синхр.'),
  _ => tr('sync off', 'синхр. выкл'),
};

/// Shard: switch sync on (pairing), what is shared, errors.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _busy = false;

  Future<void> _run(Future<pb.SyncState> Function() call) async {
    setState(() => _busy = true);
    try {
      core.setSync(await call());
    } catch (e) {
      Toasts.error(tr('Shard', 'Shard'), errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    final ok = await confirm(
      context,
      title: tr('Switch sync off?', 'Выключить синхронизацию?'),
      message: tr(
        'The hosts stay on this device. Shard keeps its copy for your other devices.',
        'Хосты останутся на этом устройстве. Shard сохранит копию для других устройств.',
      ),
      action: tr('Switch off', 'Выключить'),
      destructive: true,
    );
    if (ok) await _run(() => core.api.disableSync(pb.Empty()));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: core,
    builder: (context, _) {
      final s = core.sync;
      final hm = Hm.of(context);
      return HmPage(
        onRefresh: () => _run(() => core.api.syncNow(pb.Empty())),
        children: [
          if (!hm.mobile) HmPageTitle('Shard'),
          HmStatCards(
            children: [
              HmStatCard(label: tr('State', 'Состояние'), value: syncLabel(s), accent: s.phase == SyncState_Phase.SYNCED ? HmAccent.ok : HmAccent.paused),
              HmStatCard(label: tr('Hosts', 'Хосты'), value: '${core.hosts.length}', accent: HmAccent.total),
              HmStatCard(
                label: tr('Last sync', 'Последняя синхр.'),
                value: s.lastSyncMs == 0 ? '—' : DateFormat.Hms(currentLocale.languageCode).format(DateTime.fromMillisecondsSinceEpoch(s.lastSyncMs.toInt())),
                accent: HmAccent.active,
              ),
            ],
          ),
          if (s.phase == SyncState_Phase.PAIRING && s.pairingCode.isNotEmpty) _PairingCard(code: s.pairingCode),
          if (s.error.isNotEmpty) HmBanner(s.error, tone: HmTone.error),
          HmSectionTitle(tr('Sync', 'Синхронизация')),
          HmCard(
            padding: EdgeInsets.all(hm.mobile ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr(
                    'Shard keeps your hosts encrypted in every storage of your vault and gives every device the same list. '
                        'The app works without it; sync is optional.',
                    'Shard хранит хосты зашифрованными во всех хранилищах вашего хранилища и даёт всем устройствам один список. '
                        'Приложение работает и без него, синхронизация необязательна.',
                  ),
                  style: HmText.body.copyWith(color: HmColors.muted),
                ),
                SizedBox(height: hm.gapSm),
                HmField(tr('Shard on this device', 'Shard на этом устройстве'), Text(s.available ? tr('found', 'найден') : tr('not found', 'не найден'))),
                HmField(
                  tr('Where hosts live', 'Где хранятся хосты'),
                  Text(
                    !s.enabled
                        ? tr('this device only', 'только на этом устройстве')
                        : s.sharedServers
                        ? tr('Shard shared server list (also seen by Cellar)', 'общий список серверов Shard (его видит и Cellar)')
                        : tr('a record of this app in Shard', 'запись этого приложения в Shard'),
                  ),
                ),
                HmField(
                  tr('SSH keys of the Shard safe', 'SSH-ключи из сейфа Shard'),
                  Text(s.safeKeys ? tr('available', 'доступны') : tr('not shared', 'не открыты')),
                ),
                if (s.pending) HmField(tr('Local changes', 'Локальные изменения'), Text(tr('waiting to upload', 'ждут отправки'))),
                SizedBox(height: hm.gapSm),
                Wrap(
                  spacing: Hm.gapXxs,
                  runSpacing: Hm.gapXxs,
                  children: [
                    if (!s.enabled && s.phase != SyncState_Phase.PAIRING)
                      HmButton(
                        tr('Sync via Shard', 'Синхронизировать через Shard'),
                        variant: HmVariant.primary,
                        icon: Icons.cloud_sync_outlined,
                        loading: _busy,
                        onPressed: () => _run(() => core.api.enableSync(pb.Empty())),
                      ),
                    if (s.enabled) ...[
                      HmButton(tr('Sync now', 'Синхронизировать'), icon: Icons.sync, loading: _busy, onPressed: () => _run(() => core.api.syncNow(pb.Empty()))),
                      if (!s.sharedServers || !s.safeKeys)
                        HmButton(
                          tr('Ask for servers and keys', 'Запросить серверы и ключи'),
                          variant: HmVariant.purple,
                          icon: Icons.key_outlined,
                          onPressed: _busy ? null : () => _run(() => core.api.requestAccess(pb.Empty())),
                        ),
                      HmButton(tr('Switch off', 'Выключить'), variant: HmVariant.red, onPressed: _busy ? null : _disable),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _PairingCard extends StatelessWidget {
  const _PairingCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) => HmCard(
    accent: HmAccent.active,
    child: Row(
      children: [
        const HmLoading(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('Confirm in Shard', 'Подтвердите в Shard'), style: HmText.modalTitle),
              const SizedBox(height: 4),
              Text(
                tr('Shard shows the same code. Allow the request only if the codes match.', 'Shard покажет такой же код. Разрешите запрос, только если коды совпадают.'),
                style: HmText.small,
              ),
            ],
          ),
        ),
        Text(code, style: HmText.statValue.copyWith(color: HmColors.accent)),
      ],
    ),
  );
}
