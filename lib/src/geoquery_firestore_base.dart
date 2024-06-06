import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoquery_firestore/enums/enums.dart';
import 'package:geoquery_firestore/models/empty_snapshot.dart';
import 'package:geoquery_firestore/models/latlng_bounds.dart';
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

  /// Stores the last calculated geohashes for pagination purposes.
  /// Key: An identifier for the query execution (e.g., based on search range).
  final Map<int, List<String>?> _lastGeoHashes = {};

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
    if (_lastDocuments[id] is EmptySnapshot) return [];

    List<String> rawhashes = GeohashGeneratingService(centerPoint: center)
        .getSurroundingGeohashes(selectedRange,
            customRangeInMeters: customRangeInMeters);
    // Generate GeoHashes based on the chosen range or custom radius
    List<String> searchHashes = _lastDocuments[id] != null
        ? (_lastGeoHashes[id] ?? rawhashes)
        : rawhashes;
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
    _lastDocuments[id] = documents.lastOrNull ?? EmptySnapshot();
    _lastGeoHashes[id] = searchHashes;

    return documents;
  }

  /// Retrieves documents within a specified geographic bounds using GeoHashes.
  ///
  /// **Parameters:**
  /// * `bounds`: The `LatLngBounds` object defining the search area.
  /// * `strict` (optional): Whether to use a stricter approach for filtering GeoHashes within bounds. Defaults to `true`.
  /// * `enablePagination` (optional): Whether to enable paging for retrieving results in batches. Defaults to `false`.
  /// * `limit` (optional): The minimum number of documents to retrieve in a single query. Defaults to 20. The result length will be `limit`<=length<=`limit*2`
  Future<List<DocumentSnapshot>> byMapBounds({
    required LatLngBounds bounds,
    bool strict = true,
    bool enablePagination = false,
    int limit = 20,
  }) async {
    bool isPaginationActive(int id) {
      return enablePagination && _lastDocuments[id] != null;
    }

    // Generate GeoHashes covering the bounds area
    List<String> rawHashes =
        GeohashGeneratingService(centerPoint: bounds.center)
            .getGeohashesByBounds(bounds, strict: strict)
            .toList();

    List<List<String>> searchHashes = [
      isPaginationActive(0)
          ? (_lastGeoHashes[0] ??
              (rawHashes.length > 10 ? rawHashes.sublist(0, 10) : rawHashes))
          : rawHashes.length > 10
              ? rawHashes.sublist(0, 10)
              : rawHashes,
      isPaginationActive(1)
          ? (_lastGeoHashes[1] ??
              (rawHashes.length > 10 ? rawHashes.sublist(10) : []))
          : (rawHashes.length > 10 ? rawHashes.sublist(10) : [])
    ];

    List<Query?> queries = [null, null];

    // Loop to set queries
    for (var i = 0; i < queries.length; i++) {
      if (searchHashes[i].isEmpty || _lastDocuments[i] is EmptySnapshot) break;
      queries[i] = query
          .where(geohashFieldPath, arrayContainsAny: searchHashes[i])
          .limit(limit);

      // Apply pagination logic for each query if enabled
      if (isPaginationActive(i)) {
        queries[i] = queries[i]!.startAfterDocument(_lastDocuments[i]!);
      }
    }

    // Execute Firestore queries and combine results
    List<DocumentSnapshot> documents = [];

    int i = 0;
    for (var query in queries.where((element) => element != null)) {
      var docs = (await query!.get()).docs;

      //set last document
      _lastDocuments[i] = docs.lastOrNull ?? EmptySnapshot();
      _lastGeoHashes[i] = searchHashes[0];
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
