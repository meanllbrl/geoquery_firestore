import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/test.dart';
import 'package:geoquery_firestore/geoquery_firestore.dart';

void main() {
  test('GeoQueryFirestore initializes correctly', () {
    var query = FirebaseFirestore.instance.collection('test');
    var geoQuery = GeoQueryFirestore(query: query, geohashFieldPath: 'location.geohash');

    expect(geoQuery, isNotNull);
  });
}
