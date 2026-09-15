// The HTTP transport against a real local server: JSON both ways, an
// error status surfaced as an exception, and the wipe question asked at a
// meeting through Settings' own button.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/screens/settings.dart';
import 'package:vitals/speech/strings.dart';
import 'package:vitals/store/http_transport.dart';
import 'package:vitals/store/preferences.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals/store/sync.dart';

void main() {
  test('JSON in, JSON out, and a 4xx is an exception', () async {
    // The test binding stubs every HttpClient to a 400; a real one for this.
    HttpOverrides.global = null;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final body = await utf8.decoder.bind(req).join();
      if (req.uri.path == '/echo') {
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'method': req.method, 'got': body}));
      } else {
        req.response.statusCode = 403;
        req.response.write('no');
      }
      await req.response.close();
    });
    final t = HttpTransport(Uri.parse('http://127.0.0.1:${server.port}'));
    expect(await t.getJson('/echo'), {'method': 'GET', 'got': ''});
    expect(await t.postJson('/echo', {'a': 1}),
        {'method': 'POST', 'got': '{"a":1}'});
    await expectLater(t.getJson('/other'), throwsA(isA<HttpException>()));
    await server.close();
  });

  testWidgets(
      'Settings meets the replica and reports; a wipe is said and the face reset',
      (t) async {
    // File IO runs through the real loop; the fake clock never turns it.
    late Directory dir;
    late Records records;
    await t.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('vitals-meet-');
      records = await Records.at(
          File('${dir.path}/facts.log'), List<int>.generate(32, (i) => i + 19));
    });
    addTearDown(() => dir.delete(recursive: true));
    Preferences.shared.face = Face.clinic;
    addTearDown(() => Preferences.shared.face = Face.unchosen);
    // The replica card is far down the list; a tall surface builds it.
    t.view.physicalSize = const Size(800, 2400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    var wipe = false;
    await t.pumpWidget(MaterialApp(
        home: SettingsScreen(
            records: records,
            makeSync: (url) =>
                Sync(_Fake(() => wipe), facility: 'ikeja', device: 'tab-x'))));
    await t.pumpAndSettle();
    await t.tap(find.text(Strings.meetTheReplica));
    await t.pumpAndSettle();
    expect(find.text(Strings.replicaNotSet), findsOneWidget);
    await t.enterText(
        find.byKey(const Key('replicaUrl')), 'http://replica.local');
    await t.enterText(find.byKey(const Key('facilityName')), 'Ikeja PHC');
    await t.runAsync(() async {
      await t.tap(find.text(Strings.meetTheReplica));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pumpAndSettle();
    expect(
        find.text('${Strings.pushed} 0 · ${Strings.pulled} 0'), findsOneWidget);
    expect(Preferences.shared.replicaUrl, 'http://replica.local');
    wipe = true;
    await t.runAsync(() async {
      await t.tap(find.text(Strings.meetTheReplica));
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('wipedNote')), findsOneWidget);
    expect(Preferences.shared.face, Face.unchosen, reason: 'a blank tablet');
  });
}

final class _Fake implements Transport {
  _Fake(this.wipe);
  final bool Function() wipe;
  @override
  Future<Map<String, Object?>> getJson(String path) async =>
      path.startsWith('/devices/')
          ? {'wipe': wipe()}
          : {'facts': [], 'more': false, 'cursor': 0};
  @override
  Future<Map<String, Object?>> postJson(
          String path, Map<String, Object?> body) async =>
      {'added': 0};
}
