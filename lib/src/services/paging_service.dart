import 'package:cloud_firestore/cloud_firestore.dart';

class PagingService {
  final Query query;
  final String geohashFieldPath;
  final int pageSize;
  DocumentSnapshot? lastDocument;

  PagingService({required this.query, required this.geohashFieldPath, this.pageSize = 10});

  Future<List<DocumentSnapshot>> fetchNextPage() async {
    // Implementation here
    return [];

  }
}
