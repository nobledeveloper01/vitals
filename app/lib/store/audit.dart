// The signed audit export (ADR-0006 #30): every write and every open, as a
// CSV a supervisor can open anywhere, signed with the tablet's own Ed25519
// key so a changed line is a failed signature. The private key is made
// once and kept in the keychain; the public key is printed in the file and
// in Settings, and `scripts/verify-audit.py` checks a file with nothing but
// Python. The export reads; it writes no fact.
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vitals_domain/vitals_domain.dart';

import 'records.dart';

/// The tablet's signing key: a 32-byte seed in the keychain.
final class AuditKeys {
  AuditKeys({FlutterSecureStorage? storage, List<int>? seed})
      : _storage = storage ?? const FlutterSecureStorage(),
        _seed = seed;
  final FlutterSecureStorage _storage;
  static const _name = 'ng.vitals.audit-seed';
  List<int>? _seed;

  Future<SimpleKeyPair> keyPair() async {
    var seed = _seed;
    if (seed == null) {
      final stored = await _storage.read(key: _name);
      if (stored != null) {
        seed = stored.split(',').map(int.parse).toList();
      } else {
        final r = Random.secure();
        seed = List<int>.generate(32, (_) => r.nextInt(256));
        await _storage.write(key: _name, value: seed.join(','));
      }
      _seed = seed;
    }
    return Ed25519().newKeyPairFromSeed(seed);
  }

  Future<String> publicKeyHex() async {
    final pk = await (await keyPair()).extractPublicKey();
    return _hex(pk.bytes);
  }
}

abstract final class AuditExport {
  static const header = 'when_utc,event,kind,patient,author,device,facility';

  /// One line per fact — its write — and one per open, oldest first.
  static List<String> lines(Records records) {
    final rows = <(int, String)>[];
    for (final r in records.all.values) {
      final patient = _hex(r.patient).substring(0, 8);
      for (final f in r.all) {
        rows.add((
          f.stamp.wallMillis,
          [
            DateTime.fromMillisecondsSinceEpoch(f.stamp.wallMillis, isUtc: true)
                .toIso8601String(),
            'write',
            f.kind.name,
            patient,
            _csv(f.author),
            _csv(f.stamp.device),
            '',
          ].join(','),
        ));
      }
      for (final a in Access.of(r.current)) {
        rows.add((
          a.minutes * 60000,
          [
            DateTime.fromMillisecondsSinceEpoch(a.minutes * 60000, isUtc: true)
                .toIso8601String(),
            'open',
            'record',
            patient,
            _csv(a.who),
            _csv(a.device),
            _csv(a.facility),
          ].join(','),
        ));
      }
    }
    rows.sort((a, b) => a.$1.compareTo(b.$1));
    return [header, for (final r in rows) r.$2];
  }

  /// The file: the lines, then the public key and the signature over
  /// every byte above them, each on a line beginning `#`.
  static Future<List<int>> signed(Records records, AuditKeys keys) async {
    final body = utf8.encode('${lines(records).join('\n')}\n');
    final pair = await keys.keyPair();
    final sig = await Ed25519().sign(body, keyPair: pair);
    final pk = await pair.extractPublicKey();
    return [
      ...body,
      ...utf8.encode('# public-key ed25519 ${_hex(pk.bytes)}\n'),
      ...utf8.encode('# signature ed25519 ${_hex(sig.bytes)}\n'),
    ];
  }

  /// What the Python script does, in Dart, for the tests.
  static Future<bool> verify(List<int> file) async {
    final text = utf8.decode(file);
    final pk = RegExp(r'^# public-key ed25519 ([0-9a-f]{64})$', multiLine: true)
        .firstMatch(text);
    final sig =
        RegExp(r'^# signature ed25519 ([0-9a-f]{128})$', multiLine: true)
            .firstMatch(text);
    if (pk == null || sig == null) return false;
    final body = utf8.encode(text.substring(0, pk.start));
    return Ed25519().verify(body,
        signature: Signature(_bytes(sig[1]!),
            publicKey:
                SimplePublicKey(_bytes(pk[1]!), type: KeyPairType.ed25519)));
  }

  static String _csv(String s) =>
      s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
}

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
List<int> _bytes(String hex) => [
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16)
    ];
