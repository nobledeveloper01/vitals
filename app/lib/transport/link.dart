// The peer transport façade (Phase 5): a link carries frames between two
// devices and knows nothing about records. The handover protocol on top
// is the same over BLE, over an in-memory pair in a test, and — one frame
// at a time through a camera — over the animated QR: `Frame` and `Gather`
// are the domain's, so the bytes a receiver assembles are the same
// whichever way they came.
import 'dart:async';

import 'package:vitals_domain/vitals_domain.dart';

abstract interface class PeerLink {
  /// Frames as they arrive, already checked by their checksum.
  Stream<Frame> get incoming;

  /// The most bytes one frame's part may carry on this link (a BLE MTU
  /// less the frame header; a camera's QR capacity).
  int get partSize;

  Future<void> send(Frame frame);
  Future<void> close();
}

abstract final class Handover {
  /// Every frame of the payload, in order, then done. A receiver that
  /// missed one asks for nothing: the sender may repeat the whole set,
  /// and Gather counts a repeat once.
  static Future<void> send(PeerLink link, List<int> payload,
      {int repeats = 1}) async {
    final frames = Frame.cut(payload, size: link.partSize);
    for (var r = 0; r < repeats; r++) {
      for (final f in frames) {
        await link.send(f);
      }
    }
  }

  /// The payload once every frame has arrived, or null when the link
  /// closes first. [onProgress] is the fraction gathered so far.
  static Future<List<int>?> receive(PeerLink link,
      {void Function(double)? onProgress}) async {
    final g = Gather();
    await for (final f in link.incoming) {
      g.add(f);
      onProgress?.call(g.progress);
      if (g.complete) return g.payload;
    }
    return null;
  }
}

/// Two ends of a pipe in memory: what a test uses, and what the BLE
/// adapter is held to.
final class MemoryLink implements PeerLink {
  MemoryLink._(this._in, this._out, this.partSize, {this.drop = const {}});
  final StreamController<Frame> _in, _out;
  @override
  final int partSize;

  /// Frame indexes this end silently loses on send, for a test that wants
  /// a lossy link.
  final Set<int> drop;

  static (MemoryLink a, MemoryLink b) pair(
      {int partSize = 160, Set<int> dropFromA = const {}}) {
    final ab = StreamController<Frame>.broadcast();
    final ba = StreamController<Frame>.broadcast();
    return (
      MemoryLink._(ba, ab, partSize, drop: dropFromA),
      MemoryLink._(ab, ba, partSize),
    );
  }

  @override
  Stream<Frame> get incoming => _in.stream;

  @override
  Future<void> send(Frame frame) async {
    if (drop.contains(frame.index)) return;
    // As the wire would: bytes out, bytes in, decoded on the other side.
    final decoded = Frame.decode(frame.encode());
    if (decoded != null && !_out.isClosed) _out.add(decoded);
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<void> close() async {
    await _out.close();
  }
}
