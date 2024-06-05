import 'package:cloud_firestore/cloud_firestore.dart';


class GeoQueryFirestore {
  /// The query for returning Collection Documents 
  /// 
  /// ## True Query
  /// ```dart
  /// FirebaseFirestore.instance.collection("collection").where("condition",isEqualsTo: true).orderBy("field",descending:true)
  /// ```
  /// 
  /// ## Wrong Query
  /// ```dart
  /// FirebaseFirestore.instance.collection("collection").doc("id")
  /// ```
  final Query query;

  /// The document field path to reach out the **geohash array**
  /// 
  /// ### Example
  /// ```dart
  /// "location.geohashArray"
  /// ```
  final String geohashFieldPath;

  ///
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
