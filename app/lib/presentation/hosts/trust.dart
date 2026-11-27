import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../data/core.dart';
import '../../data/rpc/gen/sshm.pb.dart' as pb;
import '../common/hm.dart';

/// Makes sure the server's key is trusted before connecting: a first
/// connection shows the fingerprint to accept; a changed key is a warning
/// that must be confirmed explicitly. The trusted key is part of the host,
/// so it is synced (and shared with other apps through CloudSync).
Future<bool> ensureTrusted(BuildContext context, Host h) async {
  final pb.HostKey k;
  try {
    k = await core.api.probeHostKey(pb.HostRef(id: h.id));
  } catch (e) {
    Toasts.error(tr('Cannot reach ${h.name}', 'Нет связи с ${h.name}'), errorText(e));
    return false;
  }
  if (k.status == HostKey_Status.KNOWN) return true;
  if (!context.mounted) return false;
  final changed = k.status == HostKey_Status.CHANGED;
  final ok = await showHmModal<bool>(
    context,
    title: changed ? tr('The server key has CHANGED', 'Ключ сервера ИЗМЕНИЛСЯ') : tr('New server', 'Новый сервер'),
    size: HmModalSize.md,
    body: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (changed)
          HmBanner(
            tr(
              '${h.address} shows another key than the one trusted before. It may be a reinstalled server — or someone in between. '
                  'Trust the new key only if you know why it changed.',
              '${h.address} показывает не тот ключ, которому вы доверяли. Это может быть переустановленный сервер — или кто-то посередине. '
                  'Доверяйте новому ключу, только если знаете причину.',
            ),
            tone: HmTone.error,
          )
        else
          Text(
            tr('This is the first connection to ${h.address}. Compare the fingerprint with the server\'s before trusting it.',
                'Это первое подключение к ${h.address}. Сверьте отпечаток с сервером, прежде чем доверять ему.'),
            style: HmText.body.copyWith(color: HmColors.muted),
          ),
        const SizedBox(height: 16),
        HmField(tr('Key type', 'Тип ключа'), Text(k.type)),
        HmField(tr('Fingerprint', 'Отпечаток'), SelectableText(k.fingerprint, style: HmText.bodyStrong.copyWith(color: HmColors.accent))),
      ],
    ),
    actions: (ctx) => [
      HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, onPressed: () => Navigator.pop(ctx, false)),
      HmButton(
        changed ? tr('Trust the new key', 'Доверять новому ключу') : tr('Trust and connect', 'Доверять и подключиться'),
        variant: changed ? HmVariant.red : HmVariant.primary,
        onPressed: () => Navigator.pop(ctx, true),
      ),
    ],
  );
  if (ok != true) return false;
  try {
    await core.api.trustHostKey(pb.TrustRequest(id: h.id, key: k.key, replace: changed));
    await core.refresh();
    return true;
  } catch (e) {
    Toasts.error(tr('Could not save the key', 'Не удалось сохранить ключ'), errorText(e));
    return false;
  }
}
