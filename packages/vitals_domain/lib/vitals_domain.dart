/// The clinical record as data: immutable facts, a hybrid logical clock, union
/// merge, supersession, and one canonical encoding. Imports nothing — not
/// Flutter, not a clock, not randomness — because every device and the server
/// must compute the same bytes from the same facts (ADR-0002, ADR-0003).
library;

export 'src/clock.dart';
export 'src/fact.dart';
export 'src/record.dart';
export 'src/merge.dart';
export 'src/canonical.dart';
export 'src/exchange.dart';
export 'src/registration.dart';
export 'src/names.dart';
export 'src/registry.dart';
export 'src/immunisation.dart';
export 'src/gs1.dart';
