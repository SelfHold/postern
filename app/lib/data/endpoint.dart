import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'native_core.dart';

/// Where the core listens and the token it wants.
class Endpoint {
  const Endpoint({required this.address, this.port = 0, required this.token});

  final InternetAddress address;
  final int port;
  final String token;
}

/// Finds or starts the core for this platform.
abstract class CoreLauncher {
  Future<Endpoint> endpoint({bool start = true});

  static CoreLauncher forPlatform() => Platform.isAndroid ? AndroidLauncher() : DesktopLauncher();
}

/// Android: the core runs inside the app (gomobile AAR, mobilebind) in a
/// foreground service; Kotlin starts it and hands over socket and token.
class AndroidLauncher implements CoreLauncher {
  static const _ch = MethodChannel('dev.sshmanager/core');

  @override
  Future<Endpoint> endpoint({bool start = true}) async {
    final r = await _ch.invokeMapMethod<String, String>('start');
    if (r == null) throw StateError('core did not start');
    return Endpoint(
      address: InternetAddress(r['socket']!, type: InternetAddressType.unix),
      token: r['token']!,
    );
  }
}

/// Desktop: the core runs inside the app ([NativeCore]) and listens on a
/// private socket. When another instance of the app already runs it, this
/// one connects to that core (endpoint.json in the config dir); when that
/// instance quits, the next reconnect starts the core here.
class DesktopLauncher implements CoreLauncher {
  static String get configDir {
    final xdg = Platform.environment['XDG_CONFIG_HOME'];
    final home = Platform.environment['HOME'] ?? '.';
    return p.join(xdg != null && xdg.isNotEmpty ? xdg : p.join(home, '.config'), 'sshmanager');
  }

  @override
  Future<Endpoint> endpoint({bool start = true}) async {
    final r = NativeCore.instance.start();
    final err = r['error'];
    if (err != null) throw SocketException('the core did not start: $err');
    final addr = r['address'] as String;
    if (!addr.startsWith('unix://')) throw SocketException('unexpected core address $addr');
    return Endpoint(
      address: InternetAddress(addr.substring('unix://'.length), type: InternetAddressType.unix),
      token: r['token'] as String,
    );
  }
}
