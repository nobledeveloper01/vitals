// The offline facility map (ADR-0006 #18): a bundled list, sorted by
// distance from where the phone is, with no network. The list is a sample
// with its date printed; the position is asked for once and never kept;
// where there is no position, the person picks an area and the distances
// say they are from that area's centre.
import 'dart:math' as math;

final class Facility {
  const Facility(this.name, this.kind, this.lga, this.lat, this.lon);
  final String name;
  final String kind;
  final String lga;
  final double lat, lon;
}

final class Area {
  const Area(this.name, this.lat, this.lon);
  final String name;
  final double lat, lon;
}

abstract final class Facilities {
  static const String dated = '2026-09';

  /// A sample of Lagos facilities with approximate positions; the full
  /// register is loaded as data with its date when a programme hands it over.
  static const List<Facility> all = [
    Facility('Ikeja Primary Health Centre', 'PHC', 'Ikeja', 6.601, 3.351),
    Facility(
        'General Hospital Ikeja', 'General hospital', 'Ikeja', 6.594, 3.353),
    Facility('Lagos University Teaching Hospital', 'Teaching hospital',
        'Mushin', 6.518, 3.354),
    Facility(
        'Gbagada General Hospital', 'General hospital', 'Kosofe', 6.556, 3.389),
    Facility('Isolo General Hospital', 'General hospital', 'Oshodi-Isolo',
        6.535, 3.330),
    Facility('Alimosho General Hospital', 'General hospital', 'Alimosho', 6.605,
        3.257),
    Facility('Ikorodu General Hospital', 'General hospital', 'Ikorodu', 6.618,
        3.508),
    Facility('Onikan Health Centre', 'PHC', 'Lagos Island', 6.443, 3.408),
    Facility('Ajeromi General Hospital', 'General hospital', 'Ajeromi-Ifelodun',
        6.455, 3.339),
    Facility('Randle General Hospital', 'General hospital', 'Surulere', 6.497,
        3.352),
  ];

  static const List<Area> areas = [
    Area('Ikeja', 6.60, 3.35),
    Area('Surulere', 6.50, 3.35),
    Area('Lagos Island', 6.45, 3.40),
    Area('Ikorodu', 6.62, 3.51),
    Area('Alimosho', 6.60, 3.26),
  ];

  /// Great-circle distance in kilometres, on a sphere: a few metres out
  /// over a city, which is what a list sorted by distance needs.
  static double km(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1), dLon = rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * r * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Nearest first, each with its distance.
  static List<(Facility, double)> near(double lat, double lon) {
    final out = [for (final f in all) (f, km(lat, lon, f.lat, f.lon))];
    out.sort((a, b) => a.$2.compareTo(b.$2));
    return out;
  }
}
