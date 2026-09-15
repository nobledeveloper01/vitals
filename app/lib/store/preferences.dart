// What the app remembers about itself — the face, large type — kept in the
// platform's preferences (never a record; those are in the log). Launch
// arguments pin them for the tests.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Face { unchosen, clinic, patient }

final class Preferences extends ChangeNotifier {
  Preferences._();
  static final shared = Preferences._();

  Face _face = Face.unchosen;
  bool _largeType = false;
  bool _locked = false;
  SharedPreferences? _store;

  Face get face => _face;
  bool get largeType => _largeType;
  bool get locked => _locked;

  /// Read what was remembered; a phone with nothing remembered is unchanged.
  Future<void> load() async {
    try {
      _store = await SharedPreferences.getInstance();
      _face = Face.values[_store!.getInt('face') ?? 0];
      _largeType = _store!.getBool('largeType') ?? false;
      notifyListeners();
    } catch (_) {
      // No platform (a test): memory only.
    }
  }

  set face(Face f) {
    _face = f;
    _store?.setInt('face', f.index);
    notifyListeners();
  }

  set largeType(bool v) {
    _largeType = v;
    _store?.setBool('largeType', v);
    notifyListeners();
  }

  set locked(bool v) {
    _locked = v;
    notifyListeners();
  }
}
