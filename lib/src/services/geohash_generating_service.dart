// ignore_for_file: depend_on_referenced_packages

import 'package:geoquery_firestore/src/constants.dart';
import 'package:geoquery_firestore/src/enums/enums.dart';
import 'package:geoquery_firestore/src/models/geohash_details.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:geoquery_firestore/src/models/latlng_bounds.dart';
import 'package:latlong2/latlong.dart';

/// Service class for geohash operations related to GeoQuery.
class GeohashGeneratingService {
  /// The central geographical point of interest.
  final LatLng centerPoint;

  /// Static map containing geohash details for different ranges.
  static final Map<GeoQueryFirestoreRanges, GeoQueryFirestoreGeohashDetails>
      geohashData = GeoQueryFirestoreGeohashDetails.geohashData;

  /// Constructs a `GeoQueryGeohashService` instance.
  ///
  /// Args:
  ///   * `centerPoint` (required): The central `LatLng` representing the area.
  GeohashGeneratingService({required this.centerPoint});

  /// Retrieves a list of geohashes surrounding the center point within the specified range.
  ///
  /// This function utilizes the provided range details (precision and length in
  /// meters) to calculate surrounding points and generate their corresponding geohashes.
  ///
  /// Args:
  ///   * `selectedRange` (GeoQueryFirestoreRanges): The desired geohash range.
  ///
  /// Returns:
  ///   (List<String>): A list of `String` geohashes covering the area around the center point.
  List<String> getSurroundingGeohashes(GeoQueryFirestoreRanges selectedRange,
      {double? customRangeInMeters}) {
    if (selectedRange == GeoQueryFirestoreRanges.custom &&
        customRangeInMeters == null) {
      throw Exception(
          "If you set `selectedRange` = `GeoQueryFirestoreRanges.custom`, You Need To Define `customRange` ");
    }
    final latitude = centerPoint.latitude;
    final longitude = centerPoint.longitude;

    GeoQueryFirestoreGeohashDetails selectedDetails;
    if (selectedRange == GeoQueryFirestoreRanges.custom) {
      selectedDetails = _determineBestGeoQueryFirestoreGeohashDetailsForRadius(
          customRangeInMeters!);
    } else {
      selectedDetails = geohashData[selectedRange]!;
    }

    final precision = selectedDetails.precision;
    final distanceInMeters = selectedDetails.radiusInMeters;

    final centerGeohash =
        GeoHash.fromDecimalDegrees(longitude, latitude, precision: precision);

    // Calculate surrounding points at 45-degree intervals
    final surroundingPoints =
        _calculateSurroundingPoints(distanceInMeters, centerPoint);

    // Generate geohashes for each surrounding point
    final geohashes = surroundingPoints.map((point) {
      return GeoHash.fromDecimalDegrees(point.longitude, point.latitude,
              precision: precision)
          .geohash;
    }).toList();

    // Include the center point geohash as well
    geohashes.insert(0, centerGeohash.geohash);

    // Return the unique geohashes as a list
    return geohashes.toSet().toList();
  }

  /// Calculates a list of `LatLng` points surrounding the center at 45-degree intervals.
  ///
  /// This function uses the `Distance` class to calculate points at a specified
  /// distance from the center point in eight directions (every 45 degrees).
  ///
  /// Args:
  ///   * `distanceInMeter` (double): The distance in meters from the center point.
  ///   * `center` (LatLng): The central geographical point.
  ///
  /// Returns:
  ///   (List<LatLng>): A list of `LatLng` points surrounding the center.
  List<LatLng> _calculateSurroundingPoints(
      double distanceInMeter, LatLng center) {
    const distanceCalculator = Distance();
    final surroundingPoints = <LatLng>[];

    for (var degree = 0; degree < 360; degree += 36) {
      // Use 36-degree intervals
      final point = distanceCalculator.offset(center, distanceInMeter, degree);
      surroundingPoints.add(point);
    }

    return surroundingPoints;
  }

