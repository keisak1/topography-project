import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_plus_background_downloading/fmtc_plus_background_downloading.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../FormPage/formpage_screen.dart';



List<LatLng> polygonPoints = [
  LatLng(41.169555000318596, -8.622181073069193),
  LatLng(41.16586681398453, -8.615138211779408),
  LatLng(41.16909398838012, -8.608095350489625),
  LatLng(41.174702746609, -8.608401561850052)
];
String strMarkers = "";
List<Marker> savedMarkers = [];
late SharedPreferences prefs;
LocationData? currentLocation;
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

  if (latitude == null && longitude == null) {
    locationService.onLocationChanged
        .listen((LocationData currentLocation) async {
      currentLocation = currentLocation;
      heading = currentLocation.heading!;
      await prefs.setDouble('latitude', currentLocation.latitude ?? 0.0);
      await prefs.setDouble('longitude', currentLocation.longitude ?? 0.0);
    });
  } else {
    savedLocation = LatLng(latitude!, longitude!);
  }
}

Future<void> saveData(double? lat, double? longi) async {
  if (lat != null) {
    await prefs.setDouble('Latitude', lat);
  }
  if (longi != null) {
    await prefs.setDouble('Longitude', longi);
  }
}

Future<void> loadPrefs() async {
  prefs = await SharedPreferences.getInstance();
}

Map<String, dynamic> toJson() {
  /***************************************
   *
   *  SUBSTITUIR ISTO POR API CALL PARA
   *  IR BUSCAR COORDENADAS E ESTADO DO
   *  MARKER
   *
   ***************************************/
  final markers = <Marker>[
    Marker(
      width: 80,
      height: 80,
      point: LatLng(41.168517, -8.608559),
      builder: (context) => GestureDetector(
        onTap: () {
          // Replace 123 with the actual ID of the marker
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MyFormPage(markerId: 123)));
        },
        child: const Icon(
          Icons.circle,
          color: Colors.redAccent,
          size: 20,
        ),
      ),
    ),
    Marker(
      width: 80,
      height: 80,
      point: LatLng(41.17227747164333, -8.618397446786263),
      builder: (context) => const Icon(
        Icons.circle,
        color: Colors.green,
        size: 20,
      ),
    ),
  ];

  List<Map<String, dynamic>> markerList = [];
  for (Marker marker in markers) {
    Map<String, dynamic> markerMap = {
      'latitude': marker.point.latitude, // API LATITUDE
      'longitude': marker.point.longitude, // API LONGITUDE
    };
    markerList.add(markerMap);
  }
  return {
    'markers': markerList,
  };
}

Future<void> saveMarkers() async {

}

void formMarkers(Map<String, dynamic> markers){
  for(var markerData in markers['markers']){
    bool markerExists = savedMarkers.any(
            (savedMarker) => savedMarker.point.latitude == markerData['point']['latitude']
            && savedMarker.point.longitude == markerData['point']['longitude']);
    if (!markerExists) {
      savedMarkers.add(Marker(
        width: 20,
        height: 20,
        point: LatLng(markerData['point']['latitude'],
            markerData['point']['longitude']),
        builder: (context) =>
            GestureDetector(
              onTap: () {
                // Replace 123 with the actual ID of the marker
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MyFormPage(markerId: 123)));
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