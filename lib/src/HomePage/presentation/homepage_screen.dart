import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_plus_background_downloading/fmtc_plus_background_downloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map_animated_marker/flutter_map_animated_marker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:topography_project/src/HomePage/presentation/widgets/distance_direction.dart';
import 'package:topography_project/src/LocallySavedMarkersPage/locallySavedMarkers.dart';
import 'package:topography_project/src/styles/colors.dart';
import 'dart:async';
import '../../../Models/User.dart';
import '../application/homepage_utilities.dart';

class MyHomePage extends StatefulWidget {
  static const String route = '/live_location';

  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  var scaffoldKey = GlobalKey<ScaffoldState>();
  late bool _isLoading;
  late final MapController _mapController;
  bool showMarker = true;
  bool isButtonOn = true;
  final Location _locationService = Location();
  StreamSubscription<LocationData>? locationSubscription;
  late Future<User> user;
  final selectedItems = <String>{};
  bool isSelecting = false;

  @override
  void initState() {
    _isLoading = true;
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _isLoading = false;
      });
    });
    super.initState();
    user = fetchData();
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
      saveData(currentLocationGlobal!.latitude,
          currentLocationGlobal?.longitude); // save data when app is paused
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
      savedLocation = LatLng(
          currentLocationGlobal!.latitude!, currentLocationGlobal!.longitude!);
      locationSubscription?.cancel();
    }
  }

  List<Polygon> getPolygonsList(User userData) {
    final projects = userData.projects;
    List<Polygon> polygons = [];
    for (final project in projects) {
      for (final zone in project.zones) {
        final bboxList = zone.bbox.toList();
        List<LatLng> latLngList = [];

        for (var bbox in bboxList) {
          latLngList.add(LatLng(bbox.lat, bbox.lng));
        }
        final polygon = Polygon(
          borderColor: Colors.blueGrey,
          borderStrokeWidth: 4.0,
          points: latLngList,
          color: Colors.blueAccent.withOpacity(0.4),
          isFilled: shouldHideHighlight(currentZoom),
          isDotted: false,
        );
        polygons.add(polygon);
      }
    }
    return polygons;
  }

  /*void show_Icon_Flushbar(BuildContext context) {
    Flushbar(
      icon: const Icon(
        Icons.email_outlined,
        color: Colors.white,
        size: 30,
      ),
      backgroundColor: Color(0xFF0277BD),
      duration: Duration(seconds: 4),
      message: "This email is already registered.",
      messageSize: 18,
      titleText: const Text("Flushbar with Icon.",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold,
              color: Colors.white)),
    ).show(context);
  }*/

  @override
  Widget build(BuildContext context) {
    LatLng currentLatLng;
    const tag1 = 'button1';
    const tag2 = 'button2';

    if (currentLocationGlobal != null && isButtonOn == true) {
      currentLatLng = LatLng(
          currentLocationGlobal!.latitude!, currentLocationGlobal!.longitude!);

      currentLatLng = LatLng(
          currentLocationGlobal!.latitude!, currentLocationGlobal!.longitude!);
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
                      color: const Color.fromRGBO(48, 56, 76, 1.0),
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
                        color: const Color.fromRGBO(48, 56, 76, 1.0),
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
                backgroundColor: const Color.fromRGBO(58, 66, 86, 1.0),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: <Widget>[
                          DrawerHeader(
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                image: DecorationImage(
                                    image: AssetImage(
                                        "./lib/resources/topographic_regions1.png"),
                                    fit: BoxFit.cover)),
                            child: Text(
                              AppLocalizations.of(context)!.projects,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 20),
                            ), //dar add ao file |10n
                          ),
                          FutureBuilder<User>(
                            future: user,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final user = snapshot.data!;
                                return Column(
                                  children: user.projects.map((project) {
                                    if (project.zones.isEmpty) {
                                      return ListTile(
                                        title: Text(
                                          project.name,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        onTap: () {
                                          _mapController.move(
                                              LatLng(project.centerLat,
                                                  project.centerLong),
                                              (project.zoom * 16.0));
                                        },
                                      );
                                    } else {
                                      return ExpansionTile(
                                        backgroundColor: const Color.fromRGBO(
                                            48, 56, 76, 1.0),
                                        collapsedIconColor: Colors.white,
                                        title: Text(project.name,
                                            style: const TextStyle(
                                                color: Colors.white)),
                                        children: project.zones.map((zone) {
                                          return ListTile(
                                            title: Text(zone.zoneLabel,
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                            onTap: () {
                                              _mapController.move(
                                                  LatLng(zone.centerLat,
                                                      zone.centerLong),
                                                  (project.zoom * 16.0));
                                            },
                                          );
                                        }).toList(),
                                      );
                                    }
                                  }).toList(),
                                );
                              } else if (snapshot.hasError) {
                                return const Text('Error loading user data');
                              } else {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                            },
                          ),
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
                                leading: const Icon(
                                  Icons.cloud_upload,
                                  color: Colors.white,
                                ),
                                title: Text(
                                  AppLocalizations.of(context)!
                                      .locallySavedMarkers,
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.white),
                                ),
                                onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const locallySavedMarkers()),
                                    )),
                          ],
                        ))
                  ],
                )),
            endDrawer: Drawer(
              backgroundColor: const Color.fromRGBO(58, 66, 86, 1.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        DrawerHeader(
                          decoration: const BoxDecoration(
                              color: Color.fromRGBO(48, 56, 76, 1.0),
                              image: DecorationImage(
                                  image: AssetImage(
                                      "./lib/resources/topographic_regions1.png"),
                                  fit: BoxFit.cover)),
                          child: Text(
                            AppLocalizations.of(context)!.settings,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20),
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
                                    color: Colors.white,
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
                                    Icon(
                                      isButtonOn
                                          ? Icons.location_on
                                          : Icons.location_off,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        ExpansionTile(
                            subtitle: selectedOption.isNotEmpty
                                ? Column(
                                    children: selectedOption
                                        .map((option) => Text(option,
                                            style: const TextStyle(
                                                color: Colors.blueAccent)))
                                        .toList(),
                                  )
                                : Text(AppLocalizations.of(context)!.optionsSelected,
                                    style: const TextStyle(color: Colors.blueAccent)),
                            backgroundColor:
                                const Color.fromRGBO(48, 56, 76, 1.0),
                            collapsedIconColor: Colors.white,
                            title: Text(AppLocalizations.of(context)!.filters,
                                style: const TextStyle(color: Colors.white)),
                            children: [
                              ListTile(
                                title: Text(AppLocalizations.of(context)!.incomplete,
                                    style: TextStyle(color: Colors.white)),
                                onTap: () {
                                  isSelecting = true;
                                  setState(() {
                                    if (!selectedOption.contains(options[0])) {
                                      if (selectedOption.contains(options[3])) {
                                        selectedOption.clear();
                                        selectedOption.add(options[2]);
                                      } else if (selectedOption.contains(options[1]) &&
                                          selectedOption.contains(options[2])) {
                                        selectedOption.clear();
                                        selectedOption.add(options[3]);
                                      }
                                      else {
                                        selectedOption.add(options[0]);
                                      }
                                    } else {
                                      selectedOption.remove(options[0]);
                                    }
                                  });
                                  String markerData = AppLocalizations.of(context)!.incomplete;
                                  final isSelected =
                                      selectedItems.contains(markerData);
                                  if (isSelecting) {
                                    setState(() {
                                      if (isSelected) {
                                        selectedItems.remove(markerData);
                                        isSelecting = false;
                                      } else {
                                        selectedItems.add(markerData);
                                      }
                                    });
                                  }
                                },
                              ),
                              ListTile(
                                title: Text(AppLocalizations.of(context)!.semicomplete,
                                    style: TextStyle(color: Colors.white)),
                                onTap: () {
                                  isSelecting = true;
                                  setState(() {
                                    if (!selectedOption.contains(options[1])) {
                                      if (selectedOption.contains(options[3])) {
                                        selectedOption.clear();
                                        selectedOption.add(options[1]);
                                      }else if (selectedOption.contains(options[0]) &&
                                          selectedOption.contains(options[2])) {
                                        selectedOption.clear();
                                        selectedOption.add(options[3]);
                                      }
                                      else {
                                        selectedOption.add(options[1]);
                                      }
                                    } else {
                                      selectedOption.remove(options[1]);
                                    }
                                  });
                                  String markerData = AppLocalizations.of(context)!.semicomplete;
                                  final isSelected =
                                      selectedItems.contains(markerData);
                                  if (isSelecting) {
                                    setState(() {
                                      if (isSelected) {
                                        selectedItems.remove(markerData);
                                        isSelecting = false;
                                      } else {
                                        selectedItems.add(markerData);
                                      }
                                    });
                                  }
                                },
                              ),
                              ListTile(
                                title: Text(AppLocalizations.of(context)!.complete,
                                    style: TextStyle(color: Colors.white)),
                                onTap: () {
                                  isSelecting = true;
                                  setState(() {
                                    if (!selectedOption.contains(options[2])) {
                                      if (selectedOption.contains(options[0]) &&
                                          selectedOption.contains(options[1])) {
                                        selectedOption.clear();
                                        selectedOption.add(options[3]);
                                      } else if (selectedOption
                                          .contains(options[3])) {
                                        selectedOption.clear();
                                        selectedOption.add(options[2]);
                                      } else {
                                        selectedOption.add(options[2]);
                                      }
                                    } else {
                                      selectedOption.remove(options[2]);
                                    }
                                  });
                                  String markerData = AppLocalizations.of(context)!.complete;
                                  isSelecting = true;
                                  selectedItems.add(markerData);
                                  final isSelected =
                                      selectedItems.contains(markerData);
                                  if (isSelecting) {
                                    setState(() {
                                      if (isSelected) {
                                        selectedItems.remove(markerData);
                                        isSelecting = false;
                                      } else {
                                        selectedItems.add(markerData);
                                      }
                                    });
                                  }
                                },
                              ),
                              ListTile(
                                title: Text(AppLocalizations.of(context)!.allMarkers,
                                    style: TextStyle(color: Colors.white)),
                                onTap: () {
                                  isSelecting = true;
                                  setState(() {
                                    if (!selectedOption.contains(options[3])) {
                                      if (selectedOption.contains(options[0]) ||
                                          selectedOption.contains(options[1]) ||
                                          selectedOption.contains(options[2])) {
                                        selectedOption.clear();
                                        selectedOption.add(options[3]);
                                      } else {
                                        selectedOption.add(options[3]);
                                      }
                                    } else {
                                      selectedOption.remove(options[3]);
                                    }
                                  });
                                  String markerData = AppLocalizations.of(context)!.allMarkers;
                                  final isSelected =
                                      selectedItems.contains(markerData);
                                  if (isSelecting) {
                                    setState(() {
                                      setState(() {
                                        if (isSelected) {
                                          selectedItems.remove(markerData);
                                          isSelecting = false;
                                        } else {
                                          selectedItems.add(markerData);
                                        }
                                      });
                                    });
                                  }
                                },
                              ),
                            ]),
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
                              leading: const Icon(
                                Icons.logout,
                                color: Colors.white,
                              ),
                              title: Text(
                                AppLocalizations.of(context)!.logout,
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.white),
                              ),
                              onTap: () =>
                                  Navigator.pushReplacementNamed(context, '/')),
                        ],
                      ))
                ],
              ),
            ),
            body: _isLoading
                ? Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator()))
                : Stack(
                    children: [
                      FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            center: LatLng(38.756931, -9.15358),
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
                              tileProvider:
                                  FMTC.instance('savedTiles').getTileProvider(),
                              urlTemplate:
                                  'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoia2Vpc2FraSIsImEiOiJjbGV1NzV5ZXIwMWM2M3ltbGlneXphemtpIn0.htpiT-oaFiXGCw23sguJAw',
                              userAgentPackageName:
                                  'dev.fleaflet.flutter_map.example',
                            ),
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
                            FutureBuilder<User>(
                              future: user,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final userData = snapshot.data!;

                                  final polygons = getPolygonsList(userData);
                                  return PolygonLayer(
                                    polygonCulling: false,
                                    polygons: polygons,
                                  );
                                } else {
                                  // Show a loading indicator or an error message
                                  return const CircularProgressIndicator();
                                }
                              },
                            ),
                            FilterMarkers(currentZoom)
                          ]),
                    ],
                  ),
            floatingActionButton: Stack(
              children: [
                FutureBuilder<List<Marker>>(
                  future: filterMarkers(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      List<Marker>? markersList = snapshot.data;
                      if (markersList != null) {
                        return Positioned(
                          bottom: 60,
                          right: 0,
                          child: FloatingActionButton(
                            onPressed: () {
                              ClosestMarkerWidget(
                                userLocation: currentLatLng,
                                markers: markersList,
                              );
                            },
                            heroTag: null,
                            backgroundColor:
                                const Color.fromRGBO(48, 56, 76, 1.0),
                            child: const Icon(Icons.notifications),
                          ),
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
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: FloatingActionButton(
                    onPressed: () {
                      _mapController.move(currentLatLng, 17);
                    },
                    heroTag: null,
                    //label: Text(
                    //AppLocalizations.of(context)!.buildings,
                    //),
                    backgroundColor: const Color.fromRGBO(48, 56, 76, 1.0),
                    child: const Icon(Icons.my_location_outlined),
                  ),
                )
              ],
            )
            //floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
            ));
  }

  double currentZoom = 13;

  bool shouldHideHighlight(double currentZoom) {
    return currentZoom <= 16;
  }
}
