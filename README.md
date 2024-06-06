## Introduction


https://github.com/meanllbrl/geoquery_firestore/assets/83311854/dba4ac67-d3c1-43d1-9389-2756b52427e4


GeoQueryFirestore is a comprehensive package designed to facilitate efficient and performant geospatial queries within Firestore, a NoSQL database. While existing packages like GeoFlutterFire offer basic geospatial functionality, GeoQueryFirestore addresses their limitations by enabling orderby, limit, and pagination capabilities, particularly crucial for large datasets.

## Motivation

The primary motivation behind GeoQueryFirestore is to address the shortcomings of existing geospatial query packages for Firestore. While these packages provide basic functionality, they lack essential features like:

- **Orderby:** The ability to sort results based on a specified field, crucial for organizing and retrieving data in a meaningful order.
- **Limit:** The ability to restrict the number of results returned, essential for preventing performance bottlenecks and managing data retrieval efficiently.
- **Pagination:** The ability to retrieve results in batches, particularly important for large datasets and handling paginated user interfaces.

These limitations hinder the effective utilization of geospatial queries in Firestore, especially for large-scale applications. GeoQueryFirestore aims to bridge this gap by providing a robust and performant solution for geospatial queries in Firestore.

## System Overview

GeoQueryFirestore operates by intelligently selecting the appropriate precision level based on the provided range or map boundaries. It then identifies the potential GeoHashes within the specified area, enabling efficient filtering and retrieval of documents based on their coordinates.

## Database Structure

![Adsız tasarım (1)](https://github.com/meanllbrl/geoquery_firestore/assets/83311854/5afbbe7a-f5a9-48c8-bb21-a02abfb3549b)

To effectively utilize GeoQueryFirestore, the Firestore database should be structured as follows: 

- **Geohash Array** Each Firestore document must contain a field holding an array of GeoHashes representing the document's location. The field name can be customized as per the developer's preference.
- **Geohash Precision** For optimal performance, ensure the GeoHash precision aligns with the query requirements. For instance, a precision of 8 characters (e.g., swg5r323) is recommended for most use cases.

## Example Usage

GeoQueryFirestore provides convenient methods for performing various geospatial queries:

### By Range:
**Parameters:**
* `center`: The center point (latitude and longitude) of the search area.
* `selectedRange`: A predefined geospatial range (e.g., `GeoQueryFirestoreRanges.km20`).
* `customRangeInMeters` (optional): A custom range in meters if `selectedRange` is `GeoQueryFirestoreRanges.custom`.
* `startAfterDocument` (optional): The document snapshot to start after for pagination.
* `enablePagination` (optional): Whether to enable paging for retrieving results in batches. Defaults to `false`.
* `limit` (optional): The maximum number of documents to retrieve in a single query. Defaults to 20.

```dart
final center = LatLng(37.7749, -122.4194); // Center point
final range = GeoQueryFirestoreRanges.km20; // Search range (20 kilometers)

final query = GeoQueryFirestore(
  query: FirebaseFirestore.instance.collection('restaurants'),
  geohashFieldPath: 'location.geohashes',
);

final documents = await query.byRange(
  center: center,
  selectedRange: range,
);
```

**Give Custom Range**
```dart
final documents = await query.byRange(
  center: center,
  selectedRange: GeoQueryFirestoreRanges.custom,
  customRangeInMeters: 10000
);
```

**Enable Pagination**
*It will automatically store the last document and start after the document. To reset call `query.resetPagination()`*
```dart
final documents = await query.byRange(
  center: center,
  selectedRange: GeoQueryFirestoreRanges.custom,
  customRangeInMeters: 10000,
  enablePagination:true
);
```

**Handle Pagination Yourself**
```dart
final documents = await query.byRange(
  center: center,
  selectedRange: GeoQueryFirestoreRanges.custom,
  customRangeInMeters: 10000,
  enablePagination:true,
  startAfterDocument:theDocument
);
```

**Limit the Document Number**
*limit is set 20 as default*
```dart
final documents = await query.byRange(
  center: center,
  selectedRange: GeoQueryFirestoreRanges.custom,
  customRangeInMeters: 10000,
  enablePagination:true,
  startAfterDocument:theDocument,
  limit:10
);
```

### By Map Bounds:
**Parameters:**
* `bounds`: The `LatLngBounds` object defining the search area.
* `strict` (optional): Whether to use a stricter approach for filtering GeoHashes within bounds. Defaults to `true`.
* `enablePagination` (optional): Whether to enable paging for retrieving results in batches. Defaults to `false`.
* `limit` (optional): The maximum number of documents to retrieve in a single query. Defaults to 20.

```dart
final bounds = LatLngBounds(LatLng(37.7131, -122.4194), LatLng(37.8354, -122.3792)); // Search bounds
final strict = true; // Strict boundary adherence

final query = GeoQueryFirestore(
  query: FirebaseFirestore.instance.collection('restaurants'),
  geohashFieldPath: 'location.geohashes',
);

final documents = await query.byMapBounds(
  bounds: bounds,
  strict: strict,
);
```

**Enable Pagination**
*It will automatically store the last document and start after the document. To reset call `query.resetPagination()`*
```dart
final documents = await query.byMapBounds(
  bounds: bounds,
  strict: strict,
  enablePagination:true
);
```

**Limit the Document Number**
*limit is set 20 as default (the document count may be limit<=length<=limit*2) *
```dart
final documents = await query.byMapBounds(
  bounds: bounds,
  strict: strict,
  enablePagination:true,
  limit: 10
);
```

### Warnings
* This is a solution, but it does not work 100% correctly. GeoHashes divide the Earth's surface into hexagonal cells, and their boundaries may not perfectly align with the actual search area, especially for irregular shapes or areas close to GeoHash cell boundaries. This can lead to some edge cases where documents might fall outside the intended search area.
* You may receive an index error on the first run of your detailed queries. You can create an index with the link in the error message. It will then start working.

### Recommendations
* To understand more of the geohashes you can look up https://geohash.softeng.co/s & https://en.wikipedia.org/wiki/Geohash
