import 'package:cloud_firestore/cloud_firestore.dart';

class QueryService {
  final Query query;
  final String geohashFieldPath;

  QueryService({required this.query, required this.geohashFieldPath});

  Future<List<DocumentSnapshot>> fetchDocumentsByRange(double range) async {
    // Implementation here
    return [];

  }
}
