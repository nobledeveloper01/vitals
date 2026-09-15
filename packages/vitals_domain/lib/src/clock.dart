/// A hybrid logical clock: wall time as the device believed it, and a counter
/// that breaks ties and keeps order when two devices' clocks disagree. Two
/// stamps compare by (wall, counter, device), which is total and stable, so
/// every device orders the same facts the same way. Time is an argument: the
/// domain never reads a clock.
final class Stamp implements Comparable<Stamp> {
  const Stamp({required this.wallMillis, required this.counter, required this.device});

  /// Milliseconds since 1970, as the device believed it. Kept, never trusted.
  final int wallMillis;

  /// Advances when the wall clock does not, so two facts a millisecond apart
  /// on one device still order.
  final int counter;

  /// The device that made the stamp; the final tie-break.
  final String device;

  /// The next stamp on [device], given what it last saw and what its clock says.
  /// Physical time only moves the clock forward; a device whose clock went back
  /// keeps counting from the latest stamp it has seen.
  static Stamp next({required Stamp? last, required int nowMillis, required String device}) {
    if (last == null || nowMillis > last.wallMillis) {
      return Stamp(wallMillis: nowMillis, counter: 0, device: device);
    }
    return Stamp(wallMillis: last.wallMillis, counter: last.counter + 1, device: device);
  }

  /// What a device does with a stamp it received: its own next stamp is after
  /// both what it saw and what it has.
  static Stamp receive({required Stamp? last, required Stamp seen, required int nowMillis, required String device}) {
    final wall = [nowMillis, seen.wallMillis, last?.wallMillis ?? 0].reduce((a, b) => a > b ? a : b);
    var counter = 0;
    if (wall == seen.wallMillis && wall == (last?.wallMillis ?? -1)) {
      counter = (seen.counter > last!.counter ? seen.counter : last.counter) + 1;
    } else if (wall == seen.wallMillis) {
      counter = seen.counter + 1;
    } else if (wall == (last?.wallMillis ?? -1)) {
      counter = last!.counter + 1;
    }
    return Stamp(wallMillis: wall, counter: counter, device: device);
  }

  @override
  int compareTo(Stamp other) {
    if (wallMillis != other.wallMillis) return wallMillis.compareTo(other.wallMillis);
    if (counter != other.counter) return counter.compareTo(other.counter);
    return device.compareTo(other.device);
  }

  @override
  bool operator ==(Object other) =>
      other is Stamp && other.wallMillis == wallMillis && other.counter == counter && other.device == device;

  @override
  int get hashCode => Object.hash(wallMillis, counter, device);

  @override
  String toString() => '$wallMillis.$counter@$device';
}
