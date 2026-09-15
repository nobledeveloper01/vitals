// DESIGN.md's motion tokens, and the two switches with a floor under them:
// glass off draws every depth as its solid twin; reduced motion makes every
// duration zero. Both are read at act time, so Settings takes effect without
// a relaunch, and both default from what the platform says about the device.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final class Motion extends ChangeNotifier {
  Motion._();
  static final shared = Motion._();

  bool _glass = true;
  bool _reduced = false;

  bool get glass => _glass;
  bool get reduced => _reduced;

  set glass(bool v) {
    if (v == _glass) return;
    _glass = v;
    notifyListeners();
  }

  set reduced(bool v) {
    if (v == _reduced) return;
    _reduced = v;
    notifyListeners();
  }

  /// Zero when reduced; the token otherwise.
  Duration of(Duration token) => _reduced ? Duration.zero : token;

  static const quick = Duration(milliseconds: 120);
  static const move = Duration(milliseconds: 240);
  static const arrive = Duration(milliseconds: 320);
  static const sweep = Duration(milliseconds: 900);

  /// What the platform said at launch; a user's choice overrides it.
  static void readPlatform(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq != null && mq.disableAnimations) shared.reduced = true;
    if (kDebugMode &&
        const bool.fromEnvironment('VITALS_PLAIN', defaultValue: false)) {
      shared.glass = false;
    }
  }
}
