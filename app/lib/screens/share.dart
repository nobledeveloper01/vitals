// The patient hands their record over (ADR-0006 #3, #16): a grant — which
// sections, to whom, until when — written as a fact, then the payload built
// from that grant and nothing else, cut into frames and shown as an
// animated QR with the progress ring in the brand gradient. With less
// motion the frames step by hand and the count is the ring.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Card;
import 'package:qr/qr.dart';
import 'package:vitals_domain/vitals_domain.dart';

import '../design/glass.dart';
import '../design/motion.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/patient_strings.dart';
import '../store/ids.dart';
import '../store/records.dart';
import '../transport/ble.dart';
import '../transport/link.dart';

class ShareScreen extends StatefulWidget {
  const ShareScreen(
      {super.key,
      required this.records,
      required this.patient,
      required this.ids,
      required this.today});
  final Records records;
  final List<int> patient;
  final Ids ids;
  final int today;

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _grantee = TextEditingController();
  final _kinds = <FactKind>{FactKind.immunisation};
  int _days = 30;
  List<Frame>? _frames;
  List<int>? _payload;
  String? _bleNote;
  BlePeripheralLink? _ble;

  /// The same bytes over the air (R3): advertise, wait for the clinic's
  /// tablet to subscribe, send every frame twice.
  Future<void> _sendOverBluetooth() async {
    final payload = _payload;
    if (payload == null) return;
    setState(() => _bleNote = PatientStrings.t('bleWaiting'));
    final link = _ble = BlePeripheralLink();
    try {
      await link.open();
      await Handover.send(link, payload, repeats: 2);
      if (mounted) setState(() => _bleNote = PatientStrings.t('bleSent'));
    } catch (e) {
      if (mounted) {
        setState(() => _bleNote = '${PatientStrings.t('bleFailed')} $e');
      }
    } finally {
      await link.close();
      _ble = null;
    }
  }

  @override
  void dispose() {
    _ble?.close();
    _grantee.dispose();
    super.dispose();
  }

