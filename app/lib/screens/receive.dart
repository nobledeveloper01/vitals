// The other side of the handover (ADR-0006 #3): a camera on the sending
// phone's screen, gathering frames in whatever order they come until the
// record is whole, then the union merge — nothing is overwritten, what was
// missing is added. A device with no camera pastes the code's text instead;
// the same gather, the same merge. The frame around the viewfinder fills
// as the frames arrive, and says how many are still to come.
import 'package:flutter/material.dart' hide Card;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vitals_domain/vitals_domain.dart';

import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/patient_strings.dart';
import '../store/records.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen(
      {super.key, required this.records, this.camera = true, this.now});
  final Records records;

  /// False where there is no camera (a test, a desktop): the paste field
  /// alone.
  final bool camera;
  final DateTime? now;

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  final _gather = Gather();

  /// One controller for the screen's life, so a rebuild does not start the
  /// camera twice.
  late final MobileScannerController? _camera =
      widget.camera ? MobileScannerController() : null;
  final _paste = TextEditingController();
  String? _refusal;
  (String name, int facts, int added)? _done;

  @override
  void dispose() {
    _camera?.dispose();
    _paste.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final done = _done;
    return Scaffold(
      body: Mesh(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(Gap.l),
            children: [
              const Align(
                  alignment: Alignment.centerLeft, child: BackButton2()),
              Text(
                  PatientStrings.face('receiveRecord',
                      PatientStrings.english['receiveRecord']!),
                  style: Type.display.copyWith(color: p.textPrimary)),
              const SizedBox(height: Gap.xs),
              Text(
                  PatientStrings.face(
                      'receiveHint', PatientStrings.english['receiveHint']!),
                  style: Type.secondary.copyWith(color: p.textSecondary)),
              const SizedBox(height: Gap.m),
              if (done != null)
                Glass(
                  depth: Depth.low,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.check_circle, color: p.fine),
                        const SizedBox(width: Gap.s),
                        Expanded(
                            child: Text(done.$1,
                                style: Type.headline
                                    .copyWith(color: p.textPrimary))),
                      ]),
                      const SizedBox(height: Gap.xs),
                      Text(
                          '${done.$2} ${PatientStrings.shared('factsReceived')} · ${done.$3} ${PatientStrings.shared('factsNew')}',
                          style:
                              Type.secondary.copyWith(color: p.textSecondary),
                          key: const Key('received')),
                    ],
                  ),
                )
              else ...[
                if (widget.camera)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Radius2.card),
                    child: SizedBox(
                      height: 300,
                      child: MobileScanner(
                        controller: _camera,
                        // No camera, or no permission: say so in the app's
                        // own words; the paste field below still works.
                        errorBuilder: (context, error) => Container(
                          color: p.glassHigh,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(Gap.l),
                          child: Text(
                              error.errorCode ==
                                      MobileScannerErrorCode.permissionDenied
                                  ? PatientStrings.shared('cameraRefused')
                                  : PatientStrings.shared('noCamera'),
                              textAlign: TextAlign.center,
                              style:
                                  Type.body.copyWith(color: p.textSecondary)),
                        ),
                        onDetect: (capture) {
                          for (final b in capture.barcodes) {
                            final v = b.rawValue;
                            if (v != null) _take(v);
                          }
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: Gap.m),
                Glass(
                  depth: Depth.low,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          _gather.total == 0
                              ? PatientStrings.face('waitingForCode',
                                  PatientStrings.english['waitingForCode']!)
                              : '${_gather.have} / ${_gather.total} · ${_gather.missing.length} ${PatientStrings.shared('framesToCome')}',
                          style: Type.title.copyWith(color: p.textPrimary),
                          key: const Key('progress')),
                      if (_gather.total > 0) ...[
                        const SizedBox(height: Gap.s),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(Radius2.chip),
                          child: LinearProgressIndicator(
                              value: _gather.progress,
                              minHeight: 6,
                              backgroundColor: p.hairline,
                              color: p.accent),
                        ),
                      ],
                      const SizedBox(height: Gap.m),
                      TextField(
                        key: const Key('pasteField'),
                        controller: _paste,
                        maxLines: 3,
                        style: Type.small.copyWith(color: p.textPrimary),
                        decoration: InputDecoration(
                            labelText: PatientStrings.face('pasteCode',
                                PatientStrings.english['pasteCode']!),
                            helperText: PatientStrings.face('pasteHint',
                                PatientStrings.english['pasteHint']!),
                            helperMaxLines: 2,
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(Radius2.input))),
                      ),
                      const SizedBox(height: Gap.s),
                      SecondaryButton(
                          label: PatientStrings.face(
                              'addCode', PatientStrings.english['addCode']!),
                          onPressed: () {
                            _take(_paste.text);
                            _paste.clear();
                          }),
                      if (_refusal != null) ...[
                        const SizedBox(height: Gap.s),
                        Text(_refusal!,
                            style: Type.body.copyWith(color: p.danger),
                            key: const Key('refusal')),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// One scan or one paste. A frame that is not a frame is said so; a
  /// frame already seen changes nothing; the last one merges the record.
  Future<void> _take(String text) async {
    final frame = Frame.fromText(text);
    if (frame == null) {
      setState(() => _refusal = PatientStrings.face(
          'notAVitalsCode', PatientStrings.english['notAVitalsCode']!));
      return;
    }
    final added = _gather.add(frame);
    setState(() => _refusal = null);
    if (!added || !_gather.complete) return;
    final Record received;
    try {
      received = Canonical.recordFrom(_gather.payload);
    } on Object {
      setState(() => _refusal = PatientStrings.face(
          'codeDamaged', PatientStrings.english['codeDamaged']!));
      return;
    }
    final before = widget.records.all[_hex(received.patient)]?.length ?? 0;
    await widget.records
        .met(received.all, at: widget.now ?? DateTime.now().toUtc());
    final after = widget.records.all[_hex(received.patient)]?.length ?? 0;
    final reg = Registration.of(received.current);
    if (mounted) {
      setState(() => _done = (
            reg?.fullName ??
                PatientStrings.face(
                    'aRecord', PatientStrings.english['aRecord']!),
            received.length,
            after - before
          ));
    }
  }

  static String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
}
