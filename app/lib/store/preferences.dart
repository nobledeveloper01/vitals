// What the app remembers about itself — the face, the two floor toggles,
// large type — kept in memory in Phase 0 and in the encrypted store from
// Phase 1. Launch arguments pin them for the tests.
import 'package:flutter/foundation.dart';

enum Face { unchosen, clinic, patient }

final class Preferences extends ChangeNotifier {
  Preferences._();
  static final shared = Preferences._();

  Face _face = Face.unchosen;
  bool _largeType = false;
  bool _locked = false;

  Face get face => _face;
  bool get largeType => _largeType;
  bool get locked => _locked;

  set face(Face f) {
    _face = f;
    notifyListeners();
  }

  set largeType(bool v) {
    _largeType = v;
    notifyListeners();
  }

  set locked(bool v) {
    _locked = v;
    notifyListeners();
  }
}