  static const _choices = [
    FactKind.immunisation,
    FactKind.vitals,
    FactKind.ancVisit,
    FactKind.note,
  ];

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final frames = _frames;
    return Scaffold(
      body: Mesh(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(Gap.l),
            children: [
              const Align(
                  alignment: Alignment.centerLeft, child: BackButton2()),
              Text(PatientStrings.t('shareRecord'),
                  style: Type.display.copyWith(color: p.textPrimary)),
              const SizedBox(height: Gap.m),
              if (frames == null) ...[
                Glass(
                  depth: Depth.low,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        key: const Key('grantee'),
                        controller: _grantee,
                        onChanged: (_) => setState(() {}),
                        style: Type.body.copyWith(color: p.textPrimary),
                        decoration: InputDecoration(
                            labelText: PatientStrings.t('toWhom'),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(Radius2.input))),
                      ),
                      const SizedBox(height: Gap.m),
                      Text(PatientStrings.t('whichParts'),
                          style:
                              Type.secondary.copyWith(color: p.textSecondary)),
                      const SizedBox(height: Gap.xs),
                      Text(PatientStrings.t('nameAlwaysGoes'),
                          style: Type.small.copyWith(color: p.textSecondary)),
                      const SizedBox(height: Gap.s),
                      Wrap(
                        spacing: Gap.s,
                        runSpacing: Gap.s,
                        children: [
                          for (final k in _choices)
                            FilterChip(
                              key: Key('kind-${k.name}'),
                              label: Text(PatientStrings.t('kind.${k.name}')),
                              selected: _kinds.contains(k),
                              selectedColor: p.accent,
                              labelStyle: Type.small.copyWith(
                                  color: _kinds.contains(k)
                                      ? p.textOnAccent
                                      : p.textPrimary),
                              onSelected: (v) => setState(
                                  () => v ? _kinds.add(k) : _kinds.remove(k)),
                            ),
                        ],
                      ),
                      const SizedBox(height: Gap.m),
                      Text(PatientStrings.t('forHowLong'),
                          style:
                              Type.secondary.copyWith(color: p.textSecondary)),
                      const SizedBox(height: Gap.s),
                      Wrap(
                        spacing: Gap.s,
                        children: [
                          for (final d in const [1, 30, 365])
                            ChoiceChip(
                              key: Key('days-$d'),
                              label: Text('$d ${PatientStrings.t('days')}'),
                              selected: _days == d,
                              selectedColor: p.accent,
                              labelStyle: Type.small.copyWith(
                                  color: _days == d
                                      ? p.textOnAccent
                                      : p.textPrimary),
                              onSelected: (_) => setState(() => _days = d),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Gap.m),
                PrimaryButton(
                    label: PatientStrings.t('showCode'),
                    onPressed: _grantee.text.trim().isEmpty ? null : _grant),
              ] else ...[
                AnimatedQr(frames: frames, key: const Key('qr')),
                const SizedBox(height: Gap.m),
                Text(
                    '${PatientStrings.t('holdStill')} · ${_grantee.text.trim()} · ${PatientStrings.t('until')} ${_date(widget.today + _days)}',
                    style: Type.secondary.copyWith(color: p.textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: Gap.m),
                SecondaryButton(
                    label: PatientStrings.t('sendOverBluetooth'),
                    onPressed: _ble == null ? _sendOverBluetooth : null),
                if (_bleNote != null) ...[
                  const SizedBox(height: Gap.s),
                  Text(_bleNote!,
                      style: Type.secondary.copyWith(color: p.textSecondary),
                      textAlign: TextAlign.center,
                      key: const Key('bleNote')),
                ],
                const SizedBox(height: Gap.s),
                SecondaryButton(
                    label: PatientStrings.t('done'),
                    onPressed: () => Navigator.of(context).pop()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The grant as a fact, then the payload from the grant — the same
  /// function the receiver would use to check what it was handed.
  Future<void> _grant() async {
    final grantee = _grantee.text.trim();
    final grant = Grant(
        grantee: grantee,
        kinds: Set.of(_kinds),
        untilDays: widget.today + _days,
        givenDays: widget.today);
    await widget.records.record([
      Fact(
          id: widget.ids.fact(),
          patient: widget.patient,
          kind: FactKind.access,
          stamp: widget.ids.stamp(),
          author: 'patient',
          payload: grant.encode(),
          supersedes: null)
    ]);
    final record = widget.records.all[_hex(widget.patient)]!;
    final facts =
        Scope.payload(record, grantee: grantee, todayDays: widget.today);
    final bytes = Canonical.bytesOf(Record.of(widget.patient, facts));
    if (mounted) {
      setState(() {
        _payload = bytes;
        _frames = Frame.cut(bytes);
      });
    }
  }

  static String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

  static String _date(int days) {
    final d = DateTime.utc(1970).add(Duration(days: days));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

/// The frames as QR codes, one after another, with the frame around them
/// filling as the frames go by. With less motion: one frame, stepped by
/// hand, the ring still counting.
class AnimatedQr extends StatefulWidget {
  const AnimatedQr(
      {super.key,
      required this.frames,
      this.perFrame = const Duration(milliseconds: 350)});
  final List<Frame> frames;
  final Duration perFrame;

  @override
  State<AnimatedQr> createState() => _AnimatedQrState();
}

class _AnimatedQrState extends State<AnimatedQr> {
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!Motion.shared.reduced && widget.frames.length > 1) {
      _timer = Timer.periodic(widget.perFrame, (_) {
        if (Motion.shared.reduced) return;
        setState(() => _i = (_i + 1) % widget.frames.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final n = widget.frames.length;
    final frame = widget.frames[_i];
    // Text, not bytes: a camera that is not Vitals reads `VITALS/1 …` and
    // knows what it saw; a Vitals device parses the rest.
    final qr = QrCode.fromData(
        data: frame.text, errorCorrectLevel: QrErrorCorrectLevel.M);
    final image = QrImage(qr);
    final reduced = Motion.shared.reduced;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '${PatientStrings.t('code')} ${_i + 1} ${PatientStrings.t('of')} $n',
      child: Column(
        children: [
          SizedBox(
            width: 296,
            height: 296,
            child: CustomPaint(
              painter: _FramePainter(
                  progress: (_i + 1) / n,
                  colours: [p.accent, p.accentEnd],
                  track: p.hairline),
              child: Padding(
                padding: const EdgeInsets.all(Gap.m),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radius2.card - Gap.s),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(Gap.sm),
                    child: CustomPaint(
                        painter: _QrPainter(image, p.code),
                        key: Key('frame-$_i')),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Gap.s),
          Text('${_i + 1} / $n',
              style: Type.title.copyWith(color: p.textPrimary),
              key: const Key('frameCount')),
          if (reduced && n > 1)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                  tooltip: PatientStrings.t('previous'),
                  onPressed: () => setState(() => _i = (_i - 1 + n) % n),
                  icon: Icon(Icons.chevron_left, color: p.textPrimary)),
              IconButton(
                  tooltip: PatientStrings.t('next'),
                  onPressed: () => setState(() => _i = (_i + 1) % n),
                  icon: Icon(Icons.chevron_right, color: p.textPrimary)),
            ]),
        ],
      ),
    );
  }
}

/// The frame around the code: a rounded rectangle, the same shape as the
/// code it holds, with the track in hairline and the progress drawn along
/// its edge in the brand gradient, from the top centre, clockwise.
class _FramePainter extends CustomPainter {
  _FramePainter(
      {required this.progress, required this.colours, required this.track});
  final double progress;
  final List<Color> colours;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(4);
    final rrect =
        RRect.fromRectAndRadius(rect, const Radius.circular(Radius2.card));
    canvas.drawRRect(
        rrect,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    if (progress <= 0) return;
    // A path that starts at the top centre, so the fill grows clockwise
    // from twelve like a clock hand.
    final full = Path()..addRRect(rrect);
    final metric = full.computeMetrics().first;
    final start = metric.length * 0.125; // the top edge's midpoint on a
    // path that begins at the top-left corner's arc
    final total = metric.length * progress.clamp(0.0, 1.0);
    final path = Path();
    final first =
        metric.extractPath(start, math.min(metric.length, start + total));
    path.addPath(first, Offset.zero);
    if (start + total > metric.length) {
      path.addPath(
          metric.extractPath(0, start + total - metric.length), Offset.zero);
    }
    canvas.drawPath(
        path,
        Paint()
          ..shader = SweepGradient(
                  colors: [...colours, colours.first],
                  transform: const GradientRotation(-math.pi / 2))
              .createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.progress != progress;
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image, this.ink);
  final QrImage image;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final n = image.moduleCount;
    final cell = size.width / n;
    final paint = Paint()..color = ink;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (image.isDark(y, x)) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.image != image;
}
