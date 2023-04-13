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
import '../presentation/homepage_screen.dart';
import '../../FormPage/application/form_request.dart';
import '../../FormPage/presentation/formpage_screen.dart';
import 'package:topography_project/Models/Project.dart';
import 'package:topography_project/Models/Zone.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:topography_project/Models/Markers.dart';
import '../../../Models/User.dart';
import 'package:http/http.dart' as http;

import '../../LocallySavedMarkersPage/locallySavedMarkers.dart';

List<LatLng> polygonPoints = [
  LatLng(38.7482578437, -9.1483937915),
  LatLng(38.7481068461, -9.1483566982),
  LatLng(38.7479531886, -9.1483189519),
  LatLng(38.7452319621, -9.1476505235),
  LatLng(38.7452111444, -9.1476454094),
  LatLng(38.7452045008, -9.1476437786)
];

bool refresh = false;
String strMarkers = "";
late SharedPreferences prefs;
LocationData? currentLocationGlobal;
final Location locationService = Location();
double? latitude;
double? longitude;
double heading = 0.0;
LatLng savedLocation = LatLng(0.0, 0.0);
List<Marker> markers = [];
List<String> selectedOption = ['All markers'];
final List<String> options = [
  'Incomplete markers',
  'Semi-complete markers',
  'Complete markers',
  'All markers',
];

