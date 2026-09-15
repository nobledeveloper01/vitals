// FHIR export (Phase 7): a record as an R4 Bundle — Patient, Immunization,
// Observation for vitals and laboratory results — so a programme's own
// system can import it. Codes are a table, not knowledge: CVX for the
// vaccines, LOINC for the measures, UCUM for the units, and where a code
// is not in the table the text is carried with no code, which FHIR allows
// and the importer can see. Nothing here interprets: no interpretation
// element is ever written.
import 'package:vitals_domain/vitals_domain.dart';

abstract final class Fhir {
  /// CVX codes for the schedule's vaccines, from CDC's published table.
  static const Map<Vaccine, String> cvx = {
    Vaccine.bcg: '19',
    Vaccine.hepB0: '08',
    Vaccine.opv: '02',
    Vaccine.penta: '198',
    Vaccine.pcv: '133',
    Vaccine.rota: '116',
    Vaccine.ipv: '10',
    Vaccine.measles: '05',
    Vaccine.yellowFever: '37',
    Vaccine.menA: '167',
  };

  /// LOINC codes and UCUM units for the measures.
  static const Map<Measure, (String code, String display, String ucum)> loinc =
      {
    Measure.systolic: ('8480-6', 'Systolic blood pressure', 'mm[Hg]'),
    Measure.diastolic: ('8462-4', 'Diastolic blood pressure', 'mm[Hg]'),
    Measure.pulse: ('8867-4', 'Heart rate', '/min'),
    Measure.temperature: ('8310-5', 'Body temperature', 'Cel'),
    Measure.respiratory: ('9279-1', 'Respiratory rate', '/min'),
    Measure.spo2: (
      '59408-5',
      'Oxygen saturation in Arterial blood by Pulse oximetry',
      '%'
    ),
    Measure.weight: ('29463-7', 'Body weight', 'kg'),
    Measure.height: ('8302-2', 'Body height', 'cm'),
    Measure.muac: ('56072-2', 'Circumference Mid upper arm', 'cm'),
    Measure.fundalHeight: (
      '11881-0',
      'Uterus Fundal height Tape measure',
      'cm'
    ),
    Measure.fetalHeart: ('55283-6', 'Fetal Heart rate', '/min'),
  };

  static Map<String, Object?> bundle(Record record,
      {required String facility}) {
    final patientId = _hex(record.patient);
    final current = record.current;
    final reg = Registration.of(current);
    final entries = <Map<String, Object?>>[];
    if (reg != null) {
      entries.add(_entry('Patient', patientId, {
        'resourceType': 'Patient',
        'id': patientId,
        'name': [
          {
            'family': reg.familyName,
            'given': [
              reg.givenName,
              if (reg.otherNames.isNotEmpty) reg.otherNames
            ],
          }
        ],
        'gender': switch (reg.sex) {
          0 => 'female',
          1 => 'male',
          _ => 'unknown'
        },
        'birthDate': _date(reg.bornDays),
        if (reg.dobEstimated)
          'extension': [
            {
              'url': 'https://vitals.ng/fhir/birthDate-estimated',
              'valueBoolean': true,
            }
          ],
        if (reg.phone.isNotEmpty)
          'telecom': [
            {'system': 'phone', 'value': reg.phone}
          ],
        if (reg.address.isNotEmpty)
          'address': [
            {'text': reg.address}
          ],
        'managingOrganization': {'display': facility},
      }));
    }
    var n = 0;
    for (final g in Given.of(current)) {
      final code = cvx[g.vaccine];
      entries.add(_entry('Immunization', '$patientId-imm-${n++}', {
        'resourceType': 'Immunization',
        'status': 'completed',
        'vaccineCode': {
          if (code != null)
            'coding': [
              {'system': 'http://hl7.org/fhir/sid/cvx', 'code': code}
            ],
          'text': g.vaccine.label,
        },
        'patient': {'reference': 'Patient/$patientId'},
        'occurrenceDateTime': _date(g.givenDays),
        if (g.batch.isNotEmpty) 'lotNumber': g.batch,
        if (g.expiryDays > 0) 'expirationDate': _date(g.expiryDays),
        'protocolApplied': [
          {'doseNumberPositiveInt': g.dose}
        ],
      }));
    }
    for (final o in Observation.of(current)) {
      final l = loinc[o.measure];
      entries.add(_entry('Observation', '$patientId-obs-${n++}', {
        'resourceType': 'Observation',
        'status': 'final',
        'category': [
          {
            'coding': [
              {
                'system':
                    'http://terminology.hl7.org/CodeSystem/observation-category',
                'code': 'vital-signs'
              }
            ]
          }
        ],
        'code': {
          if (l != null)
            'coding': [
              {'system': 'http://loinc.org', 'code': l.$1, 'display': l.$2}
            ],
          'text': o.measure.label,
        },
        'subject': {'reference': 'Patient/$patientId'},
        'effectiveDateTime': _minute(o.takenMinutes),
        'valueQuantity': {
          'value': o.value / o.measure.perUnit,
          'unit': o.measure.unit,
          'system': 'http://unitsofmeasure.org',
          if (l != null) 'code': l.$3,
        },
      }));
    }
    for (final r in LabResult.of(current)) {
      final asNumber = double.tryParse(r.result);
      entries.add(_entry('Observation', '$patientId-lab-${n++}', {
        'resourceType': 'Observation',
        'status': 'final',
        'category': [
          {
            'coding': [
              {
                'system':
                    'http://terminology.hl7.org/CodeSystem/observation-category',
                'code': 'laboratory'
              }
            ]
          }
        ],
        'code': {'text': r.test},
        'subject': {'reference': 'Patient/$patientId'},
        'effectiveDateTime': _date(r.sampledDays),
        'issued': '${_date(r.reportedDays)}T00:00:00Z',
        if (r.lab.isNotEmpty)
          'performer': [
            {'display': r.lab}
          ],
        if (asNumber != null)
          'valueQuantity': {'value': asNumber, 'unit': r.unit}
        else
          'valueString': '${r.result} ${r.unit}'.trim(),
      }));
    }
    return {
      'resourceType': 'Bundle',
      'type': 'collection',
      'meta': {'source': 'https://vitals.ng/$facility'},
      'entry': entries,
    };
  }

  static Map<String, Object?> _entry(
          String type, String id, Map<String, Object?> resource) =>
      {
        'fullUrl': 'urn:vitals:$type/$id',
        'resource': {...resource, 'id': id}
      };

  static String _date(int days) {
    final d = DateTime.utc(1970).add(Duration(days: days));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String _minute(int minutes) =>
      DateTime.fromMillisecondsSinceEpoch(minutes * 60000, isUtc: true)
          .toIso8601String();

  static String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
}
