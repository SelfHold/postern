import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/i18n.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/layout.dart';
import '../../core/theme/typography.dart';
import '../../data/core.dart';
import '../../data/rpc/gen/sshm.pb.dart' as pb;
import '../common/hm.dart';

/// Add or edit a host. Returns the saved host.
Future<Host?> editHost(BuildContext context, [Host? host]) => showHmModal<Host>(
  context,
  title: host == null ? tr('New host', 'Новый хост') : tr('Edit ${host.name}', 'Изменить ${host.name}'),
  size: HmModalSize.lg,
  body: (ctx) => _HostForm(host: host),
);

class _HostForm extends StatefulWidget {
  const _HostForm({this.host});

  final Host? host;

  @override
  State<_HostForm> createState() => _HostFormState();
}

class _HostFormState extends State<_HostForm> {
  late final Host _h = widget.host?.deepCopy() ?? (Host()..auth = Host_Auth.PASSWORD);
  late final _name = TextEditingController(text: _h.name);
  late final _group = TextEditingController(text: _h.group);
  late final _address = TextEditingController(text: _h.address);
  late final _port = TextEditingController(text: _h.port == 0 ? '' : '${_h.port}');
  late final _user = TextEditingController(text: _h.user);
  late final _password = TextEditingController(text: _h.password);
  late final _key = TextEditingController(text: _h.privateKey);
  late final _passphrase = TextEditingController(text: _h.passphrase);
  late final _startDir = TextEditingController(text: _h.startDir);
  late final _notes = TextEditingController(text: _h.notes);
  late Host_Auth _auth = _h.auth == Host_Auth.AUTH_UNSPECIFIED ? Host_Auth.PASSWORD : _h.auth;
  late String _keyId = _h.keyId;
  List<SafeKey>? _safeKeys;
  String? _safeKeysWhy;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    try {
      final r = await core.api.safeKeys(pb.Empty());
      if (!mounted) return;
      setState(() {
        _safeKeys = r.keys;
        _safeKeysWhy = r.unavailable.isEmpty ? null : r.unavailable;
      });
    } catch (e) {
      if (mounted) setState(() => _safeKeysWhy = errorText(e));
    }
  }

  Future<void> _save() async {
    final port = _port.text.trim().isEmpty ? 0 : int.tryParse(_port.text.trim());
    if (port == null || port < 0 || port > 65535) {
      setState(() => _error = tr('Port must be 1–65535', 'Порт должен быть 1–65535'));
      return;
    }
    final h = _h
      ..name = _name.text.trim()
      ..group = _group.text.trim()
      ..address = _address.text.trim()
      ..port = port
      ..user = _user.text.trim()
      ..auth = _auth
      ..password = _password.text
      ..privateKey = _key.text
      ..passphrase = _passphrase.text
      ..keyId = _keyId
      ..startDir = _startDir.text.trim()
      ..notes = _notes.text;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await core.api.saveHost(h);
      await core.refresh();
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hm = Hm.of(context);
    Widget row(List<Widget> cs) => hm.mobile
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final c in cs) Padding(padding: EdgeInsets.only(bottom: hm.gapSm), child: c)])
        : Padding(
            padding: EdgeInsets.only(bottom: hm.gapSm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, c) in cs.indexed) ...[if (i > 0) SizedBox(width: hm.gapSm), Expanded(child: c)],
              ],
            ),
          );
    final methods = <Host_Auth, String>{
      Host_Auth.PASSWORD: tr('Password', 'Пароль'),
      Host_Auth.SAFE_KEY: 'CloudSync',
      Host_Auth.KEY: tr('Own key', 'Свой ключ'),
      if (!Platform.isAndroid) Host_Auth.AGENT: tr('Agent', 'Агент'),
    };
    final shared = core.sync.sharedServers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        row([
          HmTextField(label: tr('Name', 'Название'), controller: _name, required: true, autofocus: widget.host == null, placeholder: 'web-1'),
          HmTextField(label: tr('Group', 'Группа'), controller: _group, placeholder: 'prod', hint: tr('"a/b" nests folders', '«a/b» — вложенные папки')),
        ]),
        row([
          HmTextField(label: tr('Address', 'Адрес'), controller: _address, required: true, identifier: true, placeholder: 'example.com'),
          HmTextField(
            label: tr('Port', 'Порт'),
            controller: _port,
            placeholder: '22',
            keyboard: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          HmTextField(label: tr('User', 'Пользователь'), controller: _user, required: true, identifier: true, placeholder: 'root'),
        ]),
        HmFormField(
          label: tr('Log in with', 'Вход'),
          child: HmSegmented<Host_Auth>(options: methods, value: _auth, onChanged: (v) => setState(() => _auth = v)),
        ),
        SizedBox(height: hm.gapSm),
        ...switch (_auth) {
          Host_Auth.PASSWORD => [HmTextField(label: tr('Password', 'Пароль'), controller: _password, password: true, onSubmitted: (_) => _save())],
          Host_Auth.KEY => [
            HmTextField(
              label: tr('Private key', 'Приватный ключ'),
              controller: _key,
              lines: 6,
              identifier: true,
              placeholder: '-----BEGIN OPENSSH PRIVATE KEY-----',
              hint: shared
                  ? tr('Kept on this device only. Put the key into the CloudSync safe to use it everywhere.',
                      'Хранится только на этом устройстве. Положите ключ в сейф CloudSync, чтобы он был везде.')
                  : null,
            ),
            SizedBox(height: hm.gapSm),
            HmTextField(label: tr('Passphrase', 'Пароль ключа'), controller: _passphrase, password: true),
          ],
          Host_Auth.SAFE_KEY => [_safeKeyPicker()],
          _ => [
            Text(tr('Keys of the running ssh-agent (SSH_AUTH_SOCK) are tried.', 'Пробуются ключи запущенного ssh-agent (SSH_AUTH_SOCK).'), style: HmText.small),
          ],
        },
        SizedBox(height: hm.gapSm),
        row([
          HmTextField(label: tr('Start folder', 'Начальная папка'), controller: _startDir, identifier: true, placeholder: '~'),
          HmTextField(label: tr('Notes', 'Заметки'), controller: _notes),
        ]),
        if (_error != null) ...[HmBanner(_error!, tone: HmTone.error), SizedBox(height: hm.gapSm)],
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            HmButton(tr('Cancel', 'Отмена'), variant: HmVariant.neutral, onPressed: () => Navigator.pop(context)),
            const SizedBox(width: Hm.gapXxs),
            HmButton(tr('Save', 'Сохранить'), variant: HmVariant.primary, loading: _saving, onPressed: _save),
          ],
        ),
      ],
    );
  }

  Widget _safeKeyPicker() {
    final keys = _safeKeys;
    if (keys == null && _safeKeysWhy == null) return const HmLoading();
    if (_safeKeysWhy != null || keys!.isEmpty) {
      return HmBanner(
        _safeKeysWhy ??
            tr('The CloudSync safe has no SSH keys yet. Add one there (kind "SSH key").', 'В сейфе CloudSync пока нет SSH-ключей. Добавьте ключ там (тип «SSH-ключ»).'),
        tone: HmTone.warning,
      );
    }
    final known = keys.any((k) => k.id == _keyId);
    return HmSelect<String>(
      label: tr('Key from the CloudSync safe', 'Ключ из сейфа CloudSync'),
      required: true,
      options: {for (final k in keys) k.id: k.title.isEmpty ? k.fingerprint : k.title},
      value: known ? _keyId : null,
      placeholder: _keyId.isNotEmpty && !known ? tr('the key is gone — pick another', 'ключа больше нет — выберите другой') : null,
      describe: (id) {
        final k = keys.firstWhere((k) => k.id == id);
        return '${k.keyType}  ${k.fingerprint}';
      },
      hint: tr('The private key is fetched from CloudSync for each connection and never stored here.',
          'Приватный ключ берётся из CloudSync при каждом подключении и здесь не хранится.'),
      onChanged: (v) => setState(() => _keyId = v),
    );
  }
}

/// "user@host:port" of a host.
String hostLine(Host h) => '${h.user}@${h.address}${h.port == 0 || h.port == 22 ? '' : ':${h.port}'}';

String authLabel(Host h) => switch (h.auth) {
  Host_Auth.KEY => tr('pasted key', 'свой ключ'),
  Host_Auth.AGENT => 'ssh-agent',
  Host_Auth.SAFE_KEY => tr('CloudSync key', 'ключ CloudSync'),
  _ => tr('password', 'пароль'),
};

/// Text style for a host's address in lists.
TextStyle get hostLineStyle => HmText.body.copyWith(color: HmColors.muted);
