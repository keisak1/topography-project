import 'dart:math';
import 'package:another_flushbar/flushbar.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:elegant_notification/resources/arrays.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:fmtc_plus_background_downloading/fmtc_plus_background_downloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map_animated_marker/flutter_map_animated_marker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topography_project/src/HomePage/presentation/widgets/distance_direction.dart';
import 'package:topography_project/src/LocallySavedMarkersPage/locallySavedMarkers.dart';
import 'dart:async';
import '../../../Models/User.dart';
import '../../../main.dart';
import '../application/homepage_utilities.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class MyHomePage extends StatefulWidget {
  static const String route = '/live_location';

  const MyHomePage(
      {super.key,
      Locale? locale,
      void Function(dynamic newLocale)? onLocaleChange});

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
  bool checkPressed = false;
  bool markers = false;
  double minDistance = double.infinity;
  double angle = 0;

  String mapAPI =
      "https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoia2Vpc2FraSIsImEiOiJjbGV1NzV5ZXIwMWM2M3ltbGlneXphemtpIn0.htpiT-oaFiXGCw23sguJAw";
  final List<String> mapAPIs = [
    "https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoia2Vpc2FraSIsImEiOiJjbGV1NzV5ZXIwMWM2M3ltbGlneXphemtpIn0.htpiT-oaFiXGCw23sguJAw",
    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
    "https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
    "https://a.tile.opentopomap.org/{z}/{x}/{y}.png"
  ];

  final List<String> mapAPItitles = [
    "Mapbox Streets",
    "OpenStreetMap",
    "Humanitarian focused OSM",
    "OpenTopoMap"
  ];

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

  void _onAPISelected(int i) {
    setState(() {
      mapAPI = mapAPIs[i];
    });
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

  void _changeLocale(Locale locale) {
    setState(() {
      Provider.of<LocaleProvider>(context, listen: false).changeLocale(locale);
    });
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    final List<String> mapAPIsubtitles = [
      AppLocalizations.of(context)!.mapBox,
      AppLocalizations.of(context)!.osm,
      AppLocalizations.of(context)!.hot,
      AppLocalizations.of(context)!.otm,
    ];
    int selectedTile = 0; // initialize the selected tile index

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
                          child: Align(
                              alignment: Alignment.topRight,
                              child: Row(children: [
                                Text(
                                  AppLocalizations.of(context)!.settings,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 20),
                                ),
                                const SizedBox(
                                  width: 110,
                                ),
                                TextButton(
                                  onPressed: () async {
                                    if (Provider.of<LocaleProvider>(context,
                                                listen: false)
                                            .locale
                                            .toString() ==
                                        'en_EN') {
                                      _changeLocale(const Locale('pt', 'PT'));
                                    } else if (Provider.of<LocaleProvider>(
                                                context,
                                                listen: false)
                                            .locale
                                            .toString() ==
                                        'pt_PT') {
                                      _changeLocale(const Locale('en', 'EN'));
                                    }
                                    await AppLocalizations.delegate.load(
                                        Provider.of<LocaleProvider>(context,
                                                listen: false)
                                            .locale);
                                    setState(() {});
                                  },
                                  child: Stack(
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.language,
                                        style: TextStyle(
                                          fontSize: 16,
                                          foreground: Paint()
                                            ..style = PaintingStyle.stroke
                                            ..strokeWidth = 2
                                            ..color = Colors.black,
                                        ),
                                      ),
                                      Text(
                                        AppLocalizations.of(context)!.language,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ])),
                          //dar add ao file |10n
                        ),
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            //crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                isButtonOn ? 'GPS On' : 'GPS Off',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                  fontSize: 14,
                                  //fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8.0),
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
                        ExpansionTile(
                            subtitle: selectedOption.isNotEmpty
                                ? Column(
                                    children: selectedOption.map((option) {
                                      if (option == 'Semi-complete markers') {
                                        return Text(
                                            AppLocalizations.of(context)!
                                                .semicomplete,
                                            style: const TextStyle(
                                                color: Colors.blueAccent));
                                      } else if (option == 'All markers') {
                                        return Text(
                                            AppLocalizations.of(context)!
                                                .allMarkers,
                                            style: const TextStyle(
                                                color: Colors.blueAccent));
                                      } else if (option == 'Complete markers') {
                                        return Text(
                                            AppLocalizations.of(context)!
                                                .complete,
                                            style: const TextStyle(
                                                color: Colors.blueAccent));
                                      } else if (option ==
                                          'Incomplete markers') {
                                        return Text(
                                            AppLocalizations.of(context)!
                                                .incomplete,
                                            style: const TextStyle(
                                                color: Colors.blueAccent));
                                      } else {
                                        return Text(
                                            AppLocalizations.of(context)!
                                                .optionsSelected,
                                            style: const TextStyle(
                                                color: Colors.orangeAccent));
                                      }
                                    }).toList(),
                                  )
                                : Text(
                                    AppLocalizations.of(context)!
                                        .optionsSelected,
                                    style: const TextStyle(
                                        color: Colors.blueAccent)),
                            backgroundColor:
                                const Color.fromRGBO(48, 56, 76, 1.0),
                            collapsedIconColor: Colors.white,
                            title: Text(AppLocalizations.of(context)!.filters,
                                style: const TextStyle(color: Colors.white)),
                            children: [
                              ListTile(
                                title: Text(
                                    AppLocalizations.of(context)!.incomplete,
                                    style:
                                        const TextStyle(color: Colors.white)),
                                onTap: () {
                                  isSelecting = true;
                                  setState(() {
                                    if (!selectedOption.contains(options[0])) {
                                      if (selectedOption.contains(options[3])) {
                                        selectedOption.clear();
                                        selectedOption.add(options[0]);
                                      } else if (selectedOption
                                              .contains(options[1]) &&
                                          selectedOption.contains(options[2])) {
                                        selectedOption.clear();
                                        selectedOption.add(options[3]);
                                      } else {
                                        selectedOption.add(options[0]);
                                      }
                                    } else {
                                      selectedOption.remove(options[0]);
                                    }
                                  });
                                  String markerData =
                                      AppLocalizations.of(context)!.incomplete;
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
                                title: Text(
                                    AppLocalizations.of(context)!.semicomplete,
                                    style:
                                        const TextStyle(color: Colors.white)),
                                onTap: () {
                                  isSelecting = true;
                                  setState(() {
                                    if (!selectedOption.contains(options[1])) {
                                      if (selectedOption.contains(options[3])) {
                                        selectedOption.clear();
                                        selectedOption.add(options[1]);
                                      } else if (selectedOption
                                              .contains(options[0]) &&
                                          selectedOption.contains(options[2])) {
                                        selectedOption.clear();
                                        selectedOption.add(options[3]);
                                      } else {
                                        selectedOption.add(options[1]);
                                      }
                                    } else {
                                      selectedOption.remove(options[1]);
                                    }
                                  });
                                  String markerData =
                                      AppLocalizations.of(context)!
                                          .semicomplete;
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
                                title: Text(
                                    AppLocalizations.of(context)!.complete,
                                    style:
                                        const TextStyle(color: Colors.white)),
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
                                  String markerData =
                                      AppLocalizations.of(context)!.complete;
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
                                title: Text(
                                    AppLocalizations.of(context)!.allMarkers,
                                    style:
                                        const TextStyle(color: Colors.white)),
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
                                  String markerData =
                                      AppLocalizations.of(context)!.allMarkers;
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
                        ExpansionTile(
                          backgroundColor:
                              const Color.fromRGBO(48, 56, 76, 1.0),
                          collapsedIconColor: Colors.white,
                          title: Text(AppLocalizations.of(context)!.selectMap,
                              style: const TextStyle(color: Colors.white)),
                          children: [
                            for (int i = 0; i < mapAPIs.length; i++)
                              ListTile(
                                splashColor: Colors.orangeAccent,
                                title: Text(
                                  mapAPItitles[i],
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedTile =
                                        i; // update the selected tile index
                                    mapAPI = mapAPIs[
                                        i]; // update the selected map API
                                  });
                                },
                                subtitle: Text(
                                  mapAPIsubtitles[i],
                                  style: const TextStyle(
                                      color: Colors.orangeAccent),
                                ),
                              ),
                          ],
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
                              Icons.info_outline_rounded,
                              color: Colors.white,
                            ),
                            title: const Text(
                              "Info",
                              style:
                                  TextStyle(fontSize: 14, color: Colors.white),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor:
                                        const Color.fromRGBO(48, 56, 76, 1.0),
                                    title: Text(
                                      AppLocalizations.of(context)!.createdBy,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    content: Text(
                                      AppLocalizations.of(context)!.credits,
                                      style: const TextStyle(
                                          color: Colors.orangeAccent),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
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
                              onTap: () async {
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                );
                                await prefs.setBool('loggedOut', true);
                                Navigator.pop(
                                    context); // Close the loading dialog
                                  Navigator.pushReplacementNamed(context, '/');
                              }),
                          // add some spacing between text and button
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
                              urlTemplate: mapAPI,
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
                      checkPressed
                          ? FutureBuilder<List<Marker>>(
                              future: filterMarkers(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  List<Marker>? markersList = snapshot.data;

                                  if (markersList != null &&
                                      markersList.isNotEmpty) {
                                    markers = true;
                                    Marker closestMarker = markersList.first;
                                    double minDistance = calculateDistance(
                                      currentLatLng.latitude,
                                      currentLatLng.longitude,
                                      closestMarker.point.latitude,
                                      closestMarker.point.longitude,
                                    );
                                    for (Marker marker in markersList) {
                                      double distance = calculateDistance(
                                        currentLatLng.latitude,
                                        currentLatLng.longitude,
                                        marker.point.latitude,
                                        marker.point.longitude,
                                      );
                                      if (distance < minDistance) {
                                        closestMarker = marker;
                                        minDistance = distance;
                                      }
                                    }
                                    // Calculate the angle between the user's location and the closest marker
                                    double angle = atan2(
                                          closestMarker.point.longitude -
                                              currentLatLng.longitude,
                                          closestMarker.point.latitude -
                                              currentLatLng.latitude,
                                        ) *
                                        180 /
                                        pi;
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(height: 250),
                                        InkWell(
                                          child: ElegantNotification(
                                            width: 360,
                                            notificationPosition:
                                                NotificationPosition.center,
                                            background: const Color.fromRGBO(
                                                48, 56, 76, 1.0),
                                            animation: AnimationType.fromTop,
                                            title: Text(
                                              "${AppLocalizations.of(context)!.building}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                              ),
                                            ),
                                            description: Text(
                                              "${AppLocalizations.of(context)!.close} ${minDistance.toStringAsFixed(2)} km",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                            icon: Transform.rotate(
                                              angle: angle * pi / 180,
                                              child: const Icon(
                                                Icons.arrow_upward_rounded,
                                                color: Colors.lightGreenAccent,
                                              ),
                                            ),
                                            showProgressIndicator: false,
                                            autoDismiss: false,
                                            onDismiss: () {
                                              checkPressed = false;
                                              setState(() {});
                                            },
                                          ),
                                        )
                                      ],
                                    );
                                  } else {
                                    return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(height: 250),
                                          InkWell(
                                              child: ElegantNotification(
                                            width: 360,
                                            notificationPosition:
                                                NotificationPosition.center,
                                            background: const Color.fromRGBO(
                                                48, 56, 76, 1.0),
                                            animation: AnimationType.fromTop,
                                            title: Text(
                                              "${AppLocalizations.of(context)!.building}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                //fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            description: Text(
                                              "${AppLocalizations.of(context)!.buildingNotFound}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                //fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            icon: Transform.rotate(
                                              angle: 0 * pi / 180,
                                              child: const Icon(
                                                Icons.arrow_upward_rounded,
                                                color: Colors.lightGreenAccent,
                                              ),
                                            ),
                                            showProgressIndicator: false,
                                            autoDismiss: false,
                                            onDismiss: () {
                                              checkPressed = false;
                                              setState(() {});
                                            },
                                          ))
                                        ]);
                                  }
                                } else if (snapshot.hasError) {
                                  return Text(
                                      'Error loading markers: ${snapshot.error}');
                                } else {
                                  return const CircularProgressIndicator();
                                }
                              },
                            )
                          : Container(),
                    ],
                  ),
            floatingActionButton: Stack(
              children: [
                Positioned(
                  bottom: 60,
                  right: 0,
                  child: FloatingActionButton(
                    onPressed: () {
                      if (checkPressed == false) {
                        checkPressed = true;
                      } else {
                        checkPressed = false;
                      }
                      setState(() {});
                    },
                    heroTag: null,
                    backgroundColor: const Color.fromRGBO(48, 56, 76, 1.0),
                    child: const Icon(Icons.notifications),
                  ),
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
