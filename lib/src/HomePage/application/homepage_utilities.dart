import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_plus_background_downloading/fmtc_plus_background_downloading.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topography_project/Models/Bbox.dart';
import '../../FormPage/application/form_request.dart';
import '../../FormPage/presentation/formpage_screen.dart';
import 'package:topography_project/Models/Project.dart';
import 'package:topography_project/Models/Zone.dart';
import 'package:topography_project/Models/Markers.dart';
import '../../../Models/User.dart';
import 'package:http/http.dart' as http;

List<LatLng> polygonPoints = [
  LatLng(41.169555000318596, -8.622181073069193),
  LatLng(41.16586681398453, -8.615138211779408),
  LatLng(41.16909398838012, -8.608095350489625),
  LatLng(41.174702746609, -8.608401561850052)
];
String strMarkers = "";
List<Marker> markers = [];
late SharedPreferences prefs;
LocationData? currentLocationGlobal;
final Location locationService = Location();
double? latitude;
double? longitude;
double heading = 0.0;
LatLng savedLocation = LatLng(0.0, 0.0);


final region = RectangleRegion(
  LatLngBounds(
    LatLng(41.17380930243528, -8.613922487178936), // North West
    LatLng(41.17031240259549, -8.61030686985005), // South East
  ),
);

Future<void> downloadZones() async {
  final downloadable = region.toDownloadable(
    15, // Minimum Zoom
    18, // Maximum Zoom
    TileLayer(
      urlTemplate:
          'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoia2Vpc2FraSIsImEiOiJjbGV1NzV5ZXIwMWM2M3ltbGlneXphemtpIn0.htpiT-oaFiXGCw23sguJAw',
    ),
    seaTileRemoval: true,
    preventRedownload: true,
  );

  AndroidResource notificationIcon =
      const AndroidResource(name: 'ic_notification_icon', defType: 'drawable');

  await FMTC.instance('savedTiles').download.startBackground(
      region: downloadable,
      progressNotificationIcon: "@drawable/ic_launcher",
      backgroundNotificationIcon: notificationIcon);
}

void initLocationService() async {
  bool serviceEnabled;
  PermissionStatus permissionGranted;

  serviceEnabled = await locationService.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await locationService.requestService();
    if (!serviceEnabled) {
      // Location services are not enabled on the device.
      return;
    }
  }

  permissionGranted = await locationService.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await locationService.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      // Location permission not granted.
      return;
    }
  }

  locationService.onLocationChanged
      .listen((LocationData currentLocation) async {
    currentLocationGlobal = currentLocation;
    heading = currentLocation.heading!;
  });
}

Future<void> saveData(double? lat, double? longi) async {
  print("saving location");
  if (lat != null) {
    await prefs.setDouble('latitude', lat);
  }
  if (longi != null) {
    await prefs.setDouble('longitude', longi);
  }
}

Future<void> loadPrefs() async {
  prefs = await SharedPreferences.getInstance();
  if (prefs.getDouble("latitude") != null &&
      prefs.getDouble("longitude") != null) {
    latitude = prefs.getDouble('latitude')!;
    longitude = prefs.getDouble('longitude')!;
  }
  savedLocation = LatLng(latitude!, longitude!);
}

Future<void> fillMarkers(List<Markers> markersToFill) async {
  for (var markerData in markersToFill) {
    markers.add(Marker(
      width: 20,
      height: 20,
      point: LatLng(markerData.yLat, markerData.xLong),
      builder: (context) => GestureDetector(
        onTap: () {
          // Replace 123 with the actual ID of the marker
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DynamicForm(questions: questions, marker: markerData.id)));
        },
        child: const Icon(
          Icons.circle,
          color: Colors.redAccent,
          //replace color with the color or specification from API
          size: 20,
        ),
      ),
    ));
  }
}

Future<void> fetchMarkers() async {
  var connectivityResult = await (Connectivity().checkConnectivity());

  if (connectivityResult == ConnectivityResult.none) {
    List<dynamic>? markersData = prefs.getStringList('markers');
    if (markersData != null) {
      List<Markers> markersList = markersData.map((data) => Markers.fromJson(jsonDecode(data))).toList();
      fillMarkers(markersList);
    } else {
      throw Exception('Failed to load markers');
    }
  } else {
    final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/markers/1'));
    if (response.statusCode == 200) {
      List<Markers> markersList = (jsonDecode(response.body)['markers'] as List).map((data) => Markers.fromJson(data)).toList();
      fillMarkers(markersList);
      List<String> markersData = markersList.map((marker) => jsonEncode(marker.toJson())).toList();
      await prefs.setStringList('markers', markersData);
    } else {
      throw Exception('Failed to load markers');
    }
  }
}

