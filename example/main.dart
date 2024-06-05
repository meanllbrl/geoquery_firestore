// ignore_for_file: library_private_types_in_public_api, depend_on_referenced_packages

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoquery_firestore/geoquery_firestore.dart';
import 'package:geoquery_firestore/src/enums/enums.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoQueryFirestore Example (No Maps)',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final LatLng _center = LatLng(37.7749, -122.4194); // Initial center point
// Initial search radius (in meters)
  List<String> _restaurants = [];

  @override
  void initState() {
    super.initState();


    // Perform a geospatial query around the current location
    _performQuery();
  }

 

  void _performQuery() {
    // Create a GeoQueryFirestore instance
    final query = GeoQueryFirestore(
      query: FirebaseFirestore.instance.collection('restaurants'),
      geohashFieldPath: 'location.geohashes',
    );

    // Perform a geospatial query within the specified range
    query.byRange(_center, selectedRange: GeoQueryFirestoreRanges.km20).then((documents) {
      // Extract restaurant names
      setState(() {
        _restaurants = documents.map((document) => document['name'] as String).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GeoQueryFirestore Example (No Maps)'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Found Restaurants around your location:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            if (_restaurants.isNotEmpty)
              Column(
                children: _restaurants.map((restaurant) => Text(restaurant)).toList(),
              ),
            if (_restaurants.isEmpty)
              Text('No restaurants found in this area.'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performQuery,
              child: Text('Refresh Results'),
            ),
          ],
        ),
      ),
    );
  }
}
