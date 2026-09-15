// The replica over HTTP, with nothing but dart:io: JSON in, JSON out, a
// short timeout, and any failure surfaced as a word the screen can show.
// Enrolment is a URL a facility typed into Settings; until then there is
// no transport and nothing leaves the tablet (rule 6).
import 'dart:convert';
import 'dart:io';

import 'sync.dart';

final class HttpTransport implements Transport {
  HttpTransport(this.base, {HttpClient? client})
      : _client = client ??
            (HttpClient()..connectionTimeout = const Duration(seconds: 8));
  final Uri base;
  final HttpClient _client;

  @override
  Future<Map<String, Object?>> getJson(String path) async {
    final req = await _client.getUrl(base.resolve(path));
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    return _read(await req.close());
  }

  @override
  Future<Map<String, Object?>> postJson(
      String path, Map<String, Object?> body) async {
    final req = await _client.postUrl(base.resolve(path));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode(body));
    return _read(await req.close());
  }

  Future<Map<String, Object?>> _read(HttpClientResponse res) async {
    final text = await res.transform(utf8.decoder).join();
    if (res.statusCode >= 400) {
      throw HttpException('${res.statusCode}: $text');
    }
    if (text.isEmpty) return const {};
    return (jsonDecode(text) as Map).cast<String, Object?>();
  }
}
