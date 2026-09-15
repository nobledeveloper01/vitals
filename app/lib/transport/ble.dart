// BLE as a PeerLink (Phase 5, R3). The sender is a peripheral advertising
// one service with one characteristic it notifies frames on; the receiver
// is a central that finds the service, subscribes, and gathers. No pairing
// and no bonding: what crosses the air is the payload the grant allowed,
// which the patient chose to hand over, and a frame is useless without
// the rest. Built against the plugin's interface; proved only over the
// in-memory link until two handsets are in hand (RELEASE-GATES R3).
import 'dart:async';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:vitals_domain/vitals_domain.dart';

import 'link.dart';

abstract final class BleIds {
  /// A 128-bit UUID of Vitals' own, so a scanner sees nothing but ours.
  static final service =
      UUID.fromString('7a1e5f00-9c1b-4b6a-8b3e-0d2f5a6c7e90');
  static final frames = UUID.fromString('7a1e5f01-9c1b-4b6a-8b3e-0d2f5a6c7e90');
  static const String name = 'Vitals';
}

/// The sending end: advertise, wait for a central to subscribe, notify.
final class BlePeripheralLink implements PeerLink {
  BlePeripheralLink({PeripheralManager? manager})
      : _pm = manager ?? PeripheralManager();
  final PeripheralManager _pm;
  final _incoming = StreamController<Frame>.broadcast();
  final _subscribed = Completer<Central>();
  late final GATTCharacteristic _chr;
  StreamSubscription<Object>? _notifyState;
  int _mtu = 23;

  @override
  int get partSize => (_mtu - 3 - Frame.header).clamp(20, 400);

  Future<void> open() async {
    _chr = GATTCharacteristic.mutable(
      uuid: BleIds.frames,
      properties: [GATTCharacteristicProperty.notify],
      permissions: [GATTCharacteristicPermission.read],
      descriptors: [],
    );
    await _pm.removeAllServices();
    await _pm.addService(GATTService(
        uuid: BleIds.service,
        isPrimary: true,
        includedServices: [],
        characteristics: [_chr]));
    _notifyState = _pm.characteristicNotifyStateChanged.listen((e) async {
      if (e.state && !_subscribed.isCompleted) {
        _mtu = await _pm.getMaximumNotifyLength(e.central) + 3;
        _subscribed.complete(e.central);
      }
    });
    await _pm.startAdvertising(
        Advertisement(name: BleIds.name, serviceUUIDs: [BleIds.service]));
  }

  /// Waits for the receiver to subscribe before the first frame.
  @override
  Future<void> send(Frame frame) async {
    final central = await _subscribed.future;
    await _pm.notifyCharacteristic(central, _chr,
        value: Uint8List.fromList(frame.encode()));
  }

  @override
  Stream<Frame> get incoming => _incoming.stream;

  @override
  Future<void> close() async {
    await _notifyState?.cancel();
    await _pm.stopAdvertising();
    await _pm.removeAllServices();
    await _incoming.close();
  }
}

/// The receiving end: discover the service, connect, subscribe, decode.
final class BleCentralLink implements PeerLink {
  BleCentralLink({CentralManager? manager}) : _cm = manager ?? CentralManager();
  final CentralManager _cm;
  final _incoming = StreamController<Frame>.broadcast();
  Peripheral? _peer;
  StreamSubscription<Object>? _notified, _found;

  @override
  int get partSize => 160;

  /// Finds the first Vitals peripheral and subscribes to its frames.
  Future<void> open({Duration timeout = const Duration(seconds: 30)}) async {
    final found = Completer<Peripheral>();
    _found = _cm.discovered.listen((e) {
      if (e.advertisement.serviceUUIDs.contains(BleIds.service) &&
          !found.isCompleted) {
        found.complete(e.peripheral);
      }
    });
    await _cm.startDiscovery(serviceUUIDs: [BleIds.service]);
    final peer = _peer = await found.future.timeout(timeout);
    await _cm.stopDiscovery();
    await _cm.connect(peer);
    final services = await _cm.discoverGATT(peer);
    final chr = services
        .firstWhere((s) => s.uuid == BleIds.service)
        .characteristics
        .firstWhere((c) => c.uuid == BleIds.frames);
    _notified = _cm.characteristicNotified.listen((e) {
      if (e.characteristic.uuid != BleIds.frames) return;
      final f = Frame.decode(e.value);
      if (f != null && !_incoming.isClosed) _incoming.add(f);
    });
    await _cm.setCharacteristicNotifyState(peer, chr, state: true);
  }

  @override
  Stream<Frame> get incoming => _incoming.stream;

  @override
  Future<void> send(Frame frame) async {
    // The receiving end sends nothing in this protocol.
  }

  @override
  Future<void> close() async {
    await _found?.cancel();
    await _notified?.cancel();
    final p = _peer;
    if (p != null) await _cm.disconnect(p);
    await _incoming.close();
  }
}
