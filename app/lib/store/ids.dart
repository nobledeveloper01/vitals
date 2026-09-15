// Identifiers the domain never makes: a patient id and a fact id from the
// platform's random source, and a stamp from the phone's clock and what
// this device last saw. The domain is handed these; it never reads them.
import 'dart:math';

import 'package:vitals_domain/vitals_domain.dart';

final class Ids {
  Ids({required this.device, Random? random}) : _r = random ?? Random.secure();

  /// This device's, named at first launch; Phase 6 gives it the enrolled name.
  static final shared = Ids(device: 'this-device');
  final String device;
  final Random _r;
  Stamp? _last;

  List<int> patient() => List<int>.generate(16, (_) => _r.nextInt(256));
  List<int> fact() => List<int>.generate(32, (_) => _r.nextInt(256));

  Stamp stamp({DateTime? now}) {
    _last = Stamp.next(
        last: _last,
        nowMillis: (now ?? DateTime.now()).millisecondsSinceEpoch,
        device: device);
    return _last!;
  }

  /// What a device does with a stamp it received.
  void saw(Stamp s, {DateTime? now}) {
    _last = Stamp.receive(
        last: _last,
        seen: s,
        nowMillis: (now ?? DateTime.now()).millisecondsSinceEpoch,
        device: device);
  }
}
