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

class MyHomePage extends StatefulWidget {
  static const String route = '/live_location';

  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var scaffoldKey = GlobalKey<ScaffoldState>();
  late final MapController _mapController;
  bool showMarker = true;
  List<LatLng> polygonPoints = [
    LatLng(41.169555000318596, -8.622181073069193),
    LatLng(41.16586681398453, -8.615138211779408),
    LatLng(41.16909398838012, -8.608095350489625),
    LatLng(41.174702746609, -8.608401561850052)
  ];

/* LocationData? _currentLocation;
  bool _liveUpdate = false;
  bool _permission = false;
  String? _serviceError = '';
  final Location _locationService = Location();*/

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

    double currentZoom = 13;

    bool shouldShowMarker() {
      return currentZoom >= 13;
    }
    /*  initLocationService();*/
  }

  /*
  void initLocationService() async {
    await _locationService.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
    );

    LocationData? location;
    bool serviceEnabled;
    bool serviceRequestResult;
    try {
      serviceEnabled = await _locationService.serviceEnabled();

      if (serviceEnabled) {
        final permission = await _locationService.requestPermission();
        _permission = permission == PermissionStatus.granted;

        if (_permission) {
          location = await _locationService.getLocation();
          _currentLocation = location;
          _locationService.onLocationChanged
              .listen((LocationData result) async {
            if (mounted) {
              setState(() {
                _currentLocation = result;

                // If Live Update is enabled, move map center
                if (_liveUpdate) {
                  _mapController.move(
                      LatLng(_currentLocation!.latitude!,
                          _currentLocation!.longitude!),
                      _mapController.zoom);
                }
              });
            }
          });
        }
      } else {
        serviceRequestResult = await _locationService.requestService();
        if (serviceRequestResult) {
          initLocationService();
          return;
        }
      }
    } on PlatformException catch (e) {
      debugPrint(e.toString());
      if (e.code == 'PERMISSION_DENIED') {
        _serviceError = e.message;
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        _serviceError = e.message;
      }
      location = null;
    }
  }
*/
  @override
  Widget build(BuildContext context) {
    /* LatLng currentLatLng;

    if (_currentLocation != null) {
      currentLatLng =
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
    } else {
      currentLatLng = LatLng(0, 0);
    }*/

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
                Navigator.pop(context);
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
                    title: const Text('Something'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
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
              maxZoom: 20,
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
            ]),
      ),
      //],
      //),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: Text(
          AppLocalizations.of(context)!.buildings,
        ),
        backgroundColor: Colors.black,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
