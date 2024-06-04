# GeoQuery Firestore

A Dart package for querying Firestore documents based on geohashes. This package allows you to filter documents by range, load more documents with paging, and query documents within map bounds.

## Features

- Filter documents by range
- Load more documents with paging
- Query documents within map bounds

## Installation

Add `geoquery_firestore` to your `pubspec.yaml`:

```yaml
dependencies:
  geoquery_firestore: ^0.0.1
```

## Usage

###Constructor

Create an instance of GeoQueryFirestore:

```dart
import 'package:geoquery_firestore/geoquery_firestore.dart';

GeoQueryFirestore geoQuery = GeoQueryFirestore(
  query: firestore.collection('your_collection').where('your_field', isEqualTo: 'your_value'),
  geohashFieldPath: 'location.geohash',
);
```

## Range Query
```dart
List<DocumentSnapshot> documents = await geoQuery.queryByRange(range: 10);
```

## Paging
```dart
List<DocumentSnapshot> documents = await geoQuery.loadMore();
```

## Map Bounds
```dart
List<DocumentSnapshot> documents = await geoQuery.queryByMapBounds(bounds: yourMapBounds);
```
