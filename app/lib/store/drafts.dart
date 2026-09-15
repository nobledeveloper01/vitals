// A form's draft, written on every change and read when the form opens, so
// a hard kill mid-entry loses nothing but the last keystroke. One small
// file per form, in the app's own directory, plain text of the fields the
// nurse typed — not a record, not a fact, and cleared the moment the fact
// is written.
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

final class Drafts {
  Drafts(this._dir);
  final Directory _dir;

  static Future<Drafts> open() async => Drafts(
      Directory('${(await getApplicationSupportDirectory()).path}/drafts'));

  File _file(String key) => File('${_dir.path}/$key.json');

  Future<Map<String, String>> read(String key) async {
    final f = _file(key);
    if (!await f.exists()) return const {};
    try {
      return Map<String, String>.from(
          jsonDecode(await f.readAsString()) as Map);
    } catch (_) {
      return const {};
    }
  }

  /// One write at a time per form: a keystroke's write waits for the last.
  final _chain = <String, Future<void>>{};

  Future<void> write(String key, Map<String, String> fields) {
    final next = (_chain[key] ?? Future.value()).then((_) async {
      await _dir.create(recursive: true);
      // Write beside, then rename: a kill during the write leaves the last
      // whole draft, never half of one.
      final tmp = File('${_dir.path}/$key.tmp');
      await tmp.writeAsString(jsonEncode(fields), flush: true);
      await tmp.rename(_file(key).path);
    });
    _chain[key] = next.catchError((_) {});
    return next;
  }

  Future<void> clear(String key) async {
    await (_chain[key] ?? Future.value());
    final f = _file(key);
    if (await f.exists()) await f.delete();
  }
}
