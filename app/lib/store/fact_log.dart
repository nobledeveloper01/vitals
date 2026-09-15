// The store: an append-only log of canonical single-fact records, each
// sealed with ChaCha20-Poly1305 under a key that never lives in the file.
// Nothing is rewritten; a merge appends what was missing. Reading is
// decrypting and unioning. ADR-0007.
//
// Frame: u32 length, 12-byte nonce, then the ciphertext with its 16-byte
// tag. A frame cut short by a dead battery is the last frame and is dropped.
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:vitals_domain/vitals_domain.dart';

/// Where the key comes from. The platform keychain on a phone; memory in tests.
abstract interface class KeySource {
  Future<List<int>> key();
}

final class MemoryKey implements KeySource {
  MemoryKey(this._key);
  final List<int> _key;
  @override
  Future<List<int>> key() async => _key;
}

final class FactLog {
  FactLog(this.file, this.keys);
  final File file;
  final KeySource keys;
  static final _cipher = Chacha20.poly1305Aead();

  /// Frames written so far, counted once from the file and kept, so an
  /// append does not re-read a log that grows with every patient.
  int? _count;

  /// The nonce is the counter of frames written, never reused under a key
  /// because the log is append-only and a frame is never rewritten.
  Future<void> append(Iterable<Fact> facts) async {
    final key = SecretKey(await keys.key());
    var n = _count ??= await _frames();
    final sink = file.openWrite(mode: FileMode.append);
    for (final f in facts) {
      final plain = Canonical.bytesOf(Record.of(f.patient, [f]));
      final nonce = _nonce(n++);
      final box = await _cipher.encrypt(plain, secretKey: key, nonce: nonce);
      final body = [...box.cipherText, ...box.mac.bytes];
      sink.add(_u32(body.length));
      sink.add(nonce);
      sink.add(body);
    }
    await sink.flush();
    await sink.close();
    _count = n;
  }

  /// Everything in the log, decrypted and unioned per patient. A frame that
  /// does not decrypt or decode is not a fact and is not counted; a frame
  /// cut short is the end of the log.
  Future<Map<String, Record>> read() async {
    if (!await file.exists()) return {};
    final key = SecretKey(await keys.key());
    final bytes = await file.readAsBytes();
    final out = <String, Record>{};
    var i = 0;
    while (i + 4 + 12 <= bytes.length) {
      final len = ByteData.sublistView(bytes, i, i + 4).getUint32(0);
      i += 4;
      if (i + 12 + len > bytes.length) break;
      final nonce = bytes.sublist(i, i + 12);
      i += 12;
      final body = bytes.sublist(i, i + len);
      i += len;
      try {
        final plain = await _cipher.decrypt(
          SecretBox(body.sublist(0, body.length - 16),
              nonce: nonce, mac: Mac(body.sublist(body.length - 16))),
          secretKey: key,
        );
        final r = Canonical.recordFrom(plain);
        final k = _hex(r.patient);
        out[k] = out.containsKey(k) ? Merge.union(out[k]!, r) : r;
      } on SecretBoxAuthenticationError {
        continue;
      } on CanonicalError {
        continue;
      }
    }
    return out;
  }

  /// How many frames the file holds, whatever they decrypt to.
  Future<int> frameCount() async => _count ??= await _frames();

  Future<int> _frames() async {
    if (!await file.exists()) return 0;
    final bytes = await file.readAsBytes();
    var i = 0, n = 0;
    while (i + 4 + 12 <= bytes.length) {
      final len = ByteData.sublistView(bytes, i, i + 4).getUint32(0);
      if (i + 4 + 12 + len > bytes.length) break;
      i += 4 + 12 + len;
      n++;
    }
    return n;
  }

  static List<int> _nonce(int n) {
    final b = List<int>.filled(12, 0);
    for (var s = 0; s < 8; s++) {
      b[11 - s] = (n >> (8 * s)) & 0xff;
    }
    return b;
  }

  static List<int> _u32(int v) =>
      [(v >> 24) & 0xff, (v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff];

  static String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
}
