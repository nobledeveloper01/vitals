// Facilities near me (ADR-0006 #18): the bundled list by distance, from
// the phone's position asked once, or from the centre of an area the
// person picks. No network; the list's date printed.
import 'package:flutter/material.dart' hide Card;
import 'package:geolocator/geolocator.dart';

import '../data/facilities.dart';
import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/patient_strings.dart';

class FacilitiesScreen extends StatefulWidget {
  const FacilitiesScreen({super.key, this.locate});

  /// The phone's position, or null when it cannot say; a test hands one in.
  final Future<(double, double)?> Function()? locate;

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  (double, double)? _here;
  Area? _area;
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    (widget.locate ?? _platform)().then((p) {
      if (!mounted) return;
      setState(() {
        _here = p;
        _asked = true;
      });
    });
  }

  static Future<(double, double)?> _platform() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 8)));
      return (p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final from = _here ?? (_area == null ? null : (_area!.lat, _area!.lon));
    final list = from == null ? null : Facilities.near(from.$1, from.$2);
    return Scaffold(
      body: Mesh(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(Gap.l),
            children: [
              const Align(
                  alignment: Alignment.centerLeft, child: BackButton2()),
              Text(PatientStrings.t('facilitiesNearMe'),
                  style: Type.display.copyWith(color: p.textPrimary)),
              const SizedBox(height: Gap.xs),
              Text(
                  '${PatientStrings.t('listDated')} ${Facilities.dated} · ${PatientStrings.t('facilitiesSample')}',
                  style: Type.small.copyWith(color: p.textSecondary)),
              const SizedBox(height: Gap.m),
              if (_here == null) ...[
                Glass(
                  depth: Depth.low,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          _asked
                              ? PatientStrings.t('noPosition')
                              : PatientStrings.t('askingPosition'),
                          style: Type.body.copyWith(color: p.textPrimary),
                          key: const Key('positionNote')),
                      const SizedBox(height: Gap.s),
                      Wrap(
                        spacing: Gap.s,
                        runSpacing: Gap.s,
                        children: [
                          for (final a in Facilities.areas)
                            ChoiceChip(
                              key: Key('area-${a.name}'),
                              label: Text(a.name),
                              selected: _area == a,
                              selectedColor: p.accent,
                              labelStyle: Type.small.copyWith(
                                  color: _area == a
                                      ? p.textOnAccent
                                      : p.textPrimary),
                              onSelected: (_) => setState(() => _area = a),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Gap.m),
              ],
              if (list != null) ...[
                Text(
                    _here != null
                        ? PatientStrings.t('fromWhereYouAre')
                        : '${PatientStrings.t('fromTheCentreOf')} ${_area!.name}',
                    style: Type.secondary.copyWith(color: p.textSecondary),
                    key: const Key('fromNote')),
                const SizedBox(height: Gap.s),
                for (final (f, km) in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.s),
                    child: Semantics(
                      container: true,
                      excludeSemantics: true,
                      label:
                          '${f.name}, ${f.kind}, ${f.lga}, ${km.toStringAsFixed(1)} km',
                      child: Glass(
                        depth: Depth.low,
                        child: Row(children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f.name,
                                    style: Type.title
                                        .copyWith(color: p.textPrimary)),
                                Text('${f.kind} · ${f.lga}',
                                    style: Type.small
                                        .copyWith(color: p.textSecondary)),
                              ],
                            ),
                          ),
                          Text('${km.toStringAsFixed(1)} km',
                              style:
                                  Type.headline.copyWith(color: p.textPrimary)),
                        ]),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
