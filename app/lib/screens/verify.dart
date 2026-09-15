// Drug verification (ADR-0006 #20): the pack's barcode read by the camera
// — a number printed inside a code, or a GTIN the list knows — or the
// number typed, against the list the phone carries. Three outcomes, three
// sentences, and no fourth word; the list's own date and coverage printed
// so nobody mistakes *not on the list* for more than it says.
import 'package:flutter/material.dart' hide Card;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vitals_domain/vitals_domain.dart';

import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/patient_strings.dart';
import '../store/http_transport.dart';
import '../store/preferences.dart';
import '../store/sync.dart';

/// The bundled list: a sample until NAFDAC's published register is loaded
/// as data with its date. The prefixes it covers are declared with it.
abstract final class BundledList {
  static const String dated = '2026-09';
  static const Set<String> covered = {'A4', '04', 'B4'};

  /// Barcodes the list knows, to their numbers.
  static const Map<String, String> gtins = {
    '05012345678900': 'A4-1234',
    '05012345678917': '04-0567',
  };
  static const Map<String, String> numbers = {
    'A4-1234': 'Paracetamol 500 mg tablets',
    'A4-2001': 'Artemether/Lumefantrine 20/120 tablets',
    '04-0567': 'Amoxicillin 250 mg capsules',
    '04-0890': 'Oral rehydration salts',
    'B4-0042': 'Zinc 20 mg dispersible tablets',
  };
}

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key, this.camera = true, this.report});

  /// False where there is no camera (a test): the field alone.
  final bool camera;

  /// Where a not-on-the-list report goes: the enrolled replica over HTTP,
  /// or nowhere when none is enrolled; a test hands one in.
  final Transport? report;

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _text = TextEditingController();
  Verification? _result;
  late final MobileScannerController? _camera =
      widget.camera ? MobileScannerController() : null;
  bool _reported = false;

  Transport? get _transport {
    if (widget.report != null) return widget.report;
    final url = Uri.tryParse(Preferences.shared.replicaUrl);
    return url == null || !url.hasScheme ? null : HttpTransport(url);
  }

  /// The report carries the number, the product the list knows for its
  /// prefix if any, and the facility — never a patient, because none is
  /// involved in checking a pack.
  Future<void> _report() async {
    final r = _result;
    final t = _transport;
    if (r == null || t == null) return;
    try {
      await t.postJson('/reports/counterfeit', {
        'facility': Preferences.shared.facilityName,
        'product': r.product.isEmpty ? r.number.substring(0, 2) : r.product,
        'number': r.number,
      });
      if (mounted) setState(() => _reported = true);
    } catch (_) {
      // Offline: the report waits for a hand that tries again.
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _text.dispose();
    super.dispose();
  }

  /// What a scan or the field gives: the number if one is printed in it,
  /// else the GTIN if the list knows it.
  void _check(String raw) =>
      setState(() => _result = Verify.check(Verify.numberIn(raw),
          list: BundledList.numbers,
          covered: BundledList.covered,
          gtins: BundledList.gtins,
          gtin: Verify.gtinIn(raw)));

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final r = _result;
    return Scaffold(
      body: Mesh(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(Gap.l),
            children: [
              const Align(
                  alignment: Alignment.centerLeft, child: BackButton2()),
              Text(PatientStrings.t('checkAPack'),
                  style: Type.display.copyWith(color: p.textPrimary)),
              const SizedBox(height: Gap.xs),
              Text(
                  '${PatientStrings.t('listDated')} ${BundledList.dated} · ${PatientStrings.t('listCovers')} ${BundledList.covered.join(', ')}',
                  style: Type.small.copyWith(color: p.textSecondary)),
              const SizedBox(height: Gap.m),
              if (widget.camera) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radius2.card),
                  child: SizedBox(
                    height: 220,
                    child: MobileScanner(
                      controller: _camera,
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
                            style: Type.body.copyWith(color: p.textSecondary)),
                      ),
                      onDetect: (capture) {
                        for (final b in capture.barcodes) {
                          final v = b.rawValue;
                          if (v != null && v != _text.text) {
                            _text.text = v;
                            _check(v);
                          }
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: Gap.m),
              ],
              Glass(
                depth: Depth.low,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      key: const Key('packText'),
                      controller: _text,
                      onChanged: (_) => setState(() => _result = null),
                      style: Type.body.copyWith(color: p.textPrimary),
                      decoration: InputDecoration(
                          labelText: PatientStrings.t('nafdacNumber'),
                          helperText: PatientStrings.t('nafdacHint'),
                          helperMaxLines: 2,
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(Radius2.input))),
                    ),
                    const SizedBox(height: Gap.m),
                    PrimaryButton(
                        label: PatientStrings.t('check'),
                        onPressed: () => _check(_text.text)),
                  ],
                ),
              ),
              if (r != null) ...[
                const SizedBox(height: Gap.m),
                _OutcomeCard(result: r),
                if (r.outcome == Outcome.notOnTheList &&
                    _transport != null) ...[
                  const SizedBox(height: Gap.s),
                  SecondaryButton(
                      label: PatientStrings.t('reportIt'),
                      onPressed: _reported ? null : _report),
                  if (_reported) ...[
                    const SizedBox(height: Gap.s),
                    Text(PatientStrings.t('reportKept'),
                        style: Type.secondary.copyWith(color: p.textSecondary),
                        key: const Key('reportKept')),
                  ],
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.result});
  final Verification result;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final (icon, colour, headline, body) = switch (result.outcome) {
      Outcome.onTheList => (
          Icons.list_alt,
          p.fine,
          PatientStrings.t('onTheList'),
          '${result.number} · ${result.product}\n${PatientStrings.t('onTheListMeans')}'
        ),
      Outcome.notOnTheList => (
          Icons.help_outline,
          p.attention,
          PatientStrings.t('notOnTheList'),
          '${result.number}\n${PatientStrings.t('notOnTheListMeans')}'
        ),
      Outcome.cannotSay => (
          Icons.remove_circle_outline,
          p.textSecondary,
          PatientStrings.t('cannotSay'),
          PatientStrings.t('cannotSayMeans')
        ),
    };
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$headline. $body',
      child: Glass(
        depth: Depth.low,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: colour),
              const SizedBox(width: Gap.s),
              Expanded(
                  child: Text(headline,
                      style: Type.headline.copyWith(color: colour),
                      key: const Key('outcome'))),
            ]),
            const SizedBox(height: Gap.s),
            Text(body, style: Type.body.copyWith(color: p.textPrimary)),
          ],
        ),
      ),
    );
  }
}
