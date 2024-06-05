import 'package:geoquery_firestore/src/enums/enums.dart';

/// A class representing geohash details such as precision, area, and length in meters.
class GeoQueryFirestoreGeohashDetails {
  final int precision;
  final double areaInSquareMeters;
  final double lengthInMeters;

  const GeoQueryFirestoreGeohashDetails({
    required this.precision,
    required this.lengthInMeters,
    required this.areaInSquareMeters,
  });

  /// A static, final map containing geohash details for various ranges.
  static final Map<GeoQueryFirestoreRanges, GeoQueryFirestoreGeohashDetails> geohashData = {
    GeoQueryFirestoreRanges.km2500: GeoQueryFirestoreGeohashDetails(
        precision: 1, areaInSquareMeters: 25000000000000, lengthInMeters: 2500000),
    GeoQueryFirestoreRanges.km630: GeoQueryFirestoreGeohashDetails(
        precision: 2, areaInSquareMeters: 781250000000, lengthInMeters: 630000),
    GeoQueryFirestoreRanges.km80: GeoQueryFirestoreGeohashDetails(
        precision: 3, areaInSquareMeters: 24336000000, lengthInMeters: 80000),
    GeoQueryFirestoreRanges.km20: GeoQueryFirestoreGeohashDetails(
        precision: 4, areaInSquareMeters: 763050000, lengthInMeters: 20000),
    GeoQueryFirestoreRanges.km2: GeoQueryFirestoreGeohashDetails(
        precision: 5, areaInSquareMeters: 23920000, lengthInMeters: 2400),
    GeoQueryFirestoreRanges.m600: GeoQueryFirestoreGeohashDetails(
        precision: 6, areaInSquareMeters: 744200, lengthInMeters: 610),
    GeoQueryFirestoreRanges.m80: GeoQueryFirestoreGeohashDetails(
        precision: 7, areaInSquareMeters: 23409, lengthInMeters: 76),
    GeoQueryFirestoreRanges.m20: GeoQueryFirestoreGeohashDetails(
        precision: 8, areaInSquareMeters: 728.62, lengthInMeters: 19),
  };

  /// Returns the geohash precision for a given range.
  static int rangeToPrecision(GeoQueryFirestoreRanges range) =>
      geohashData[range]!.precision;

  /// Returns the geohash range for a given precision.
  static GeoQueryFirestoreRanges precisionToRange(int precision) =>
      geohashData.entries.firstWhere((entry) => entry.value.precision == precision).key;
}
