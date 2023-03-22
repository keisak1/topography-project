import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_plus_background_downloading/fmtc_plus_background_downloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map_animated_marker/flutter_map_animated_marker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:topography_project/src/LocallySavedMarkersPage/locallySavedMarkers.dart';
import 'dart:async';
import '../../../Models/Project.dart';
import '../../../Models/User.dart';
import '../../../Models/Zone.dart';
import '../application/homepage_utilities.dart';

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
  bool isButtonOn = false;
  final Location _locationService = Location();
  StreamSubscription<LocationData>? locationSubscription;

  late Future<Project> project;
  late Future<User> user;
  late Future<Zone> zone;

  @override
  void initState() {
    super.initState();
    user = fetchUser();
    project = fetchProject();
    zone = fetchZone();
    loadPrefs();
    _mapController = MapController();
    WidgetsBinding.instance.addObserver(this);
    initLocationService();
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    downloadZones();
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
      saveData(currentLocationGlobal!.latitude, currentLocationGlobal?.longitude); // save data when app is paused
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
          currentLocationGlobal = locationData;
          heading = locationData.heading!;
        });
      });
    } else {
      savedLocation = LatLng(currentLocationGlobal!.latitude!, currentLocationGlobal!.longitude!);
      locationSubscription?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    LatLng currentLatLng;

    if (currentLocationGlobal != null && isButtonOn == true) {
      currentLatLng =
          LatLng(currentLocationGlobal!.latitude!,
              currentLocationGlobal!.longitude!);
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
        child: Column(
          children: [
            Expanded(child: ListView(
              children: <Widget>[
                DrawerHeader(
                  decoration: const BoxDecoration(
                      color: Colors.black,
                      image: DecorationImage(
                          image: AssetImage("./lib/resources/topographic_regions1.png"),
                          fit: BoxFit.cover
                      )
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.projects,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ), //dar add ao file |10n
                ),
                FutureBuilder<User>(
                  future: user,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final user = snapshot.data!;
                      return Column(
                        children: user.projects.map((project) {
                          return ExpansionTile(
                            title: Text(project.name),
                            children: project.zones.map((zone) {
                              return ListTile(
                                title: Text(zone.name),
                                onTap: () {
                                  _mapController.move(LatLng(zone.centerLat, zone.centerLong), zone.zoom);
                                },
                              );
                            }).toList(),
                          );
                        }).toList(),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Error loading user data');
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                ),

              ],
            ),),
            Align(
                alignment: FractionalOffset.bottomCenter,
                // This container holds all the children that will be aligned
                // on the bottom and should not scroll with the above ListView
                child: Column(
                  children: <Widget>[
                    ListTile(
                        leading: const Icon(Icons.cloud_upload),
                        title: Text(
                          AppLocalizations.of(context)!.locallySavedMarkers,
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () =>
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => locallySavedMarkers()),
                            )),
                  ],
                ))
          ],
        )
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
                        image: DecorationImage(
                            image: AssetImage("./lib/resources/topographic_regions1.png"),
                            fit: BoxFit.cover
                        )
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
                              fontSize: 14,
                              //fontWeight: FontWeight.bold,
                            ),
                          ),
                          //const SizedBox(height: 8.0),
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
                  ),
                  /*Row(children: [
                    SizedBox(width: 240),
                    // add some spacing between text and button
                    TextButton(
                      onPressed: () async {
                        if (Provider.of<LocaleProvider>(context,
                            listen: false)
                            .locale
                            .toString() ==
                            'en_EN') {
                          _changeLocale(Locale('pt', 'PT'));
                        } else if (Provider.of<LocaleProvider>(context,
                            listen: false)
                            .locale
                            .toString() ==
                            'pt_PT') {
                          _changeLocale(Locale('en', 'EN'));
                        }
                        await AppLocalizations.delegate.load(
                            Provider.of<LocaleProvider>(context,
                                listen: false)
                                .locale);
                        setState(() {});
                      },
                      child: Text(
                        AppLocalizations.of(context)!.language,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ]),*/
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
                          style: const TextStyle(fontSize: 14),
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
