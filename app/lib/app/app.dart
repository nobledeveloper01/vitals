import 'package:flutter/material.dart';

import '../brand/splash.dart';
import '../design/motion.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../fixtures/demo.dart';
import '../screens/face_picker.dart';
import '../screens/lock.dart';
import '../screens/shell.dart';
import '../speech/strings.dart';
import '../store/preferences.dart';
import '../store/records.dart';

class VitalsApp extends StatefulWidget {
  const VitalsApp({super.key, this.open = Records.open});

  /// How the store is opened: the keychain-keyed log on a phone, a file with
  /// a key in memory in the tests.
  final Future<Records> Function() open;

  @override
  State<VitalsApp> createState() => _VitalsAppState();
}

class _VitalsAppState extends State<VitalsApp> {
  var _swept = false;
  Records? _records;

  @override
  void initState() {
    super.initState();
    // Launch arguments pin what the tests need; a phone in a hand sets none.
    const face = String.fromEnvironment('VITALS_FACE', defaultValue: '');
    if (face == 'clinic') Preferences.shared.face = Face.clinic;
    if (face == 'patient') Preferences.shared.face = Face.patient;
    if (const bool.fromEnvironment('VITALS_LOCK', defaultValue: false)) {
      Preferences.shared.locked = true;
    }
    if (const bool.fromEnvironment('VITALS_PLAIN', defaultValue: false)) {
      Motion.shared.glass = false;
    }
    if (const bool.fromEnvironment('VITALS_REDUCE', defaultValue: false)) {
      Motion.shared.reduced = true;
    }
    // What the app remembers, then the store, while the splash is up.
    Preferences.shared.load();
    widget.open().then((r) async {
      if (const bool.fromEnvironment('VITALS_DEMO', defaultValue: false)) {
        await Demo.seed(r);
      }
      if (mounted) setState(() => _records = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Preferences.shared, Motion.shared]),
      builder: (context, _) => MaterialApp(
        title: Strings.appName,
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: Preferences.shared.largeType
                ? TextScaler.linear(
                    MediaQuery.of(context).textScaler.scale(1) * 1.3)
                : MediaQuery.of(context).textScaler,
          ),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            Motion.readPlatform(context);
            // The splash stays up until it has swept and the store has opened.
            if (!_swept || _records == null) {
              return Splash(onDone: () => setState(() => _swept = true));
            }
            if (Preferences.shared.locked) {
              return LockScreen(records: _records);
            }
            if (Preferences.shared.face == Face.unchosen) {
              return const FacePicker();
            }
            return Shell(records: _records!);
          },
        ),
      ),
    );
  }

  ThemeData _theme(Brightness b) {
    final p = b == Brightness.dark ? Palette.dark : Palette.light;
    return ThemeData(
      brightness: b,
      useMaterial3: true,
      fontFamily: Type.family,
      scaffoldBackgroundColor: p.base,
      colorScheme: ColorScheme.fromSeed(
          seedColor: p.accent,
          brightness: b,
          primary: p.accent,
          surface: p.base),
      textTheme: const TextTheme(
          bodyMedium: Type.body,
          titleMedium: Type.title,
          headlineSmall: Type.headline),
    );
  }
}
