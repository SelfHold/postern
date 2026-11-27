import 'dart:convert';
import 'dart:ffi';

/// The desktop core inside this process (Go, `desktopbind`), linked into the
/// executable (app/linux/CMakeLists.txt).
class NativeCore {
  NativeCore._(DynamicLibrary lib)
    : _start = lib.lookupFunction<Pointer<Uint8> Function(), Pointer<Uint8> Function()>('SshmStart'),
      _stop = lib.lookupFunction<Void Function(), void Function()>('SshmStop'),
      _free = lib.lookupFunction<Void Function(Pointer<Uint8>), void Function(Pointer<Uint8>)>('SshmFree');

  static NativeCore? _instance;

  static NativeCore get instance => _instance ??= NativeCore._(DynamicLibrary.process());

  final Pointer<Uint8> Function() _start;
  final void Function() _stop;
  final void Function(Pointer<Uint8>) _free;
  bool _started = false;

  /// Starts the core (or returns the running one): {"address", "token"},
  /// with "external" when another instance of the app runs it, or {"error"}.
  Map<String, dynamic> start() {
    final p = _start();
    try {
      var n = 0;
      while (p[n] != 0) {
        n++;
      }
      final r = jsonDecode(utf8.decode(p.asTypedList(n))) as Map<String, dynamic>;
      if (r['error'] == null && r['external'] != true) _started = true;
      return r;
    } finally {
      _free(p);
    }
  }

  /// Closes the SSH connections and stops the core (before the app quits).
  static void stop() {
    final c = _instance;
    if (c == null || !c._started) return;
    c._started = false;
    c._stop();
  }
}
