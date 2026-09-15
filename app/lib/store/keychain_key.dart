// The log's key: 32 bytes made once from the platform's random source and
// kept in the keychain (iOS) or the keystore-backed encrypted preferences
// (Android). It never lives in the log's file, so the file alone is noise.
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'fact_log.dart';

final class KeychainKey implements KeySource {
  KeychainKey({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _name = 'ng.vitals.log-key';
  List<int>? _cached;

  @override
  Future<List<int>> key() async {
    if (_cached case final k?) return k;
    final stored = await _storage.read(key: _name);
    if (stored != null) {
      return _cached = stored.split(',').map(int.parse).toList();
    }
    final r = Random.secure();
    final k = List<int>.generate(32, (_) => r.nextInt(256));
    await _storage.write(key: _name, value: k.join(','));
    return _cached = k;
  }
}
