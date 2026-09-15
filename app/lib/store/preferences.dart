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
  List<int> _facility = const [];
  bool _locked = false;
  SharedPreferences? _store;

  Face get face => _face;

  /// The facility's own record id — where stock and the fridge log hang.
  /// Made once on this tablet and kept; a test hands one in.
  List<int> get facility => _facility;
  bool get largeType => _largeType;
  bool get locked => _locked;

  /// Read what was remembered; a phone with nothing remembered is unchanged.
  Future<void> load() async {
    try {
      _store = await SharedPreferences.getInstance();
      _face = Face.values[_store!.getInt('face') ?? 0];
      _largeType = _store!.getBool('largeType') ?? false;
      final hex = _store!.getString('facility');
      _facility = hex == null
          ? const []
          : [
              for (var i = 0; i < hex.length; i += 2)
                int.parse(hex.substring(i, i + 2), radix: 16)
            ];
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

  /// The facility id, made with [make] the first time it is asked for. No
  /// listener is told: nothing on a screen changes when it comes to exist,
  /// and it is asked for while screens are building.
  List<int> facilityOrMake(List<int> Function() make) {
    if (_facility.isEmpty) {
      _facility = make();
      _store?.setString('facility',
          _facility.map((b) => b.toRadixString(16).padLeft(2, '0')).join());
    }
    return _facility;
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