final region = RectangleRegion(
  LatLngBounds(
    LatLng(41.17380930243528, -8.613922487178936), // North West
    LatLng(41.17031240259549, -8.61030686985005),
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

  await FMTC
      .instance('savedTiles')
      .download
      .startBackground(
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

bool shouldShowMarker(double currentZoom) {
  return currentZoom >= 13;
}

double outsideCurrentZoom = 0;

class FilterMarkers extends StatefulWidget {
  final double currentZoom;

  FilterMarkers(this.currentZoom, {Key? key }) : super(key: key);

  @override
  State<FilterMarkers> createState() => _FilterMarkersState();
}

class _FilterMarkersState extends State<FilterMarkers> {
  late Future<List<Marker>> markers;
  List<MarkerData> markersForm = [];

  @override
  void initState() {
    super.initState();
    markers = filterMarkers();
    outsideCurrentZoom = widget.currentZoom;
  }

  Future<List<Marker>> loadMarkers() async {
    markers = filterMarkers(optionalParameter: reloadMarkers);
    return markers;
  }

  void reloadMarkers() {
    setState(() {
      markers = loadMarkers();
    });
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Marker>>(
      future: loadMarkers(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Marker>? markersList = snapshot.data;
          if (markersList != null) {
            return MarkerLayer(
              markers: shouldShowMarker(widget.currentZoom) ? markersList : [],
            );
          } else {
            return const Text('Error: markers is null');
          }
        } else if (snapshot.hasError) {
          return Text('Error loading markers: ${snapshot.error}');
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}

Future<List<Markers>> fetchMarkers() async {
  /*var connectivityResult = await (Connectivity().checkConnectivity());

  if (connectivityResult == ConnectivityResult.none) {
    List<dynamic>? markersData = prefs.getStringList('markers');
    if (markersData != null) {
      List<Markers> markersList = markersData.map((data) =>
          Markers.fromJson(jsonDecode(data))).toList();
      return markersList;
    }else{
      return markersData;
    }
  } else {
    final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/markers/1'));
    if (response.statusCode == 200) {
      List<Markers> markersList = (jsonDecode(response.body)['markers'] as List).map((data) => Markers.fromJson(data)).toList();
      List<String> markersData = markersList.map((marker) => jsonEncode(marker.toJson())).toList();
      await prefs.setStringList('markers', markersData);
      return markersList;
  }*/

  List<Markers> markersList = [];
  Markers markers1 = const Markers(
      fullID: "r11050205",
      osmID: 11050205,
      id: 21,
      yLat: 38.7475644,
      xLong: -9.1350445,
      mainZoneID: 1,
      subZoneID: 1,
      status: 0);
  Markers markers2 = const Markers(
      fullID: "w31730499",
      osmID: 31730499,
      id: 22,
      yLat: 38.747934,
      xLong: -9.135595,
      mainZoneID: 1,
      subZoneID: 1,
      status: 1);
  Markers markers3 = const Markers(
      fullID: "w31731372",
      osmID: 31731372,
      id: 23,
      yLat: 38.7465131,
      xLong: -9.1368064,
      mainZoneID: 1,
      subZoneID: 1,
      status: 2);
  Markers markers4 = const Markers(
      fullID: "w31731373",
      osmID: 31731373,
      id: 24,
      yLat: 38.7464782,
      xLong: -9.1372773,
      mainZoneID: 1,
      subZoneID: 1,
      status: 0);
  Markers markers5 = const Markers(
      fullID: "w31731374",
      osmID: 31731374,
      id: 25,
      yLat: 38.7464433,
      xLong: -9.1377495,
      mainZoneID: 1,
      subZoneID: 1,
      status: 1);
  Markers markers6 = const Markers(
      fullID: "w31731375",
      osmID: 31731375,
      id: 26,
      yLat: 38.7461413,
      xLong: -9.1381216,
      mainZoneID: 1,
      subZoneID: 1,
      status: 2);
  markersList.add(markers1);
  markersList.add(markers2);
  markersList.add(markers3);
  markersList.add(markers4);
  markersList.add(markers5);
  markersList.add(markers6);

  return markersList;
}

Future<List<Marker>> filterMarkers({Function()? optionalParameter}) async {
  List<Markers> markersList = await fetchMarkers();
  List<MarkerData> markersData = [];
  List<Marker> markers = [];

  final prefs = await SharedPreferences.getInstance();
  final markerIDs = prefs.getStringList('localForm') ?? [];
  for (final markerID in markerIDs) {
    final formDataJson = prefs.getString(markerID);
    final formData = json.decode(formDataJson!);
    final imagePaths = prefs.getStringList('${markerID}_images');
    final dateInt = prefs.getInt('${markerID}_date');
    DateTime dt = DateTime.fromMillisecondsSinceEpoch(dateInt!);
    final markerData = MarkerData(markerID, imagePaths!, formData, dt);
    markersData.add(markerData);
  }
  if (selectedOption.contains('All markers')) {
    for (var markerData in markersList) {
      if (markerData.status == 0) {
        if (markersData.any((markerzData) =>
        markerzData.markerID == markerData.id.toString())) {
          int index = markersData.indexWhere(
                  (marker) => marker.markerID == markerData.id.toString());
          markers.add(Marker(
            width: 20,
            height: 20,
            point: LatLng(markerData.yLat, markerData.xLong),
            builder: (context) =>
                GestureDetector(
                  onTap: () async {
                    // Replace 123 with the actual ID of the marker
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DynamicForm(
                                  questions: questions,
                                  marker: markerData.id,
                                  values: markersData[index].formData,
                                  onResultUpdated: optionalParameter!,
                                )));
                  },
                  child: const Icon(
                    Icons.circle,
                    color: Colors.redAccent,
                    //replace color with the color or specification from API
                    size: 20,
                  ),
                ),
          ));
        } else {
          markers.add(Marker(
            width: 20,
            height: 20,
            point: LatLng(markerData.yLat, markerData.xLong),
            builder: (context) =>
                GestureDetector(
                  onTap: () async {
                    // Replace 123 with the actual ID of the marker
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DynamicForm(
                                  questions: questions,
                                  marker: markerData.id,
                                  onResultUpdated: optionalParameter!,
                                )));
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
      } else if (markerData.status == 1) {
        if (markersData.any((markerzData) =>
        markerzData.markerID == markerData.id.toString())) {
          int index = markersData.indexWhere(
                  (marker) => marker.markerID == markerData.id.toString());
          markers.add(Marker(
            width: 20,
            height: 20,
            point: LatLng(markerData.yLat, markerData.xLong),
            builder: (context) =>
                GestureDetector(
                  onTap: () {
                    // Replace 123 with the actual ID of the marker
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DynamicForm(
                                  questions: questions,
                                  marker: markerData.id,
                                  values: markersData[index].formData,
                                  onResultUpdated: optionalParameter!,
                                )));
                  },
                  child: const Icon(
                    Icons.circle,
                    color: Colors.orangeAccent,
                    //replace color with the color or specification from API
                    size: 20,
                  ),
                ),
          ));
        } else {
          markers.add(Marker(
            width: 20,
            height: 20,
            point: LatLng(markerData.yLat, markerData.xLong),
            builder: (context) =>
                GestureDetector(
                  onTap: () {
                    // Replace 123 with the actual ID of the marker
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DynamicForm(
                                  questions: questions,
                                  marker: markerData.id,
                                  onResultUpdated: optionalParameter!,
                                )));
                  },
                  child: const Icon(
                    Icons.circle,
                    color: Colors.orangeAccent,
                    //replace color with the color or specification from API
                    size: 20,
                  ),
                ),
          ));
        }
      } else if (markerData.status == 2) {
        markers.add(Marker(
          width: 20,
          height: 20,
          point: LatLng(markerData.yLat, markerData.xLong),
          builder: (context) =>
              GestureDetector(
                onTap: () {
                  // Replace 123 with the actual ID of the marker
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              DynamicForm(
                                questions: questions,
                                marker: markerData.id,
                                onResultUpdated: optionalParameter!,
                              )));
                },
                child: const Icon(
                  Icons.circle,
                  color: Colors.greenAccent,
                  //replace color with the color or specification from API
                  size: 20,
                ),
              ),
        ));
      }
    }
    return markers;
  } else if (selectedOption.contains('Incomplete markers')) {
    for (Markers markerData in markersList) {
      if (markerData.status == 0) {
        if (markersData.any((markerzData) =>
        markerzData.markerID == markerData.id.toString())) {
          int index = markersData.indexWhere(
                  (marker) => marker.markerID == markerData.id.toString());
          markers.add(Marker(
            width: 20,
            height: 20,
            point: LatLng(markerData.yLat, markerData.xLong),
            builder: (context) =>
                GestureDetector(
                  onTap: () async {
                    // Replace 123 with the actual ID of the marker
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DynamicForm(
                                  questions: questions,
                                  marker: markerData.id,
                                  values: markersData[index].formData,
                                  onResultUpdated: optionalParameter!,
                                )));
                  },
                  child: const Icon(
                    Icons.circle,
                    color: Colors.redAccent,
                    //replace color with the color or specification from API
                    size: 20,
                  ),
                ),
          ));
        } else {
          markers.add(Marker(
            width: 20,
            height: 20,
            point: LatLng(markerData.yLat, markerData.xLong),
            builder: (context) =>
                GestureDetector(
                  onTap: () async {
                    // Replace 123 with the actual ID of the marker
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DynamicForm(
                                  questions: questions,
                                  marker: markerData.id,
                                  onResultUpdated: optionalParameter!,
                                )));
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
    }
    if (selectedOption.contains('Semi-complete markers')) {
      for (Markers markerData in markersList) {
        if (markerData.status == 1) {
          if (markersData.any((markerzData) =>
          markerzData.markerID == markerData.id.toString())) {
            int index = markersData.indexWhere(
                    (marker) => marker.markerID == markerData.id.toString());
            markers.add(Marker(
              width: 20,
              height: 20,
              point: LatLng(markerData.yLat, markerData.xLong),
              builder: (context) =>
                  GestureDetector(
                    onTap: () {
                      // Replace 123 with the actual ID of the marker
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  DynamicForm(
                                    questions: questions,
                                    marker: markerData.id,
                                    values: markersData[index].formData,
                                    onResultUpdated: optionalParameter!,
                                  )));
                    },
                    child: const Icon(
                      Icons.circle,
                      color: Colors.orangeAccent,
                      //replace color with the color or specification from API
                      size: 20,
                    ),
                  ),
            ));
          } else {
            markers.add(Marker(
              width: 20,
              height: 20,
              point: LatLng(markerData.yLat, markerData.xLong),
              builder: (context) =>
                  GestureDetector(
                    onTap: () {
                      // Replace 123 with the actual ID of the marker
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  DynamicForm(
                                    questions: questions,
                                    marker: markerData.id,
                                    onResultUpdated: optionalParameter!,
                                  )));
                    },
                    child: const Icon(
                      Icons.circle,
                      color: Colors.orangeAccent,
                      //replace color with the color or specification from API
                      size: 20,
                    ),
                  ),
            ));
          }
        }
      }
    } else if (selectedOption.contains('Complete markers')) {
      for (Markers markerData in markersList) {
        if (markerData.status == 2) {
          markers.add(Marker(
            width: 20,
            height: 20,
            point: LatLng(markerData.yLat, markerData.xLong),
            builder: (context) =>
                GestureDetector(
                  onTap: () {
                    // Replace 123 with the actual ID of the marker
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DynamicForm(
                                  questions: questions,
                                  marker: markerData.id,
                                  onResultUpdated: optionalParameter!,
                                )));
                  },
                  child: const Icon(
                    Icons.circle,
                    color: Colors.greenAccent,
                    //replace color with the color or specification from API
                    size: 20,
                  ),
                ),
          ));
        }
      }
    }
    return markers;
  } else if (selectedOption.contains('Semi-complete markers')) {
    for (Markers markerData in markersList) {
      if (markerData.status == 1) {
        if (markersData.any((markerzData) =>
        markerzData.markerID == markerData.id.toString())) {
          int index = markersData.indexWhere(
                  (marker) => marker.markerID == markerData.id.toString());
          markers.add(Marker(
            width: 20,
            height: 20,
            point: LatLng(markerData.yLat, markerData.xLong),
            builder: (context) =>
                GestureDetector(
                  onTap: () {
                    // Replace 123 with the actual ID of the marker
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DynamicForm(
                                  questions: questions,
                                  marker: markerData.id,
                                  values: markersData[index].formData,
                                  onResultUpdated: optionalParameter!,
                                )));
                  },
                  child: const Icon(
                    Icons.circle,
                    color: Colors.orangeAccent,
                    //replace color with the color or specification from API
                    size: 20,
                  ),
                ),
          ));
        } else {
          markers.add(Marker(
            width: 20,
            height: 20,
            point: LatLng(markerData.yLat, markerData.xLong),
            builder: (context) =>
                GestureDetector(
                  onTap: () {
                    // Replace 123 with the actual ID of the marker
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DynamicForm(
                                  questions: questions,
                                  marker: markerData.id,
                                  onResultUpdated: optionalParameter!,
                                )));
                  },
                  child: const Icon(
                    Icons.circle,
                    color: Colors.orangeAccent,
                    //replace color with the color or specification from API
                    size: 20,
                  ),
                ),
          ));
        }
      }
    }
    if (selectedOption.contains('Incomplete markers')) {
      for (Markers markerData in markersList) {
        if (markerData.status == 0) {
          if (markersData.any((markerzData) =>
          markerzData.markerID == markerData.id.toString())) {
            int index = markersData.indexWhere(
                    (marker) => marker.markerID == markerData.id.toString());
            markers.add(Marker(
              width: 20,
              height: 20,
              point: LatLng(markerData.yLat, markerData.xLong),
              builder: (context) =>
                  GestureDetector(
                    onTap: () async {
                      // Replace 123 with the actual ID of the marker
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  DynamicForm(
                                    questions: questions,
                                    marker: markerData.id,
                                    values: markersData[index].formData,
                                    onResultUpdated: optionalParameter!,
                                  )));
                    },
                    child: const Icon(
                      Icons.circle,
                      color: Colors.redAccent,
                      //replace color with the color or specification from API
                      size: 20,
                    ),
                  ),
            ));
          } else {
            markers.add(Marker(
              width: 20,
              height: 20,
              point: LatLng(markerData.yLat, markerData.xLong),
              builder: (context) =>
                  GestureDetector(
                    onTap: () async {
                      // Replace 123 with the actual ID of the marker
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  DynamicForm(
                                    questions: questions,
                                    marker: markerData.id,
                                    onResultUpdated: optionalParameter!,
                                  )));
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
      }
    } else if (selectedOption.contains('Complete markers')) {
      for (Markers markerData in markersList) {
        if (markerData.status == 2) {
          markers.add(Marker(
            width: 20,
            height: 20,
            point: LatLng(markerData.yLat, markerData.xLong),
            builder: (context) =>
                GestureDetector(
                  onTap: () {
                    // Replace 123 with the actual ID of the marker
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                DynamicForm(
                                  questions: questions,
                                  marker: markerData.id,
                                  onResultUpdated: optionalParameter!,
                                )));
                  },
                  child: const Icon(
                    Icons.circle,
                    color: Colors.greenAccent,
                    //replace color with the color or specification from API
                    size: 20,
                  ),
                ),
          ));
        }
      }
    }
    return markers;
  } else if (selectedOption.contains('Complete markers')) {
    for (Markers markerData in markersList) {
      if (markerData.status == 2) {
        markers.add(Marker(
          width: 20,
          height: 20,
          point: LatLng(markerData.yLat, markerData.xLong),
          builder: (context) =>
              GestureDetector(
                onTap: () {
                  // Replace 123 with the actual ID of the marker
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              DynamicForm(
                                questions: questions,
                                marker: markerData.id,
                                onResultUpdated: optionalParameter!,
                              )));
                },
                child: const Icon(
                  Icons.circle,
                  color: Colors.greenAccent,
                  //replace color with the color or specification from API
                  size: 20,
                ),
              ),
        ));
      }
    }
    if (selectedOption.contains('Incomplete markers')) {
      for (Markers markerData in markersList) {
        if (markerData.status == 0) {
          if (markersData.any((markerzData) =>
          markerzData.markerID == markerData.id.toString())) {
            int index = markersData.indexWhere(
                    (marker) => marker.markerID == markerData.id.toString());
            markers.add(Marker(
              width: 20,
              height: 20,
              point: LatLng(markerData.yLat, markerData.xLong),
              builder: (context) =>
                  GestureDetector(
                    onTap: () async {
                      // Replace 123 with the actual ID of the marker
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  DynamicForm(
                                    questions: questions,
                                    marker: markerData.id,
                                    values: markersData[index].formData,
                                    onResultUpdated: optionalParameter!,
                                  )));
                    },
                    child: const Icon(
                      Icons.circle,
                      color: Colors.redAccent,
                      //replace color with the color or specification from API
                      size: 20,
                    ),
                  ),
            ));
          } else {
            markers.add(Marker(
              width: 20,
              height: 20,
              point: LatLng(markerData.yLat, markerData.xLong),
              builder: (context) =>
                  GestureDetector(
                    onTap: () async {
                      // Replace 123 with the actual ID of the marker
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  DynamicForm(
                                    questions: questions,
                                    marker: markerData.id,
                                    onResultUpdated: optionalParameter!,
                                  )));
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
      }
    } else if (selectedOption.contains('Semi-complete markers')) {
      for (Markers markerData in markersList) {
        if (markerData.status == 1) {
          if (markersData.any((markerzData) =>
          markerzData.markerID == markerData.id.toString())) {
            int index = markersData.indexWhere(
                    (marker) => marker.markerID == markerData.id.toString());
            markers.add(Marker(
              width: 20,
              height: 20,
              point: LatLng(markerData.yLat, markerData.xLong),
              builder: (context) =>
                  GestureDetector(
                    onTap: () {
                      // Replace 123 with the actual ID of the marker
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  DynamicForm(
                                    questions: questions,
                                    marker: markerData.id,
                                    values: markersData[index].formData,
                                    onResultUpdated: optionalParameter!,
                                  )));
                    },
                    child: const Icon(
                      Icons.circle,
                      color: Colors.orangeAccent,
                      //replace color with the color or specification from API
                      size: 20,
                    ),
                  ),
            ));
          } else {
            markers.add(Marker(
              width: 20,
              height: 20,
              point: LatLng(markerData.yLat, markerData.xLong),
              builder: (context) =>
                  GestureDetector(
                    onTap: () {
                      // Replace 123 with the actual ID of the marker
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  DynamicForm(
                                    questions: questions,
                                    marker: markerData.id,
                                    onResultUpdated: optionalParameter!,
                                  )));
                    },
                    child: const Icon(
                      Icons.circle,
                      color: Colors.orangeAccent,
                      //replace color with the color or specification from API
                      size: 20,
                    ),
                  ),
            ));
          }
        }
      }
    }
    return markers;
  }
  return markers;
}

