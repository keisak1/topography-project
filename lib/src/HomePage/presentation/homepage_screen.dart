import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_plus_background_downloading/fmtc_plus_background_downloading.dart';
import 'package:topography_project/src/FormPage/formpage_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map_animated_marker/flutter_map_animated_marker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  static const String route = '/live_location';

  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  var scaffoldKey = GlobalKey<ScaffoldState>();


  late final MapController _mapController;
  bool showMarker = true;
  List<LatLng> polygonPoints = [
    LatLng(41.169555000318596, -8.622181073069193),
    LatLng(41.16586681398453, -8.615138211779408),
    LatLng(41.16909398838012, -8.608095350489625),
    LatLng(41.174702746609, -8.608401561850052)
  ];

  final region = RectangleRegion(
    LatLngBounds(
      LatLng(41.17380930243528, -8.613922487178936), // North West
      LatLng(41.17031240259549, -8.61030686985005), // South East
    ),
  );

  late SharedPreferences _prefs;
  late int numbTiles = 0;
  bool isButtonOn = false;

  double? latitude;
  double? longitude;
  late LatLng savedLocation = LatLng(0.0, 0.0);
  LocationData? _currentLocation;
  late double heading = 0.0;
  final Location _locationService = Location();
  StreamSubscription<LocationData>? locationSubscription;

  String strMarkers = "";
  List<Marker> savedMarkers = [];
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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addObserver(this);
    initLocationService();
    saveMarkers();
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    _downloadZones();

    _prefs = await SharedPreferences.getInstance();
    latitude = _prefs.getDouble('latitude')!;
    longitude = _prefs.getDouble('longitude')!;

    strMarkers = _prefs.getString("markers")!;
    Map<String, dynamic> markersMap = jsonDecode(strMarkers);
    formMarkers(markersMap);
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

  Future<void> _downloadZones() async {
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

    numbTiles = await FMTC.instance('savedTiles').download.check(downloadable);
    AndroidResource notificationIcon =
        AndroidResource(name: 'ic_notification_icon', defType: 'drawable');

    await FMTC.instance('savedTiles').download.startBackground(
        region: downloadable,
        progressNotificationIcon: "@drawable/ic_launcher",
        backgroundNotificationIcon: notificationIcon);
  }

  Future<void> _saveData(double? lat, double? longi) async {
    if (lat != null) {
      await _prefs.setDouble('Latitude', lat);
    }
    if (longi != null) {
      await _prefs.setDouble('Longitude', longi);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      double? lat = _currentLocation!.latitude;
      double? long = _currentLocation?.longitude;
      _saveData(lat, long); // save data when app is paused
    }
  }

  void initLocationService() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        // Location services are not enabled on the device.
        return;
      }
    }

    permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        // Location permission not granted.
        return;
      }
    }

    if (latitude == null && longitude == null) {
      _locationService.onLocationChanged
          .listen((LocationData currentLocation) async {
        _currentLocation = currentLocation;
        heading = currentLocation.heading!;
        await _prefs.setDouble('latitude', currentLocation.latitude ?? 0.0);
        await _prefs.setDouble('longitude', currentLocation.longitude ?? 0.0);
      });
    } else {
      savedLocation = LatLng(latitude!, longitude!);
    }
  }

  void onButtonToggle(int index) {
    setState(() {
      isButtonOn = !isButtonOn;
    });
    if (isButtonOn) {
      locationSubscription = _locationService.onLocationChanged
          .listen((LocationData locationData) {
        setState(() {
          _currentLocation = locationData;
          heading = locationData.heading!;
        });
      });
    } else {
      locationSubscription?.cancel();
    }
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> markerList = [];
    for (Marker marker in markers) {
      Map<String, dynamic> markerMap = {
        'latitude': marker.point.latitude,
        'longitude': marker.point.longitude,
      };
      markerList.add(markerMap);
    }
    return {
      'markers': markerList,
    };
  }

  Future<void> saveMarkers() async {
    bool markersAdded = false;
    for (final Marker marker in markers) {
      bool markerExists = savedMarkers.any((savedMarker) => savedMarker.point == marker.point);
      if (!markerExists) {
        savedMarkers.add(marker);
        markersAdded = true;
      }
    }

    if (markersAdded) {
      await _prefs.setString('markers', jsonEncode(toJson()));
    }
  }

  /*List<Marker> MarkersExist(){
    if(savedMarkers.isEmpty){
      return markers;
    }else{
      return savedMarkers;
    }
  }*/

  @override
  Widget build(BuildContext context) {
    LatLng currentLatLng;

    if (_currentLocation != null && isButtonOn == true) {
      currentLatLng =
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
    } else {
      currentLatLng = savedLocation;
    }

    return FMTCBackgroundDownload(
        child: Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(
                  Icons.menu,
                  size: 40.0,
                ),
                color: Colors.black,
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          actions: <Widget>[
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    size: 40.0,
                  ),
                  color: Colors.black,
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                );
              },
            )
          ],
          backgroundColor: Colors.transparent,
          elevation: 0.0),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Text(
                AppLocalizations.of(context)!.zones,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ), //dar add ao file |10n
            ),
            ListTile(
              title: const Text('Zona 1'),
              onTap: () {
                _mapController.move(
                    LatLng(41.17209721775161, -8.611916195059322), 17);
              },
            ),
            ListTile(
              title: const Text('Zona 2'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: <Widget>[
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.settings,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ), //dar add ao file |10n
                  ),
                  ListTile(
                    title: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        //crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            isButtonOn ? 'GPS On' : 'GPS Off',
                            style: const TextStyle(
                              fontSize: 20.0,
                              //fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          ToggleButtons(
                            isSelected: [isButtonOn],
                            onPressed: (int index) {
                              onButtonToggle(index);
                            },
                            children: [
                              Icon(isButtonOn
                                  ? Icons.location_on
                                  : Icons.location_off),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Something'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
            ),
            Align(
                alignment: FractionalOffset.bottomCenter,
                // This container holds all the children that will be aligned
                // on the bottom and should not scroll with the above ListView
                child: Column(
                  children: <Widget>[
                    ListTile(
                        leading: const Icon(Icons.logout),
                        title: Text(
                          AppLocalizations.of(context)!.logout,
                          style: const TextStyle(fontSize: 20),
                        ),
                        onTap: () =>
                            Navigator.pushReplacementNamed(context, '/')),
                  ],
                ))
          ],
        ),
      ),
      body: Center(
        child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: LatLng(41.17209721775161, -8.611916195059322),
              zoom: 10,
              maxZoom: 18.499999,
              minZoom: 0,
              onPositionChanged: (position, _) {
                setState(() {
                  currentZoom = position.zoom!;
                });
              },
            ),
            children: [
              TileLayer(
                tileProvider: FMTC.instance('savedTiles').getTileProvider(),
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoia2Vpc2FraSIsImEiOiJjbGV1NzV5ZXIwMWM2M3ltbGlneXphemtpIn0.htpiT-oaFiXGCw23sguJAw',
                userAgentPackageName: 'dev.fleaflet.flutter_map.example',
              ),
              if (currentLatLng != null)
                AnimatedMarkerLayer(
                  options: AnimatedMarkerLayerOptions(
                    duration: const Duration(
                      milliseconds: 1000,
                    ),
                    marker: Marker(
                      width: 80.0,
                      height: 80.0,
                      point: currentLatLng,
                      builder: (context) => Transform.rotate(
                        angle: heading * (pi / 180),
                        child: const Icon(
                          Icons.navigation,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              PolygonLayer(
                polygonCulling: false,
                polygons: [
                  Polygon(
                      points: polygonPoints,
                      color: Colors.redAccent.withOpacity(0.5),
                      isFilled: shouldHideHighlight(currentZoom),
                      isDotted: false),
                ],
              ),
              MarkerLayer(
                markers: shouldShowMarker(currentZoom) ? savedMarkers : [],
              ),

              //MarkerLayerOptions(markers: [userMarker]),
              //flutterMapLocation,
            ]),
      ),
      //],
      //),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController.move(currentLatLng, 17);
        },
        //label: Text(
        //AppLocalizations.of(context)!.buildings,
        //),
        backgroundColor: Colors.black,
        child: const Icon(Icons.my_location_outlined),
      ),
      //floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    ));
  }

  double currentZoom = 13;

  bool shouldHideHighlight(double currentZoom) {
    return currentZoom <= 16;
  }

  bool shouldShowMarker(double currentZoom) {
    return currentZoom >= 13;
  }
}