  /// Calculates a set of geohashes that entirely cover the provided `LatLngBounds`.
  ///
  /// This function uses a hierarchical approach to determine geohashes with
  /// appropriate precision to encompass the entire area.
  ///
  /// Args:
  ///   * `mapBounds`: The `LatLngBounds` representing the area of interest.
  ///   * `strict` (optional): A flag indicating whether to strictly filter
  ///     geohashes within the bounds. Defaults to `false`.
  ///
  /// Returns:
  ///   A set of `String` geohashes covering the `mapBounds`. The set size is
  ///   limited to `Constants.mapBoundGeohashLimit` if exceeded.
  Set<String> getGeohashesByBounds(LatLngBounds mapBounds,
      {bool strict = false}) {
    // Calculate the center of the bounds.
    final center = LatLng(
      (mapBounds.north + mapBounds.south) / 2,
      (mapBounds.east + mapBounds.west) / 2,
    );

    // Calculate the area of the bounds.
    final area = _calculateAreaOfLatLngBounds(mapBounds);

    // Determine the optimal geohash precision for the area.
    final bestPrecision = _determineBestPrecisionForAreas(area);

    // Get the geohash for the center point with the best precision.
    final centerHash = GeoHash.fromDecimalDegrees(
        center.longitude, center.latitude,
        precision: bestPrecision);

    // Start with the center geohash and include its neighbors.
    final hashSet = centerHash.neighbors.values.toSet()
      ..add(centerHash.geohash);

    // Explore surrounding points in decreasing distances for additional coverage.
    for (var distanceMultiplier in [8, 4, 3, 2, 1.5, 1.25, 1]) {
      final distance =
          Distance().as(LengthUnit.Meter, center, mapBounds.northWest) /
              distanceMultiplier;
      final calculatedCoordinates =
          _calculateSurroundingPoints(distance, center);

      // Optionally filter points outside the bounds for stricter coverage.
      if (strict) {
        calculatedCoordinates.removeWhere((point) =>
            !(point.latitude > mapBounds.south &&
                point.latitude < mapBounds.north &&
                point.longitude > mapBounds.west &&
                point.longitude < mapBounds.east));
      }

      // Generate geohashes for the surrounding points with the best precision.
      final nearGeohashes = calculatedCoordinates
          .map((point) => GeoHash.fromDecimalDegrees(
              point.longitude, point.latitude,
              precision: bestPrecision))
          .map((geohash) => geohash.geohash)
          .toSet();

      // Add these geohashes to the set.
      hashSet.addAll(nearGeohashes);
    }

    // Limit the set size if exceeding the defined limit.
    return hashSet.length > Constants.mapBoundGeohashLimit
        ? hashSet.take(Constants.mapBoundGeohashLimit).toSet()
        : hashSet;
  }

  /// Determines the optimal geohash precision for covering a given area.
  ///
  /// This function selects the geohash precision that offers the closest area
  /// to an ideal size (one-ninth of the provided area) while maintaining a
  /// maximum error tolerance of 25%.
  ///
  /// Args:
  ///   * `area` (double): The area in square meters to be covered by geohashes.
  ///
  /// Returns:
  ///   (int): The most suitable geohash precision for the given area.
  int _determineBestPrecisionForAreas(double area) {
    // Sort geohash options by their closeness to the ideal area per geohash.
    final geohashOptions = geohashData.values.toList()
      ..sort((a, b) {
        final idealArea = area / 9; // Ideal area if divided into 9 parts
        return (idealArea - a.areaInSquareMeters)
            .abs()
            .compareTo((idealArea - b.areaInSquareMeters).abs());
      });

    // Start with the highest precision (smallest geohash).
    var bestPrecision = geohashOptions.first.precision;

    // Check if a less precise option offers sufficient coverage with low error.
    if (bestPrecision > 1) {
      final nextPrecision = bestPrecision - 1;
      final nextPrecisionArea = geohashData[
                  GeoQueryFirestoreGeohashDetails.precisionToRange(
                      nextPrecision)]!
              .areaInSquareMeters *
          9;
      final errorPercentage = (area / nextPrecisionArea - 1).abs();
      if (errorPercentage <= 0.25) {
        bestPrecision = nextPrecision;
      }
    }

    return bestPrecision;
  }

  /// Determines the optimal geohash precision for covering a given radius.
  ///
  /// This function selects the geohash precision that offers the closest area
  /// to an ideal size (one-ninth of the provided area) while maintaining a
  /// maximum error tolerance of 25%.
  ///
  /// Args:
  ///   * `radiusInMeters` (double): The area in square meters to be covered by geohashes.
  ///
  /// Returns:
  ///   (GeoQueryFirestoreGeohashDetails): The most suitable GeoQueryFirestoreGeohashDetails
  GeoQueryFirestoreGeohashDetails
      _determineBestGeoQueryFirestoreGeohashDetailsForRadius(
          double radiusInMeters) {
    // Sort geohash options by their closeness to the ideal area per geohash.
    final geohashOptions = geohashData.values.toList()
      ..sort((a, b) {
        return (radiusInMeters - a.radiusInMeters)
            .abs()
            .compareTo((radiusInMeters - b.radiusInMeters).abs());
      });

    return geohashOptions.first;
  }

  /// Calculates the area of the provided `LatLngBounds` in square meters.
  ///
  /// This function uses the distance calculator to determine the width and
  /// height of the bounds and multiplies them to get the total area.
  ///
  /// Args:
  ///   * `bounds` (LatLngBounds): The geographical bounding box.
  ///
  /// Returns:
  ///   (double): The area of the `LatLngBounds` in square meters.
  double _calculateAreaOfLatLngBounds(LatLngBounds bounds) {
    const distance = Distance();
    final width =
        distance.as(LengthUnit.Meter, bounds.southEast, bounds.southWest);
    final height =
        distance.as(LengthUnit.Meter, bounds.southEast, bounds.northEast);
    return width * height;
  }
}
