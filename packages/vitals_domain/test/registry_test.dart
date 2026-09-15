// The registry: a registration round-trips, Nigerian names fold to one key
// across their spellings, a search finds by name or phone, and a duplicate
// is a candidate with its reasons — twins stay two.
import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

import 'sample.dart';

Registration reg(String given, String family, {String other = '', int born = 19_000, String mother = '', String phone = '', bool est = false}) => Registration(
      givenName: given,
      familyName: family,
      otherNames: other,
      sex: 0,
      bornDays: born,
      dobEstimated: est,
      motherName: mother,
      phone: phone,
      address: '12 Herbert Macaulay Way',
    );

Record recordOf(int p, Registration r) => Record.of(patientId(p), [
      Fact(id: id(p), patient: patientId(p), kind: FactKind.registration, stamp: Stamp(wallMillis: 1000 + p, counter: 0, device: 'tab'), author: 'nurse', payload: r.encode(), supersedes: null),
    ]);

void main() {
  test('a registration round-trips, tone marks and all', () {
    final r = reg('Adéọlá', 'Ọlátúnjí', other: 'Chukwuemeka', born: -3_000, mother: 'Fúnmiláyọ̀', phone: '0803 123 4567', est: true);
    final back = Registration.decode(r.encode());
    expect(back.fullName, 'Adéọlá Chukwuemeka Ọlátúnjí');
    expect((back.bornDays, back.dobEstimated, back.motherName, back.phone), (-3_000, true, 'Fúnmiláyọ̀', '0803 123 4567'));
    expect(Registration.of(recordOf(1, r).current)?.givenName, 'Adéọlá');
    expect(Registration.of(const []), isNull);
  });

  test('names that are one sound have one key', () {
    for (final (a, b) in [
      ('Adeola', 'Adéọlá'),
      ('Oluwaseun', 'Seun'),
      ('Chukwuemeka', 'Emeka'),
      ('Muhammad', 'Mohammed'),
      ('Muhammed', 'Mohamed'),
      ('Ngozi', 'Ngozi'),
      ('Yusuf', 'Yusuff'),
      ('Philip', 'Filip'),
      ('Shola', 'Sola'),
      ('Okafor', 'Okafor'),
    ]) {
      expect(Names.key(a), Names.key(b), reason: '$a vs $b');
    }
    expect(Names.key('Adeola'), isNot(Names.key('Adebola')), reason: 'different names stay different');
    expect(Names.key('Okafor'), isNot(Names.key('Okeke')));
    expect(Names.tokens('Ade-Ola  Bamisaye'), ['adeola', 'bamisaye']);
  });

  test('search finds by any spelling, by every token, and by phone', () {
    final listed = Registry.list([
      recordOf(1, reg('Adeola', 'Okafor', phone: '08031234567', mother: 'Ngozi Okafor')),
      recordOf(2, reg('Oluwaseun', 'Bamisaye', phone: '07011112222')),
      recordOf(3, reg('Emeka', 'Okeke')),
    ]);
    expect(Registry.search(listed, 'adéọlá').map((h) => h.listed.registration.givenName), ['Adeola']);
    expect(Registry.search(listed, 'seun').map((h) => h.listed.registration.givenName), ['Oluwaseun']);
    expect(Registry.search(listed, 'chukwuemeka okeke').map((h) => h.listed.registration.givenName), ['Emeka']);
    expect(Registry.search(listed, 'adeola okeke'), isEmpty, reason: 'every token must match one patient');
    expect(Registry.search(listed, '1234').map((h) => h.listed.registration.givenName), ['Adeola']);
    expect(Registry.search(listed, 'ngozi').map((h) => h.listed.registration.givenName), ['Adeola'], reason: 'the mother finds the child');
    expect(Registry.search(listed, ''), isEmpty);
    expect(Registry.search(listed, 'ok').length, 2, reason: 'a prefix finds both Okafor and Okeke');
  });

  test('a duplicate is a candidate with reasons, and twins are two', () {
    final listed = Registry.list([
      recordOf(1, reg('Adeola', 'Okafor', born: 19_000, mother: 'Ngozi', phone: '0803')),
      recordOf(2, reg('Taiwo', 'Okafor', born: 19_000, mother: 'Ngozi', phone: '0803')),
      recordOf(3, reg('Kehinde', 'Okafor', born: 19_000, mother: 'Ngozi', phone: '0803')),
    ]);
    final again = Listed(patientId(9), reg('Adéọlá', 'Okafor', born: 19_200, mother: 'Ngozi'));
    final c = Registry.duplicates(listed, again);
    expect(c.length, 1, reason: 'only Adeola, not the twins');
    expect(c.single.a.registration.givenName, 'Adeola');
    expect(c.single.reasons, ['same name, born within a year', 'same name and mother']);
    final twin = Listed(patientId(8), reg('Kehinde', 'Okafor', born: 19_000, mother: 'Ngozi', phone: '0803'));
    final t = Registry.duplicates(listed, twin);
    expect(t.map((x) => x.a.registration.givenName), ['Kehinde'], reason: 'the twin matches only themself, never Taiwo');
    expect(Registry.duplicates(listed, listed.first), isEmpty, reason: 'a patient is not their own duplicate');
  });
}
