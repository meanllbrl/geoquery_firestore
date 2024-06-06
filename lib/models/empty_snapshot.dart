// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';

class EmptySnapshot extends DocumentSnapshot{
  @override
  operator [](Object field) {
    throw UnimplementedError();
  }

  @override
  Object? data() {
    throw UnimplementedError();
  }

  @override
  bool get exists => throw UnimplementedError();

  @override
  get(Object field) {
    throw UnimplementedError();
  }

  @override
  String get id => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  DocumentReference<Object?> get reference => throw UnimplementedError();
}