import 'package:flutter/material.dart';

import 'app.dart';
import 'core/desktop/desktop_window.dart';
import 'core/settings.dart';
import 'data/core.dart';
import 'data/endpoint.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load();
  await DesktopWindow.instance.init();
  core = Core(CoreLauncher.forPlatform());
  core.connect();
  runApp(const PosternApp());
}
