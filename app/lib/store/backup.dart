// Backup (ADR-0006 #29): every fact into one file under a second key the
// nurse chooses at backup time — a passphrase stretched into a key — so a
// USB stick left in a drawer is noise. Restore decrypts, decodes every fact,
// unions what decodes, and says what did not.
import 'dart:io';

import 'package:cryptography/cryptography.dart';

import 'fact_log.dart';
import 'records.dart';

abstract final class Backup {
  static const _magic = [0x56, 0x49, 0x54, 0x42]; // "VITB"
  static const _version = 1;

  /// A key from a passphrase: Argon2id would be the choice with a native
  /// binding; here PBKDF2-HMAC-SHA256 at 200k rounds, salted, which a phone
  /// does in under a second and a dictionary does not.
  static Future<SecretKey> _key(String passphrase, List<int> salt) =>
      Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 200_000, bits: 256)
          .deriveKeyFromPassword(password: passphrase, nonce: salt);

  static Future<void> write(Records records, File to,
      {required String passphrase, required List<int> salt}) async {
    final log = FactLog(File('${to.path}.tmp'),
        MemoryKey(await (await _key(passphrase, salt)).extractBytes()));
    if (await log.file.exists()) await log.file.delete();
    await log.append(records.all.values.expand((r) => r.all));
    final body = await log.file.readAsBytes();
    await log.file.delete();
    await to.writeAsBytes([..._magic, _version, ...salt, ...body]);
  }

  /// What came back: kept, and refused (frames that did not decrypt or decode).
  static Future<({int kept, int refused})> restore(Records records, File from,
      {required String passphrase}) async {
    final bytes = await from.readAsBytes();
    if (bytes.length < 21 ||
        bytes.sublist(0, 4).join() != _magic.join() ||
        bytes[4] != _version) {
      return (kept: 0, refused: 1);
    }
    final salt = bytes.sublist(5, 21);
    final tmp = File('${from.path}.restore');
    await tmp.writeAsBytes(bytes.sublist(21));
    final log = FactLog(
        tmp, MemoryKey(await (await _key(passphrase, salt)).extractBytes()));
    final read = await log.read();
    final frames = await log.frameCount();
    await tmp.delete();
    final facts = read.values.expand((r) => r.all).toList();
    final kept = await records.record(facts);
    return (kept: kept, refused: frames - facts.length);
  }
}
