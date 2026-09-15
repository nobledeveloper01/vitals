// The FHIR bundle: a Patient, an Immunization per dose with its CVX code,
// an Observation per vital with LOINC and UCUM, a laboratory Observation
// as a quantity or as text — and no interpretation element anywhere.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/report/fhir.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  test('a record becomes a bundle an importer can read', () {
    final patient = List<int>.generate(16, (i) => i + 1);
    var n = 0;
    Fact f(FactKind k, List<int> payload) => Fact(
        id: List.filled(32, ++n),
        patient: patient,
        kind: k,
        stamp: Stamp(wallMillis: n * 1000, counter: 0, device: 'a'),
        author: 'nurse',
        payload: payload,
        supersedes: null);
    final born = Gs1.daysOf(2026, 1, 1);
    final record = Record.of(patient, [
      f(
          FactKind.registration,
          Registration(
                  givenName: 'Ada',
                  familyName: 'Eze',
                  sex: 0,
                  bornDays: born,
                  dobEstimated: true,
                  phone: '0803')
              .encode()),
      f(
          FactKind.immunisation,
          Given(
                  vaccine: Vaccine.penta,
                  dose: 2,
                  givenDays: born + 70,
                  batch: 'P-9',
                  expiryDays: born + 400)
              .encode()),
      f(
          FactKind.vitals,
          Observation(
                  measure: Measure.temperature,
                  value: 375,
                  takenMinutes: (born + 70) * 1440 + 600)
              .encode()),
      f(
          FactKind.lab,
          LabResult(
                  test: 'Haemoglobin',
                  result: '10.2',
                  unit: 'g/dL',
                  lab: 'LUTH',
                  sampledDays: born + 70,
                  reportedDays: born + 72)
              .encode()),
      f(
          FactKind.lab,
          LabResult(
                  test: 'HIV',
                  result: 'non-reactive',
                  sampledDays: born + 70,
                  reportedDays: born + 72)
              .encode()),
      f(FactKind.note, const Note(text: 'private').encode()),
    ]);
    final bundle = Fhir.bundle(record, facility: 'Ikeja PHC');
    expect(bundle['resourceType'], 'Bundle');
    final entries = (bundle['entry'] as List).cast<Map<String, Object?>>();
    final resources =
        entries.map((e) => e['resource'] as Map<String, Object?>).toList();
    expect(resources.map((r) => r['resourceType']), [
      'Patient',
      'Immunization',
      'Observation',
      'Observation',
      'Observation'
    ]);
    final p = resources[0];
    expect(p['birthDate'], '2026-01-01');
    expect(p['gender'], 'female');
    expect((p['name'] as List).first, {
      'family': 'Eze',
      'given': ['Ada']
    });
    final imm = resources[1];
    expect(((imm['vaccineCode'] as Map)['coding'] as List).first,
        {'system': 'http://hl7.org/fhir/sid/cvx', 'code': '198'});
    expect(imm['lotNumber'], 'P-9');
    expect(
        ((imm['protocolApplied'] as List).first
            as Map)['doseNumberPositiveInt'],
        2);
    final temp = resources[2];
    expect(((temp['code'] as Map)['coding'] as List).first, {
      'system': 'http://loinc.org',
      'code': '8310-5',
      'display': 'Body temperature'
    });
    expect(temp['valueQuantity'], {
      'value': 37.5,
      'unit': '°C',
      'system': 'http://unitsofmeasure.org',
      'code': 'Cel'
    });
    expect(resources[3]['valueQuantity'], {'value': 10.2, 'unit': 'g/dL'});
    expect(resources[4]['valueString'], 'non-reactive');
    final json = jsonEncode(bundle);
    expect(json, isNot(contains('private')), reason: 'notes are not exported');
    expect(json, isNot(contains('interpretation')));
    expect(json, isNot(contains('referenceRange')));
    // Round-trips through JSON as a document, which is what an importer gets.
    expect(jsonDecode(json), bundle);
  });
}
