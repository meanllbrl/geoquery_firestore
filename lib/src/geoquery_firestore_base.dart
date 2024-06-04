import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/geohash_document.dart';
import 'services/query_service.dart';
import 'services/paging_service.dart';

class GeoQueryFirestore {
  final Query query;
  final String geohashFieldPath;

  GeoQueryFirestore({required this.query, required this.geohashFieldPath});

  Future<List<DocumentSnapshot>> queryByRange({required double range}) async {
    // Implementation here
    return [];
  }

  Future<List<DocumentSnapshot>> loadMore() async {
    // Implementation here
    return [];

  }

  Future<List<DocumentSnapshot>> queryByMapBounds(
      {required dynamic bounds}) async {
    // Implementation here
    return [];
  }
}
