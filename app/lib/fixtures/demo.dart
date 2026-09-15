// A synthetic clinic for the screenshots and a demo in a hand: invented
// names, invented dates, nobody's patient. Seeded only under
// --dart-define=VITALS_DEMO=true and only into an empty store.
import 'package:vitals_domain/vitals_domain.dart';

import '../store/ids.dart';
import '../store/preferences.dart';
import '../store/records.dart';

abstract final class Demo {
  static Future<void> seed(Records records) async {
    if (records.all.isNotEmpty) return;
    final ids = Ids(device: 'demo-tablet');
    final today = DateTime.now().toUtc().difference(DateTime.utc(1970)).inDays;
    final nowMinutes = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 60000;
    final facts = <Fact>[];
    Fact f(List<int> patient, FactKind k, List<int> payload,
            {String author = 'nurse-adaeze', int? minutesAgo}) =>
        Fact(
            id: ids.fact(),
            patient: patient,
            kind: k,
            stamp: ids.stamp(
                now: DateTime.now()
                    .toUtc()
                    .subtract(Duration(minutes: minutesAgo ?? 0))),
            author: author,
            payload: payload,
            supersedes: null);

    // Children at the ages the whiteboard needs: one at birth, one behind,
    // two on time, one complete.
    final children = [
      (
        'Ifeoma',
        'Okafor',
        2,
        'Ngozi',
        '08031110001',
        const <(Vaccine, int, int)>[]
      ),
      (
        'Tunde',
        'Balogun',
        130,
        'Bisi',
        '08031110002',
        [(Vaccine.bcg, 1, 1), (Vaccine.opv, 0, 1), (Vaccine.hepB0, 1, 1)]
      ),
      (
        'Amina',
        'Sani',
        75,
        'Hauwa',
        '',
        [
          (Vaccine.bcg, 1, 0),
          (Vaccine.opv, 0, 0),
          (Vaccine.hepB0, 1, 0),
          (Vaccine.opv, 1, 43),
          (Vaccine.penta, 1, 43),
          (Vaccine.pcv, 1, 43),
          (Vaccine.rota, 1, 43),
          (Vaccine.opv, 2, 71),
          (Vaccine.penta, 2, 71),
          (Vaccine.pcv, 2, 71),
          (Vaccine.rota, 2, 71)
        ]
      ),
      (
        'Chukwuemeka',
        'Eze',
        300,
        'Adaobi',
        '08031110004',
        [
          for (final d in Schedule.v1.where((d) => d.dueDays <= 274))
            (d.vaccine, d.dose, d.dueDays + 2)
        ]
      ),
      (
        'Zainab',
        'Bello',
        700,
        'Maryam',
        '08031110005',
        [for (final d in Schedule.v1) (d.vaccine, d.dose, d.dueDays + 1)]
      ),
    ];
    for (final (given, family, ageDays, mother, phone, doses) in children) {
      final p = ids.patient();
      facts.add(f(
          p,
          FactKind.registration,
          Registration(
                  givenName: given,
                  familyName: family,
                  sex: given.endsWith('a') ? 0 : 1,
                  bornDays: today - ageDays,
                  dobEstimated: ageDays > 500,
                  motherName: mother,
                  phone: phone)
              .encode()));
      for (final (v, dose, atDay) in doses) {
        facts.add(f(
            p,
            FactKind.immunisation,
            Given(
                    vaccine: v,
                    dose: dose,
                    givenDays: today - ageDays + atDay,
                    batch: '${v.name.toUpperCase().substring(0, 3)}-26${dose}A',
                    expiryDays: today + 300)
                .encode()));
      }
      if (ageDays > 30) {
        facts.add(f(
            p,
            FactKind.vitals,
            Observation(
                    measure: Measure.weight,
                    value: 3200 + ageDays * 18,
                    takenMinutes: nowMinutes - 60)
                .encode()));
      }
    }
    // A mother in antenatal care, with vitals over three visits.
    final mother = ids.patient();
    facts.add(f(
        mother,
        FactKind.registration,
        Registration(
                givenName: 'Adaobi',
                familyName: 'Eze',
                sex: 0,
                bornDays: today - 365 * 27,
                dobEstimated: false,
                phone: '08031110004')
            .encode()));
    facts.add(f(mother, FactKind.ancVisit,
        Pregnancy(lmpDays: today - 7 * 22, gravida: 2, para: 1).encode()));
    for (final (weeksAgo, sys, dia, pulse) in [
      (8, 112, 72, 78),
      (4, 118, 76, 84),
      (0, 124, 80, 88)
    ]) {
      final at = nowMinutes - weeksAgo * 7 * 1440;
      facts.add(f(
          mother,
          FactKind.vitals,
          Observation(measure: Measure.systolic, value: sys, takenMinutes: at)
              .encode()));
      facts.add(f(
          mother,
          FactKind.vitals,
          Observation(measure: Measure.diastolic, value: dia, takenMinutes: at)
              .encode()));
      facts.add(f(
          mother,
          FactKind.vitals,
          Observation(measure: Measure.pulse, value: pulse, takenMinutes: at)
              .encode()));
      facts.add(f(
          mother,
          FactKind.vitals,
          Observation(
                  measure: Measure.temperature,
                  value: 367 + weeksAgo,
                  takenMinutes: at)
              .encode()));
    }
    facts.add(f(
        mother,
        FactKind.ancVisit,
        AncVisit(
                visitNumber: 1,
                visitDays: today - 56,
                answers: {for (final s in DangerSign.values) s: false},
                notes: 'Booked. Iron and folate given.')
            .encode()));
    facts.add(f(
        mother,
        FactKind.ancVisit,
        AncVisit(
                visitNumber: 2,
                visitDays: today - 28,
                answers: {
                  for (final s in DangerSign.values) s: s == DangerSign.swelling
                },
                notes: 'Mother reports swollen feet in the evenings.')
            .encode()));
    facts.add(f(
        mother,
        FactKind.access,
        Access(
                who: 'nurse-adaeze',
                minutes: nowMinutes - 3000,
                device: 'demo-tablet',
                facility: 'Ikeja PHC')
            .encode()));
    facts.add(f(
        mother,
        FactKind.access,
        Access(
                who: 'nurse-bola',
                minutes: nowMinutes - 400,
                device: 'demo-tablet-2',
                facility: 'Ikeja PHC')
            .encode()));
    // The facility's stock and fridge.
    final facility = Preferences.shared.facilityOrMake(ids.patient);
    for (final (product, units, expiry) in [
      ('BCG', 40, 300),
      ('OPV', 12, 45),
      ('Penta', 60, 400),
      ('PCV', 55, 380),
      ('Rota', 30, 200),
      ('Measles', 25, 500),
      ('Vitamin A', 100, 700),
      ('ORS', 80, 900)
    ]) {
      facts.add(f(
          facility,
          FactKind.stockMovement,
          StockMove(
                  product: product,
                  movement: Movement.receipt,
                  units: units,
                  days: today - 20,
                  batch: '$product-26B',
                  expiryDays: today + expiry)
              .encode(),
          author: 'store-keeper'));
    }
    facts.add(f(
        facility,
        FactKind.stockMovement,
        StockMove(
                product: 'BCG',
                movement: Movement.count,
                units: 37,
                days: today - 3)
            .encode()));
    facts.add(f(facility, FactKind.vitals,
        FridgeReading(tenths: 46, minutes: nowMinutes - 1440 + 60).encode()));
    facts.add(f(facility, FactKind.vitals,
        FridgeReading(tenths: 52, minutes: nowMinutes - 1440 + 600).encode()));
    await records.record(facts);
  }
}
