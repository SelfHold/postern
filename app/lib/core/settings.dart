import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/endpoint.dart';
import 'i18n.dart';

/// App settings of this device (UI language), kept next to the core's
/// files. Nothing here is synced. The app starts in English; Russian only
/// when the user picks it in the header.
abstract final class AppSettings {
  static File? _file;

  static Future<void> load() async {
    try {
      final dir = Platform.isAndroid ? (await getApplicationSupportDirectory()).path : DesktopLauncher.configDir;
      _file = File(p.join(dir, 'app.json'));
      if (await _file!.exists()) {
        final j = jsonDecode(await _file!.readAsString()) as Map<String, dynamic>;
        lang.value = j['lang'] == 'ru' ? Lang.ru : Lang.en;
      }
      // No saved choice: stay on English. The system locale is never used.
    } catch (_) {}
  }

  static Future<void> setLanguage(Lang l) async {
    lang.value = l;
    try {
      await _file?.parent.create(recursive: true);
      await _file?.writeAsString(jsonEncode({'lang': l.name}));
    } catch (_) {}
  }
}
