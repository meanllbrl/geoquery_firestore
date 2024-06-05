import 'package:dart_geohash/dart_geohash.dart';
import 'package:test/test.dart';
import 'package:geoquery_firestore/src/enums/enums.dart';
import 'package:geoquery_firestore/src/models/latlng_bounds.dart';
import 'package:latlong2/latlong.dart';
import 'package:geoquery_firestore/src/services/geohash_generating_service.dart';

void main() {
  group("GeoQueryGeohashService", () {
    final LatLng testCenterPoint = LatLng(38.4710, 27.2177); //izmir
    final GeohashGeneratingService geoQueryGeohashService =
        GeohashGeneratingService(centerPoint: testCenterPoint);
    group("getSurroundingGeohashes", () {
      test("returns correct geohashes for km20 range", () {
        final geohashes = geoQueryGeohashService
            .getSurroundingGeohashes(GeoQueryFirestoreRanges.km20);
        print(geohashes);
        expect(
            geohashes
                .toSet()
                .containsAll({"swg7", "swgd", "swg6", "swg3", "swg4", "swg5"}),
            isTrue); // 1 center + 8 surrounding
      });

      test('includes center geohash', () {
        final geohashes = geoQueryGeohashService
            .getSurroundingGeohashes(GeoQueryFirestoreRanges.km20);
        final centerGeohash = GeoHash.fromDecimalDegrees(
                testCenterPoint.longitude, testCenterPoint.latitude,
                precision: 4)
            .geohash;
        expect(geohashes.contains(centerGeohash), isTrue);
      });

      test("Gives error missing custom range", () {
        void geohashes() => geoQueryGeohashService.getSurroundingGeohashes(
            GeoQueryFirestoreRanges.custom,
            customRangeInMeters: null);
        expect(geohashes, throwsA(isException));
      });

      test("Setting custom range", () {
        final geohashes = geoQueryGeohashService.getSurroundingGeohashes(
            GeoQueryFirestoreRanges.custom,
            customRangeInMeters: 80000);
        final geohashes2 = geoQueryGeohashService.getSurroundingGeohashes(
          GeoQueryFirestoreRanges.km80,
        );
        expect(geohashes.toSet().containsAll(geohashes2), isTrue);
      });
    });

    group("getCompleteGeohashesByLatLngBounds", () {
      test('returns non-empty set', () {
        final bounds = LatLngBounds(
          LatLng(37.7749, -122.4194),
          LatLng(37.7740, -122.4195),
        );
        final geohashes = geoQueryGeohashService.getGeohashesByBounds(bounds);
        print(geohashes);
        expect(geohashes.isNotEmpty, isTrue);
      });

      test('returns correct number of geohashes', () {
        final bounds = LatLngBounds(
          LatLng(37.7749, -122.4194),
          LatLng(37.7740, -122.4195),
        );
        final geohashes = geoQueryGeohashService.getGeohashesByBounds(bounds);
        expect(geohashes.length <= 20, isTrue);
      });

      test('returns correct geohashes', () {
        final bounds = LatLngBounds(
          LatLng(38.49601, 27.07048),
          LatLng(38.3204, 27.4217),
        );
        final geohashes =
            geoQueryGeohashService.getGeohashesByBounds(bounds, strict: true);
        print(geohashes);
        print(geohashes.length);
        expect(
            geohashes.containsAll([
              "swg6e",
              "swg6s",
              "swg67",
              "swg6k",
              "swg6d",
              "swg66",
              "swg6t",
              "swg6m"
            ]),
            isTrue);
      });
    });
  });
}
