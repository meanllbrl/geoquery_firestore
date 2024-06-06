import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoquery_firestore/enums/enums.dart';
import 'package:geoquery_firestore/src/models/latlng_bounds.dart';
import 'package:geoquery_firestore/src/services/geohash_generating_service.dart';
import 'package:latlong2/latlong.dart';

/// Class for performing geospatial queries using Firestore and GeoHashes.
class GeoQueryFirestore {
  /// The Firestore query for retrieving collection documents.

  /// **Example:**
  /// ```dart
  /// FirebaseFirestore.instance
  ///   .collection("restaurants")
  ///   .where("cuisine", isEqualTo: "Italian")
  ///   .orderBy("rating", descending: true)
  /// ```
  final Query query;

  /// The document field path containing the GeoHash array for geospatial filtering.
  ///
  /// **Example:**
  /// ```dart
  /// "location.geohashes"
  /// ```
  final String geohashFieldPath;

  /// Creates a new instance of `GeoQueryFirestore`.
  ///
  /// **Parameters:**
  /// * `query`: The Firestore query for retrieving documents.
  /// * `geohashFieldPath`: The document field path containing the GeoHash array.
  GeoQueryFirestore({required this.query, required this.geohashFieldPath});

  /// Stores the last retrieved documents for pagination purposes.
  /// Key: An identifier for the query execution (e.g., based on search range).
  /// Value: The last document snapshot retrieved in the previous query execution.
  final Map<int, DocumentSnapshot?> _lastDocuments = {};

  /// Retrieves documents within a specified geospatial range from a given center point.
  ///
  /// **Parameters:**
  /// * `center`: The center point (latitude and longitude) of the search area.
  /// * `selectedRange`: A predefined geospatial range (e.g., `GeoQueryFirestoreRanges.km20`).
  /// * `customRangeInMeters` (optional): A custom range in meters if `selectedRange` is `GeoQueryFirestoreRanges.custom`.
  /// * `startAfterDocument` (optional): The document snapshot to start after for pagination.
  /// * `enablePagination` (optional): Whether to enable paging for retrieving results in batches. Defaults to `false`.
  /// * `limit` (optional): The maximum number of documents to retrieve in a single query. Defaults to 20.
  Future<List<DocumentSnapshot>> byRange(
    LatLng center, {
    required GeoQueryFirestoreRanges selectedRange,
    double? customRangeInMeters,
    DocumentSnapshot? startAfterDocument,
    bool enablePagination = false,
    int limit = 20,
  }) async {
    int id = 3;
    // Generate GeoHashes based on the chosen range or custom radius
    List<String> searchHashes = GeohashGeneratingService(centerPoint: center)
        .getSurroundingGeohashes(selectedRange,
            customRangeInMeters: customRangeInMeters);
    // Construct the Firestore query with GeoHash filtering
    Query firestoreQuery = query
        .where(geohashFieldPath, arrayContainsAny: searchHashes)
        .limit(limit);

    // Apply pagination logic if enabled
    if (enablePagination) {
      if (startAfterDocument != null) {
        firestoreQuery = firestoreQuery.startAfterDocument(startAfterDocument);
      } else if (_lastDocuments[id] != null) {
        firestoreQuery = firestoreQuery.startAfterDocument(_lastDocuments[id]!);
      }
    }

    // Execute the Firestore query and retrieve documents
    final List<DocumentSnapshot> documents = (await firestoreQuery.get()).docs;

    // Update the last document for the current query execution (identified by `id`)
    _lastDocuments[id] = documents.lastOrNull;

    return documents;
  }

  /// Retrieves documents within a specified geographic bounds using GeoHashes.
  ///
  /// **Parameters:**
  /// * `bounds`: The `LatLngBounds` object defining the search area.
  /// * `strict` (optional): Whether to use a stricter approach for filtering GeoHashes within bounds. Defaults to `true`.
  /// * `enablePagination` (optional): Whether to enable paging for retrieving results in batches. Defaults to `false`.
  /// * `limit` (optional): The maximum number of documents to retrieve in a single query. Defaults to 20.
  Future<List<DocumentSnapshot>> byMapBounds({
    required LatLngBounds bounds,
    bool strict = true,
    bool enablePagination = false,
    int limit = 20,
  }) async {
    // Generate GeoHashes covering the bounds area
    List<String> searchHashes =
        GeohashGeneratingService(centerPoint: bounds.center)
            .getGeohashesByBounds(bounds, strict: strict)
            .toList();

    List<Query?> queries = [null, null];

    // Loop to set queries
    for (var i = 0; i < queries.length; i++) {
      if (searchHashes.isEmpty) break;
      queries[i] = query
          .where(geohashFieldPath,
              arrayContainsAny: i == 0 && searchHashes.length > 10
                  ? searchHashes.sublist(0, 10)
                  : searchHashes)
          .limit(limit);

      // Remove used GeoHashes from the list
      if (searchHashes.length > 10) {
        searchHashes.removeRange(0, 10);
      }

      // Apply pagination logic for each query if enabled
      if (enablePagination && _lastDocuments[i] != null) {
        queries[i] = query.startAfterDocument(_lastDocuments[i]!);
      }
    }

    // Execute Firestore queries and combine results
    List<DocumentSnapshot> documents = [];

    int i = 0;
    for (var query in queries.where((element) => element != null)) {
      var docs = (await query!.get()).docs;
      //set last document
      _lastDocuments[i] = docs.lastOrNull;
      documents.addAll(docs);
      i++;
    }

    return documents;
  }

  ///resets the pagination
  void resetPagination() {
    _lastDocuments.clear();
  }
}