Future<User> fetchData() async {
  /*var connectivityResult = await (Connectivity().checkConnectivity());
  final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/user/1'));
  List<Project> projects = [];
  User userAux;
  User user;

  if (response.statusCode == 200) {
    userAux = User.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load user');
  }

  if (connectivityResult == ConnectivityResult.none) {
    List<dynamic>? projectsData = prefs.getStringList('projects');
    if (projectsData != null) {
      projects = projectsData.map((data) => Project.fromJson(jsonDecode(data))).toList();
      user = User(name: userAux.name, projects: projects);
    } else {
      throw Exception('Failed to load projects');
    }
  } else {
    for(User user1 in [userAux]){
      String name = user1.name;
      final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/project/$name'));
      if (response.statusCode == 200) {
        Project projectAux = Project.fromJson(jsonDecode(response.body));
        projects.add(projectAux);
      } else {
        throw Exception('Failed to load projects');
      }
    }
    user = User(name:userAux.name, projects: projects);
    List<String> projectData = projects.map((project) => jsonEncode(project.toJson())).toList();
    await prefs.setStringList('projects', projectData);
  }*/
  String userJson =
      '{"name":"Horatio Standbrook","project":[{"id":1,"name":"Alvalade"},{"id":2,"name":"Areeiro"}]}';
  String project1Json =
      '{"name":"Alvalade","center_lat":38.756931,"center_long":-9.15358,"zoom":1,"form":1,"zones":[{"id":1,"zone_label":"A.1","center_lat":38.749298,"center_long":-9.138483,"bbox":[{"lat":38.7482578437,"lng":-9.1483937915},{"lat":38.7481068461,"lng":-9.1483566982},{"lat":38.7479531886,"lng":-9.1483189519},{"lat":38.7452319621,"lng":-9.1476505235},{"lat":38.7452111444,"lng":-9.1476454094},{"lat":38.7452045008,"lng":-9.1476437786},{"lat":38.7450020263,"lng":-9.1475940576},{"lat":38.7449312036,"lng":-9.1475766658},{"lat":38.7446317944,"lng":-9.1475237733},{"lat":38.7448515141,"lng":-9.1463514233},{"lat":38.7450086689,"lng":-9.1455128581},{"lat":38.7450090696,"lng":-9.1455021644},{"lat":38.7450118899,"lng":-9.1453699708},{"lat":38.7450695707,"lng":-9.1445249153},{"lat":38.7450689469,"lng":-9.1443701642},{"lat":38.7450646275,"lng":-9.1433005313},{"lat":38.745062846,"lng":-9.1428601499},{"lat":38.7450614597,"lng":-9.1425175525},{"lat":38.7451034394,"lng":-9.1419338325},{"lat":38.7451274384,"lng":-9.1414499288},{"lat":38.7451789152,"lng":-9.1404959697},{"lat":38.7451708448,"lng":-9.1402426219},{"lat":38.74517041,"lng":-9.1402289982},{"lat":38.7452084859,"lng":-9.1397832487},{"lat":38.7452239384,"lng":-9.1396626927},{"lat":38.7452283286,"lng":-9.1396102164},{"lat":38.7452440252,"lng":-9.1394225789},{"lat":38.7453407402,"lng":-9.1379205951},{"lat":38.7453861509,"lng":-9.1372495015},{"lat":38.7454238182,"lng":-9.1366404101},{"lat":38.745469905,"lng":-9.1359946295},{"lat":38.7455364274,"lng":-9.1348568354},{"lat":38.7455574289,"lng":-9.1346888954},{"lat":38.7455583011,"lng":-9.1346819268},{"lat":38.7458653332,"lng":-9.1322265145},{"lat":38.7459358159,"lng":-9.1312564305},{"lat":38.7459374176,"lng":-9.1312343796},{"lat":38.7459349182,"lng":-9.1308593729},{"lat":38.7459323273,"lng":-9.130470777},{"lat":38.7459446876,"lng":-9.1304702761},{"lat":38.7465060785,"lng":-9.1304476536},{"lat":38.7465084264,"lng":-9.1304730343},{"lat":38.7465179276,"lng":-9.1305756792},{"lat":38.7465918918,"lng":-9.1305691421},{"lat":38.7466234611,"lng":-9.1305663537},{"lat":38.7467577585,"lng":-9.1305557641},{"lat":38.7474244208,"lng":-9.1304867467},{"lat":38.7475595638,"lng":-9.1304731134},{"lat":38.7478300303,"lng":-9.1304458147},{"lat":38.7478613585,"lng":-9.1304417186},{"lat":38.7478991976,"lng":-9.1304367709},{"lat":38.7481032986,"lng":-9.1304140308},{"lat":38.7481248775,"lng":-9.1304116314},{"lat":38.7482037821,"lng":-9.1302758104},{"lat":38.7482121901,"lng":-9.1302613465},{"lat":38.7484093179,"lng":-9.1302531887},{"lat":38.7486342151,"lng":-9.1302438816},{"lat":38.7486345374,"lng":-9.1301904749},{"lat":38.7486346848,"lng":-9.1301656895},{"lat":38.7486351405,"lng":-9.1301004447},{"lat":38.7486788802,"lng":-9.1300830914},{"lat":38.7487145733,"lng":-9.1300688883},{"lat":38.7488154555,"lng":-9.1297314327},{"lat":38.7488374109,"lng":-9.1297336935},{"lat":38.7488930326,"lng":-9.1296769489},{"lat":38.748926114,"lng":-9.1296548643},{"lat":38.7489649865,"lng":-9.1296395308},{"lat":38.7490126809,"lng":-9.1296297446},{"lat":38.7490552581,"lng":-9.129626283},{"lat":38.7491124943,"lng":-9.1296283544},{"lat":38.7491769017,"lng":-9.1296529217},{"lat":38.7491845944,"lng":-9.1296577737},{"lat":38.7492093497,"lng":-9.1296735295},{"lat":38.7492714832,"lng":-9.1297362655},{"lat":38.7493270393,"lng":-9.1298021574},{"lat":38.7493356848,"lng":-9.1298242667},{"lat":38.7493534139,"lng":-9.1298693794},{"lat":38.7493651954,"lng":-9.1299217621},{"lat":38.7493746187,"lng":-9.1300609388},{"lat":38.7493746337,"lng":-9.1301730125},{"lat":38.7493746439,"lng":-9.1302414024},{"lat":38.7493731731,"lng":-9.1303903615},{"lat":38.7493872209,"lng":-9.1303392491},{"lat":38.749407622,"lng":-9.1303026003},{"lat":38.7494359731,"lng":-9.1302752795},{"lat":38.7494631241,"lng":-9.1302586477},{"lat":38.7494935935,"lng":-9.13024699},{"lat":38.7495272127,"lng":-9.1302425333},{"lat":38.749561223,"lng":-9.1302446169},{"lat":38.7496573162,"lng":-9.1301097338},{"lat":38.7496284867,"lng":-9.1297974079},{"lat":38.7496489492,"lng":-9.1297953734},{"lat":38.7496329725,"lng":-9.1297744976},{"lat":38.7496135244,"lng":-9.129736801},{"lat":38.7496092726,"lng":-9.129726143},{"lat":38.7496055591,"lng":-9.1297168027},{"lat":38.7495875524,"lng":-9.1296524633},{"lat":38.7495673557,"lng":-9.1296146655},{"lat":38.7495453371,"lng":-9.1295528298},{"lat":38.7495373307,"lng":-9.1295235952},{"lat":38.7495298146,"lng":-9.1294961124},{"lat":38.7495278676,"lng":-9.1294888718},{"lat":38.7495242986,"lng":-9.1294663684},{"lat":38.7494960893,"lng":-9.129384305},{"lat":38.7494826681,"lng":-9.1293426041},{"lat":38.7494746064,"lng":-9.129322914},{"lat":38.7494636753,"lng":-9.1293050636},{"lat":38.7494377487,"lng":-9.1292752775},{"lat":38.7493765129,"lng":-9.1291941701},{"lat":38.7493758845,"lng":-9.1291445537},{"lat":38.7493841003,"lng":-9.1290592663},{"lat":38.7493901537,"lng":-9.1289822943},{"lat":38.7493695899,"lng":-9.1289708542},{"lat":38.749320839,"lng":-9.1289437292},{"lat":38.7493419897,"lng":-9.1288897716},{"lat":38.7493507548,"lng":-9.1288516529},{"lat":38.7493610601,"lng":-9.1288141871},{"lat":38.7494275335,"lng":-9.1288427384},{"lat":38.7494559669,"lng":-9.1287438442},{"lat":38.7494925248,"lng":-9.1287341662},{"lat":38.7495995026,"lng":-9.1287100902},{"lat":38.7496276909,"lng":-9.1287608431},{"lat":38.7496386998,"lng":-9.128804995},{"lat":38.7496946025,"lng":-9.1287804535},{"lat":38.7496906155,"lng":-9.1287364726},{"lat":38.7497740026,"lng":-9.1287196954},{"lat":38.7498215803,"lng":-9.1287116531},{"lat":38.7498317021,"lng":-9.1287843331},{"lat":38.7498375103,"lng":-9.1288298128},{"lat":38.7498536617,"lng":-9.1288387623},{"lat":38.7498653176,"lng":-9.1288531661},{"lat":38.7498721622,"lng":-9.1288747995},{"lat":38.7498833676,"lng":-9.128912898},{"lat":38.7498857486,"lng":-9.1289261884},{"lat":38.7498879543,"lng":-9.1289384928},{"lat":38.7498915267,"lng":-9.128951519},{"lat":38.7498948342,"lng":-9.1289635845},{"lat":38.7499024013,"lng":-9.1289853039},{"lat":38.7499099814,"lng":-9.1289946117},{"lat":38.7499361272,"lng":-9.1290041636},{"lat":38.7500667092,"lng":-9.1290035497},{"lat":38.7500919317,"lng":-9.1290065597},{"lat":38.7501007659,"lng":-9.1290258799},{"lat":38.7501121071,"lng":-9.1290410559},{"lat":38.7501374875,"lng":-9.1290436068},{"lat":38.7501529135,"lng":-9.1290482499},{"lat":38.7501714768,"lng":-9.1290640163},{"lat":38.750225226,"lng":-9.1290490649},{"lat":38.7502369441,"lng":-9.129047194},{"lat":38.7503266472,"lng":-9.1290316079},{"lat":38.7504810519,"lng":-9.1290355824},{"lat":38.7506449858,"lng":-9.1290399954},{"lat":38.7507576882,"lng":-9.1290433904},{"lat":38.7507999849,"lng":-9.1290711476},{"lat":38.7508393878,"lng":-9.1290936766},{"lat":38.7509093007,"lng":-9.1291639286},{"lat":38.7509696705,"lng":-9.1291967914},{"lat":38.7510134381,"lng":-9.1292485454},{"lat":38.7511453427,"lng":-9.1293267338},{"lat":38.7512198986,"lng":-9.1293733714},{"lat":38.7513328534,"lng":-9.1295323939},{"lat":38.7513589966,"lng":-9.1295803856},{"lat":38.7513751723,"lng":-9.1296100417},{"lat":38.7514103812,"lng":-9.1296744976},{"lat":38.7514137592,"lng":-9.1297893222},{"lat":38.7514157411,"lng":-9.1298566924},{"lat":38.7514166648,"lng":-9.1298885395},{"lat":38.7514181925,"lng":-9.1299411469},{"lat":38.7514250425,"lng":-9.1300141777},{"lat":38.7513942153,"lng":-9.1300881741},{"lat":38.7514976366,"lng":-9.1300780807},{"lat":38.7514972408,"lng":-9.1300709408},{"lat":38.7516119767,"lng":-9.1300597083},{"lat":38.7517642189,"lng":-9.1300448333},{"lat":38.7518589547,"lng":-9.130037198},{"lat":38.7519381427,"lng":-9.1300308396},{"lat":38.751965094,"lng":-9.1300286412},{"lat":38.7519894429,"lng":-9.1300266562},{"lat":38.7520095304,"lng":-9.1300248661},{"lat":38.7521029081,"lng":-9.130013693},{"lat":38.7522164337,"lng":-9.1300043174},{"lat":38.7522624657,"lng":-9.1300003932},{"lat":38.7522782037,"lng":-9.129999395},{"lat":38.7523194641,"lng":-9.1299960141},{"lat":38.7523538007,"lng":-9.1299940575},{"lat":38.7524405192,"lng":-9.1299924569},{"lat":38.7524891746,"lng":-9.129987757},{"lat":38.7525517331,"lng":-9.1299823773},{"lat":38.7525738446,"lng":-9.1299793224},{"lat":38.7526629844,"lng":-9.1299705428},{"lat":38.752791904,"lng":-9.1299578369},{"lat":38.7528982301,"lng":-9.1299547386},{"lat":38.7531235794,"lng":-9.1299361199},{"lat":38.7532547587,"lng":-9.1299260808},{"lat":38.7533596514,"lng":-9.1299180528},{"lat":38.7535910457,"lng":-9.1298903725},{"lat":38.7538299355,"lng":-9.1298646771},{"lat":38.7540411474,"lng":-9.1298465389},{"lat":38.7531323304,"lng":-9.143985958},{"lat":38.7482578437,"lng":-9.1483937915}]}]}';
  String project2Json =
      '{"name":"Areeiro","center_lat":38.756931,"center_long":-9.15358,"zoom":1,"form":1,"zones":[{"id":1,"zone_label":"A.1","center_lat":38.749298,"center_long":-9.138483,"bbox":[{"lat":38.7482578437,"lng":-9.1483937915},{"lat":38.7481068461,"lng":-9.1483566982},{"lat":38.7479531886,"lng":-9.1483189519},{"lat":38.7452319621,"lng":-9.1476505235},{"lat":38.7452111444,"lng":-9.1476454094},{"lat":38.7452045008,"lng":-9.1476437786},{"lat":38.7450020263,"lng":-9.1475940576},{"lat":38.7449312036,"lng":-9.1475766658},{"lat":38.7446317944,"lng":-9.1475237733},{"lat":38.7448515141,"lng":-9.1463514233},{"lat":38.7450086689,"lng":-9.1455128581},{"lat":38.7450090696,"lng":-9.1455021644},{"lat":38.7450118899,"lng":-9.1453699708},{"lat":38.7450695707,"lng":-9.1445249153},{"lat":38.7450689469,"lng":-9.1443701642},{"lat":38.7450646275,"lng":-9.1433005313},{"lat":38.745062846,"lng":-9.1428601499},{"lat":38.7450614597,"lng":-9.1425175525},{"lat":38.7451034394,"lng":-9.1419338325},{"lat":38.7451274384,"lng":-9.1414499288},{"lat":38.7451789152,"lng":-9.1404959697},{"lat":38.7451708448,"lng":-9.1402426219},{"lat":38.74517041,"lng":-9.1402289982},{"lat":38.7452084859,"lng":-9.1397832487},{"lat":38.7452239384,"lng":-9.1396626927},{"lat":38.7452283286,"lng":-9.1396102164},{"lat":38.7452440252,"lng":-9.1394225789},{"lat":38.7453407402,"lng":-9.1379205951},{"lat":38.7453861509,"lng":-9.1372495015},{"lat":38.7454238182,"lng":-9.1366404101},{"lat":38.745469905,"lng":-9.1359946295},{"lat":38.7455364274,"lng":-9.1348568354},{"lat":38.7455574289,"lng":-9.1346888954},{"lat":38.7455583011,"lng":-9.1346819268},{"lat":38.7458653332,"lng":-9.1322265145},{"lat":38.7459358159,"lng":-9.1312564305},{"lat":38.7459374176,"lng":-9.1312343796},{"lat":38.7459349182,"lng":-9.1308593729},{"lat":38.7459323273,"lng":-9.130470777},{"lat":38.7459446876,"lng":-9.1304702761},{"lat":38.7465060785,"lng":-9.1304476536},{"lat":38.7465084264,"lng":-9.1304730343},{"lat":38.7465179276,"lng":-9.1305756792},{"lat":38.7465918918,"lng":-9.1305691421},{"lat":38.7466234611,"lng":-9.1305663537},{"lat":38.7467577585,"lng":-9.1305557641},{"lat":38.7474244208,"lng":-9.1304867467},{"lat":38.7475595638,"lng":-9.1304731134},{"lat":38.7478300303,"lng":-9.1304458147},{"lat":38.7478613585,"lng":-9.1304417186},{"lat":38.7478991976,"lng":-9.1304367709},{"lat":38.7481032986,"lng":-9.1304140308},{"lat":38.7481248775,"lng":-9.1304116314},{"lat":38.7482037821,"lng":-9.1302758104},{"lat":38.7482121901,"lng":-9.1302613465},{"lat":38.7484093179,"lng":-9.1302531887},{"lat":38.7486342151,"lng":-9.1302438816},{"lat":38.7486345374,"lng":-9.1301904749},{"lat":38.7486346848,"lng":-9.1301656895},{"lat":38.7486351405,"lng":-9.1301004447},{"lat":38.7486788802,"lng":-9.1300830914},{"lat":38.7487145733,"lng":-9.1300688883},{"lat":38.7488154555,"lng":-9.1297314327},{"lat":38.7488374109,"lng":-9.1297336935},{"lat":38.7488930326,"lng":-9.1296769489},{"lat":38.748926114,"lng":-9.1296548643},{"lat":38.7489649865,"lng":-9.1296395308},{"lat":38.7490126809,"lng":-9.1296297446},{"lat":38.7490552581,"lng":-9.129626283},{"lat":38.7491124943,"lng":-9.1296283544},{"lat":38.7491769017,"lng":-9.1296529217},{"lat":38.7491845944,"lng":-9.1296577737},{"lat":38.7492093497,"lng":-9.1296735295},{"lat":38.7492714832,"lng":-9.1297362655},{"lat":38.7493270393,"lng":-9.1298021574},{"lat":38.7493356848,"lng":-9.1298242667},{"lat":38.7493534139,"lng":-9.1298693794},{"lat":38.7493651954,"lng":-9.1299217621},{"lat":38.7493746187,"lng":-9.1300609388},{"lat":38.7493746337,"lng":-9.1301730125},{"lat":38.7493746439,"lng":-9.1302414024},{"lat":38.7493731731,"lng":-9.1303903615},{"lat":38.7493872209,"lng":-9.1303392491},{"lat":38.749407622,"lng":-9.1303026003},{"lat":38.7494359731,"lng":-9.1302752795},{"lat":38.7494631241,"lng":-9.1302586477},{"lat":38.7494935935,"lng":-9.13024699},{"lat":38.7495272127,"lng":-9.1302425333},{"lat":38.749561223,"lng":-9.1302446169},{"lat":38.7496573162,"lng":-9.1301097338},{"lat":38.7496284867,"lng":-9.1297974079},{"lat":38.7496489492,"lng":-9.1297953734},{"lat":38.7496329725,"lng":-9.1297744976},{"lat":38.7496135244,"lng":-9.129736801},{"lat":38.7496092726,"lng":-9.129726143},{"lat":38.7496055591,"lng":-9.1297168027},{"lat":38.7495875524,"lng":-9.1296524633},{"lat":38.7495673557,"lng":-9.1296146655},{"lat":38.7495453371,"lng":-9.1295528298},{"lat":38.7495373307,"lng":-9.1295235952},{"lat":38.7495298146,"lng":-9.1294961124},{"lat":38.7495278676,"lng":-9.1294888718},{"lat":38.7495242986,"lng":-9.1294663684},{"lat":38.7494960893,"lng":-9.129384305},{"lat":38.7494826681,"lng":-9.1293426041},{"lat":38.7494746064,"lng":-9.129322914},{"lat":38.7494636753,"lng":-9.1293050636},{"lat":38.7494377487,"lng":-9.1292752775},{"lat":38.7493765129,"lng":-9.1291941701},{"lat":38.7493758845,"lng":-9.1291445537},{"lat":38.7493841003,"lng":-9.1290592663},{"lat":38.7493901537,"lng":-9.1289822943},{"lat":38.7493695899,"lng":-9.1289708542},{"lat":38.749320839,"lng":-9.1289437292},{"lat":38.7493419897,"lng":-9.1288897716},{"lat":38.7493507548,"lng":-9.1288516529},{"lat":38.7493610601,"lng":-9.1288141871},{"lat":38.7494275335,"lng":-9.1288427384},{"lat":38.7494559669,"lng":-9.1287438442},{"lat":38.7494925248,"lng":-9.1287341662},{"lat":38.7495995026,"lng":-9.1287100902},{"lat":38.7496276909,"lng":-9.1287608431},{"lat":38.7496386998,"lng":-9.128804995},{"lat":38.7496946025,"lng":-9.1287804535},{"lat":38.7496906155,"lng":-9.1287364726},{"lat":38.7497740026,"lng":-9.1287196954},{"lat":38.7498215803,"lng":-9.1287116531},{"lat":38.7498317021,"lng":-9.1287843331},{"lat":38.7498375103,"lng":-9.1288298128},{"lat":38.7498536617,"lng":-9.1288387623},{"lat":38.7498653176,"lng":-9.1288531661},{"lat":38.7498721622,"lng":-9.1288747995},{"lat":38.7498833676,"lng":-9.128912898},{"lat":38.7498857486,"lng":-9.1289261884},{"lat":38.7498879543,"lng":-9.1289384928},{"lat":38.7498915267,"lng":-9.128951519},{"lat":38.7498948342,"lng":-9.1289635845},{"lat":38.7499024013,"lng":-9.1289853039},{"lat":38.7499099814,"lng":-9.1289946117},{"lat":38.7499361272,"lng":-9.1290041636},{"lat":38.7500667092,"lng":-9.1290035497},{"lat":38.7500919317,"lng":-9.1290065597},{"lat":38.7501007659,"lng":-9.1290258799},{"lat":38.7501121071,"lng":-9.1290410559},{"lat":38.7501374875,"lng":-9.1290436068},{"lat":38.7501529135,"lng":-9.1290482499},{"lat":38.7501714768,"lng":-9.1290640163},{"lat":38.750225226,"lng":-9.1290490649},{"lat":38.7502369441,"lng":-9.129047194},{"lat":38.7503266472,"lng":-9.1290316079},{"lat":38.7504810519,"lng":-9.1290355824},{"lat":38.7506449858,"lng":-9.1290399954},{"lat":38.7507576882,"lng":-9.1290433904},{"lat":38.7507999849,"lng":-9.1290711476},{"lat":38.7508393878,"lng":-9.1290936766},{"lat":38.7509093007,"lng":-9.1291639286},{"lat":38.7509696705,"lng":-9.1291967914},{"lat":38.7510134381,"lng":-9.1292485454},{"lat":38.7511453427,"lng":-9.1293267338},{"lat":38.7512198986,"lng":-9.1293733714},{"lat":38.7513328534,"lng":-9.1295323939},{"lat":38.7513589966,"lng":-9.1295803856},{"lat":38.7513751723,"lng":-9.1296100417},{"lat":38.7514103812,"lng":-9.1296744976},{"lat":38.7514137592,"lng":-9.1297893222},{"lat":38.7514157411,"lng":-9.1298566924},{"lat":38.7514166648,"lng":-9.1298885395},{"lat":38.7514181925,"lng":-9.1299411469},{"lat":38.7514250425,"lng":-9.1300141777},{"lat":38.7513942153,"lng":-9.1300881741},{"lat":38.7514976366,"lng":-9.1300780807},{"lat":38.7514972408,"lng":-9.1300709408},{"lat":38.7516119767,"lng":-9.1300597083},{"lat":38.7517642189,"lng":-9.1300448333},{"lat":38.7518589547,"lng":-9.130037198},{"lat":38.7519381427,"lng":-9.1300308396},{"lat":38.751965094,"lng":-9.1300286412},{"lat":38.7519894429,"lng":-9.1300266562},{"lat":38.7520095304,"lng":-9.1300248661},{"lat":38.7521029081,"lng":-9.130013693},{"lat":38.7522164337,"lng":-9.1300043174},{"lat":38.7522624657,"lng":-9.1300003932},{"lat":38.7522782037,"lng":-9.129999395},{"lat":38.7523194641,"lng":-9.1299960141},{"lat":38.7523538007,"lng":-9.1299940575},{"lat":38.7524405192,"lng":-9.1299924569},{"lat":38.7524891746,"lng":-9.129987757},{"lat":38.7525517331,"lng":-9.1299823773},{"lat":38.7525738446,"lng":-9.1299793224},{"lat":38.7526629844,"lng":-9.1299705428},{"lat":38.752791904,"lng":-9.1299578369},{"lat":38.7528982301,"lng":-9.1299547386},{"lat":38.7531235794,"lng":-9.1299361199},{"lat":38.7532547587,"lng":-9.1299260808},{"lat":38.7533596514,"lng":-9.1299180528},{"lat":38.7535910457,"lng":-9.1298903725},{"lat":38.7538299355,"lng":-9.1298646771},{"lat":38.7540411474,"lng":-9.1298465389},{"lat":38.7531323304,"lng":-9.143985958},{"lat":38.7482578437,"lng":-9.1483937915}]}]}';
  User user;
  List<Project> projects = [];
  Project project1 = Project.fromJson(jsonDecode(project1Json));
  Project project2 = Project.fromJson(jsonDecode(project2Json));
  projects.add(project1);
  projects.add(project2);
  User aux = User.fromJson(jsonDecode(userJson));
  user = User(name: aux.name, projects: projects);
  await Future.delayed(const Duration(seconds: 2));
  return user;
}
