// Vital signs (ADR-0008). The pulse card on the patient header: the last of
// each measure with the published range printed beside it, the trend drawn
// behind the number, *outside range* as the only mark. The vitals sheet:
// integers in the measure's own unit, drafted on every keystroke so a hard
// kill loses nothing, every reading a fact with its attribution.
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:vitals_domain/vitals_domain.dart';

import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/strings.dart';
import '../store/drafts.dart';
import '../store/ids.dart';
import '../store/records.dart';

class PulseCard extends StatelessWidget {
  const PulseCard(
      {super.key,
      required this.observations,
      required this.ageDays,
      this.measures = const [
        Measure.pulse,
        Measure.systolic,
        Measure.temperature,
        Measure.spo2,
        Measure.weight
      ]});
  final List<Observation> observations;
  final int ageDays;
  final List<Measure> measures;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final latest = Observation.latest(observations);
    if (latest.isEmpty) {
      return Glass(
          depth: Depth.low,
          child: Text(Strings.noVitalsYet,
              style: Type.body.copyWith(color: p.textSecondary)));
    }
    return Glass(
      depth: Depth.low,
      child: Wrap(
        spacing: Gap.m,
        runSpacing: Gap.s,
        children: [
          for (final m in measures)
            if (latest[m] != null)
              _Tile(
                  latest: latest[m]!,
                  trend: Observation.trend(observations, m),
                  range: Reference.forAge(m, ageDays)),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.latest, required this.trend, this.range});
  final Observation latest;
  final List<Observation> trend;
  final Reference? range;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final outside = range != null && range!.outside(latest.value);
    final rangeText = range == null
        ? ''
        : '${_show(range!.low, latest.measure)}–${_show(range!.high, latest.measure)}';
    final label = [
      latest.measure.label,
      '${latest.display} ${latest.measure.unit}',
      if (range != null) '${Strings.range} $rangeText',
      if (outside) Strings.outsideRange,
    ].join(', ');
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: label,
      child: SizedBox(
        width: 120,
        child: Stack(
          children: [
            Positioned.fill(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(Radius2.chip),
                    child: CustomPaint(
                        painter: _TrendPainter(
                            trend.map((o) => o.value).toList(),
                            (outside ? p.attention : p.accent)
                                .withValues(alpha: 0.3))))),
            Padding(
              padding: const EdgeInsets.all(Gap.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(latest.measure.label,
                      style: Type.small.copyWith(color: p.textSecondary)),
                  Text(latest.display,
                      style: Type.value.copyWith(
                          color: outside ? p.attention : p.textPrimary),
                      key: Key('value-${latest.measure.name}')),
                  Text(
                      range == null
                          ? latest.measure.unit
                          : '${latest.measure.unit} · $rangeText',
                      style: Type.small.copyWith(color: p.textSecondary)),
                  if (outside)
                    Text(Strings.outsideRange,
                        style: Type.small.copyWith(color: p.attention)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _show(int v, Measure m) =>
      Observation(measure: m, value: v, takenMinutes: 0).display;
}

/// The trend behind the number: a line through the readings, oldest left.
/// No axis, no slope named — a shape the eye reads, by ADR-0008.
class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values, this.colour);
  final List<int> values;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final span = (hi - lo).clamp(1, 1 << 30);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height * (0.92 - 0.4 * (values[i] - lo) / span);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = colour
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values || old.colour != colour;
}

/// The vitals sheet. Fields are text so the keyboard is numeric and the
/// draft is a string; a field the nurse leaves empty records nothing.
class VitalsSheet extends StatefulWidget {
  const VitalsSheet(
      {super.key,
      required this.records,
      required this.patient,
      required this.ids,
      required this.author,
      required this.drafts,
      required this.nowMinutes,
      this.measures = const [
        Measure.systolic,
        Measure.diastolic,
        Measure.pulse,
        Measure.temperature,
        Measure.respiratory,
        Measure.spo2,
        Measure.weight,
        Measure.height,
        Measure.muac
      ]});
  final Records records;
  final List<int> patient;
  final Ids ids;
  final String author;
  final Drafts drafts;
  final int nowMinutes;
  final List<Measure> measures;

  String get draftKey =>
      'vitals-${patient.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

  @override
  State<VitalsSheet> createState() => _VitalsSheetState();
}

class _VitalsSheetState extends State<VitalsSheet> {
  late final Map<Measure, TextEditingController> _c = {
    for (final m in widget.measures) m: TextEditingController()
  };
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    widget.drafts.read(widget.draftKey).then((d) {
      if (!mounted) return;
      for (final e in d.entries) {
        final m = Measure.values.where((m) => m.name == e.key);
        if (m.isNotEmpty) _c[m.first]?.text = e.value;
      }
      setState(() => _restored = d.isNotEmpty);
    });
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _draft() => widget.drafts.write(widget.draftKey, {
        for (final e in _c.entries)
          if (e.value.text.trim().isNotEmpty) e.key.name: e.value.text.trim()
      });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Glass(
        depth: Depth.high,
        radius: Radius2.sheet,
        padding: const EdgeInsets.all(Gap.l),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(Strings.recordVitals,
                  style: Type.headline.copyWith(color: p.textPrimary)),
              if (_restored)
                Padding(
                  padding: const EdgeInsets.only(top: Gap.xs),
                  child: Text(Strings.draftRestored,
                      style: Type.small.copyWith(color: p.textSecondary),
                      key: const Key('draftRestored')),
                ),
              const SizedBox(height: Gap.m),
              Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [
                  for (final m in widget.measures)
                    SizedBox(
                      width: 150,
                      child: TextField(
                        key: Key('field-${m.name}'),
                        controller: _c[m],
                        onChanged: (_) => _draft(),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                        ],
                        style: Type.body.copyWith(color: p.textPrimary),
                        decoration: InputDecoration(
                            labelText: m.label,
                            suffixText: m.unit,
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(Radius2.input))),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Gap.l),
              PrimaryButton(label: Strings.recordVitals, onPressed: _record),
              const SizedBox(height: Gap.s),
              SecondaryButton(
                  label: Strings.cancel,
                  onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }

  /// "37.5" in a tenths measure is 375; "3.25" in grams is 3250.
  static int? parse(String text, Measure m) {
    final t = text.trim();
    if (t.isEmpty) return null;
    final d = double.tryParse(t);
    if (d == null) return null;
    return (d * m.perUnit).round();
  }

  Future<void> _record() async {
    final facts = <Fact>[];
    for (final e in _c.entries) {
      final v = parse(e.value.text, e.key);
      if (v == null) continue;
      facts.add(Fact(
          id: widget.ids.fact(),
          patient: widget.patient,
          kind: FactKind.vitals,
          stamp: widget.ids.stamp(),
          author: widget.author,
          payload: Observation(
                  measure: e.key, value: v, takenMinutes: widget.nowMinutes)
              .encode(),
          supersedes: null));
    }
    if (facts.isEmpty) return;
    await widget.records.record(facts);
    await widget.drafts.clear(widget.draftKey);
    if (mounted) Navigator.of(context).pop();
  }
}
