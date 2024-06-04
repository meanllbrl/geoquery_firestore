import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoquery_firestore/geoquery_firestore.dart';

void main() async {
  GeoQueryFirestore geoQuery = GeoQueryFirestore(
    query: FirebaseFirestore.instance.collection('your_collection').where('your_field', isEqualTo: 'your_value'),
    geohashFieldPath: 'location.geohash',
  );

  // Range query example
  List<DocumentSnapshot> rangeDocuments = await geoQuery.queryByRange(range: 10);
  print('Documents in range: ${rangeDocuments.length}');

  // Paging example
  List<DocumentSnapshot> pagedDocuments = await geoQuery.loadMore();
  print('Documents loaded: ${pagedDocuments.length}');

  // Map bounds example
  dynamic yourMapBounds = {}; // Define your map bounds
  List<DocumentSnapshot> mapBoundDocuments = await geoQuery.queryByMapBounds(bounds: yourMapBounds);
  print('Documents in map bounds: ${mapBoundDocuments.length}');
}