Future<User> fetchUser() async {
  /*final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/user/1'));

  if (response.statusCode == 200) {
    return User.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load user');
  }*/
  Bbox bbox1 = const Bbox(lat: 38.7482578437, lng: -9.1483937915);
  Bbox bbox2 = const Bbox(lat: 38.7481068461, lng: -9.1483566982);
  Bbox bbox3 = const Bbox(lat: 38.7479531886, lng: -9.1483189519);
  Bbox bbox4 = const Bbox(lat: 38.7452319621, lng: -9.1476505235);
  Bbox bbox5 = const Bbox(lat: 38.7452111444, lng: -9.1476454094);
  Bbox bbox6 = const Bbox(lat: 38.7452045008, lng: -9.1476437786);
  List<Bbox> bboxs = [];
  bboxs.add(bbox1);
  bboxs.add(bbox2);
  bboxs.add(bbox3);
  bboxs.add(bbox4);
  bboxs.add(bbox5);
  bboxs.add(bbox6);

  Zone zone1 = Zone(id: 1, zoneLabel: "A.1", centerLat: 38.7479531886, centerLong: -9.1483189519, bbox: bboxs);
  Zone zone2 = Zone(id: 2, zoneLabel: "A.2", centerLat: 38.7452319621, centerLong: -9.1476505235, bbox: bboxs);
  List<Zone> zones = [];
  zones.add(zone1);
  zones.add(zone2);

  Project project1 = Project(name: "Areeiro", zones: zones, centerLat: 38.756931, centerLong: -9.15358, zoom: 1, form: 1);
  Project project2 = Project(name: "Alvalade", zones: zones, centerLat: 38.74032, centerLong: -9.13785, zoom: 1, form: 1);

  List<Project> projects = [];
  projects.add(project1);
  projects.add(project2);

  User user = User(name: "Nicolis Earthfield", projects: projects);
  return user;
}

Future<Project> fetchProject() async {
  /*var connectivityResult = await (Connectivity().checkConnectivity());

  if (connectivityResult == ConnectivityResult.none) {
    List<dynamic>? projectsData = prefs.getStringList('projects');
    if (projectsData != null) {
      List<Project> projects = projectsData.map((data) => Project.fromJson(jsonDecode(data))).toList();
      return projects;
    } else {
      throw Exception('Failed to load projects');
    }
  } else {
    final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/project/1'));
    if (response.statusCode == 200) {
      List<Project> projects = (jsonDecode(response.body)['projects'] as List).map((data) => Project.fromJson(data)).toList();
      List<String> projectsData = projects.map((project) => jsonEncode(project.toJson())).toList();
      await prefs.setStringList('projects', projectsData);
      return projects;
    } else {
      throw Exception('Failed to load projects');
    }
  }*/
  Bbox bbox1 = const Bbox(lat: 38.7482578437, lng: -9.1483937915);
  Bbox bbox2 = const Bbox(lat: 38.7481068461, lng: -9.1483566982);
  Bbox bbox3 = const Bbox(lat: 38.7479531886, lng: -9.1483189519);
  Bbox bbox4 = const Bbox(lat: 38.7452319621, lng: -9.1476505235);
  Bbox bbox5 = const Bbox(lat: 38.7452111444, lng: -9.1476454094);
  Bbox bbox6 = const Bbox(lat: 38.7452045008, lng: -9.1476437786);
  List<Bbox> bboxs = [];
  bboxs.add(bbox1);
  bboxs.add(bbox2);
  bboxs.add(bbox3);
  bboxs.add(bbox4);
  bboxs.add(bbox5);
  bboxs.add(bbox6);

  Zone zone1 = Zone(id: 1, zoneLabel: "A.1", centerLat: 38.7479531886, centerLong: -9.1483189519, bbox: bboxs);
  Zone zone2 = Zone(id: 2, zoneLabel: "A.2", centerLat: 38.7452319621, centerLong: -9.1476505235, bbox: bboxs);
  List<Zone> zones = [];
  zones.add(zone1);
  zones.add(zone2);

  Project project = Project(name: "Areeiro", zones: zones, centerLat: 38.756931, centerLong: -9.15358, zoom: 1, form: 1);
  return project;
}

Future<Zone> fetchZone() async {
  /*var connectivityResult = await (Connectivity().checkConnectivity());

  if (connectivityResult == ConnectivityResult.none) {
    List<dynamic>? zonesData = prefs.getStringList('zones');
    if (zonesData != null) {
      List<Zone> zones = zonesData.map((data) => Zone.fromJson(jsonDecode(data))).toList();
      return zones;
    } else {
      throw Exception('Failed to load zones');
    }
  } else {
    final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/project/1'));
    if (response.statusCode == 200) {
      List<Zone> zones = (jsonDecode(response.body)['zones'] as List).map((data) => Zone.fromJson(data)).toList();
      List<String> zonesData = zones.map((zone) => jsonEncode(zone.toJson())).toList();
      await prefs.setStringList('zones', zonesData);
      return zones;
    } else {
      throw Exception('Failed to load zones');
    }
  }*/

  Bbox bbox1 = const Bbox(lat: 38.7482578437, lng: -9.1483937915);
  Bbox bbox2 = const Bbox(lat: 38.7481068461, lng: -9.1483566982);
  Bbox bbox3 = const Bbox(lat: 38.7479531886, lng: -9.1483189519);
  Bbox bbox4 = const Bbox(lat: 38.7452319621, lng: -9.1476505235);
  Bbox bbox5 = const Bbox(lat: 38.7452111444, lng: -9.1476454094);
  Bbox bbox6 = const Bbox(lat: 38.7452045008, lng: -9.1476437786);
  List<Bbox> bboxs = [];
  bboxs.add(bbox1);
  bboxs.add(bbox2);
  bboxs.add(bbox3);
  bboxs.add(bbox4);
  bboxs.add(bbox5);
  bboxs.add(bbox6);

  Zone zone = Zone(id: 1, zoneLabel: "A.1", centerLat: 38.7479531886, centerLong: -9.1483189519, bbox: bboxs);
  return zone;
}