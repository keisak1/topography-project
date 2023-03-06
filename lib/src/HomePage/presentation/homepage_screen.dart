import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:topography_project/src/FormPage/formpage_screen.dart';
import 'package:topography_project/src/HomePage/presentation/widgets/sidebar_button.dart';
import 'package:topography_project/src/HomePage/presentation/widgets/settings_button.dart';
import 'package:topography_project/src/SettingsPage/settingspage_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver{
  var scaffoldKey = GlobalKey<ScaffoldState>();
  late final MapController _mapController;
  bool showMarker = true;
  List<LatLng> polygonPoints = [
    LatLng(41.169555000318596, -8.622181073069193),
    LatLng(41.16586681398453, -8.615138211779408),
    LatLng(41.16909398838012, -8.608095350489625),
    LatLng(41.174702746609, -8.608401561850052)
  ];
  late SharedPreferences _prefs;

  bool isButtonOn = false;

  LocationData? _currentLocation;
  bool _liveUpdate = false;
  bool _permission = false;
  String? _serviceError = '';
  final Location _locationService = Location();
  StreamSubscription<LocationData>? locationSubscription;

  void _settingsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addObserver(this);


    initLocationService();
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
      print("Saving");
      _saveData(lat,long); // save data when app is paused
    }
  }

  void initLocationService() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    _prefs = await SharedPreferences.getInstance();

    double? latitude = _prefs.getDouble('Latitude');
    double? longitude = _prefs.getDouble('Longitude');

    print("LATITUDE E LONGITUDE");
    print(latitude);
    print(longitude);
    _serviceEnabled = await _locationService.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationService.requestService();
      if (!_serviceEnabled) {
        // Location services are not enabled on the device.
        return;
      }
    }

    _permissionGranted = await _locationService.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationService.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        // Location permission not granted.
        return;
      }
    }

    if (latitude == null && longitude == null) {
      _locationService.onLocationChanged.listen((LocationData currentLocation) async {
        _currentLocation = currentLocation;
        await _prefs.setDouble('latitude', currentLocation.latitude ?? 0.0);
        await _prefs.setDouble('longitude', currentLocation.longitude ?? 0.0);
      });
    }else{
      print("im setting the location");
      _currentLocation = LatLng(latitude!, longitude!) as LocationData?;
    }
  }


  void onButtonToggle(int index) {
    setState(() {
      isButtonOn = !isButtonOn;
    });
    if (isButtonOn) {
      locationSubscription =
          _locationService.onLocationChanged.listen((LocationData locationData) {
            setState(() {
              _currentLocation = locationData;
            });
          });
    } else {
      locationSubscription?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    LatLng currentLatLng;

    if (_currentLocation != null) {
      currentLatLng =
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
    } else {
      currentLatLng = LatLng(0, 0);
    }

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
          child: Icon(
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
      Marker(
        width: 80.0,
        height: 80.0,
        point: currentLatLng,
        builder: (context) => const Icon(
          Icons.navigation,
          color: Colors.blue,
          size: 30,
        ),
      ),
    ];

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: Icon(
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
                  icon: Icon(
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
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Text(
                AppLocalizations.of(context)!.zones,
                style: TextStyle(color: Colors.white, fontSize: 20),
              ), //dar add ao file |10n
            ),
            ListTile(
              title: const Text('Zona 1'),
              onTap: () {
                _mapController.move(LatLng(41.17209721775161, -8.611916195059322), 17);
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
                    decoration: BoxDecoration(
                      color: Colors.black,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.settings,
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ), //dar add ao file |10n
                  ),
                  ListTile(
                    title: Container(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        //crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            isButtonOn ? 'GPS On' : 'GPS Off',
                            style: TextStyle(
                              fontSize: 20.0,
                              //fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          ToggleButtons(
                            children: [
                              Icon(isButtonOn ? Icons.location_on : Icons.location_off),
                            ],
                            isSelected: [isButtonOn],
                            onPressed: (int index) {
                              onButtonToggle(index);
                            },
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
                  /*ToggleButtons(
                    children: [
                      Icon(isButtonOn ? Icons.location_on : Icons.location_off),
                    ],
                    isSelected: [isButtonOn],
                    onPressed: (int index) {
                      onButtonToggle(index);
                    },
                  ),*/
                ],
              ),
            ),
            Container(
                // This align moves the children to the bottom
                child: Align(
                    alignment: FractionalOffset.bottomCenter,
                    // This container holds all the children that will be aligned
                    // on the bottom and should not scroll with the above ListView
                    child: Container(
                        child: Column(
                      children: <Widget>[
                        ListTile(
                            leading: Icon(Icons.logout),
                            title: Text(
                              AppLocalizations.of(context)!.logout,
                              style: TextStyle(fontSize: 20),
                            ),
                            onTap: () =>
                                Navigator.pushReplacementNamed(context, '/')),
                      ],
                    ))))
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
                  print(currentZoom);
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoia2Vpc2FraSIsImEiOiJjbGV1NzV5ZXIwMWM2M3ltbGlneXphemtpIn0.htpiT-oaFiXGCw23sguJAw',
                userAgentPackageName: 'dev.fleaflet.flutter_map.example',
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
                markers: shouldShowMarker(currentZoom) ? markers : [],
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
        child: const Icon(Icons.my_location_outlined),
        //label: Text(
          //AppLocalizations.of(context)!.buildings,
        //),
        backgroundColor: Colors.black,
      ),
      //floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  double currentZoom = 13;

  bool shouldHideHighlight(double currentZoom) {
    return currentZoom <= 16;
  }

  bool shouldShowMarker(double currentZoom) {
    return currentZoom >= 13;
  }
}
