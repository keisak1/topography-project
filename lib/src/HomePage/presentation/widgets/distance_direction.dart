import 'dart:math';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../HomePage/application/homepage_utilities.dart';
import '../../../LocallySavedMarkersPage/locallySavedMarkers.dart';

class ClosestMarkerWidget extends StatefulWidget {
  final LatLng userLocation;

  const ClosestMarkerWidget(
      {super.key, required this.userLocation});

  @override
  State<ClosestMarkerWidget> createState() => _ClosestMarkerWidget();
}

class _ClosestMarkerWidget extends State<ClosestMarkerWidget> {
  late LatLng _userLocation;
  late Future<List<Marker>> markers;
  List<MarkerData> markersForm = [];
  double minDistance = double.infinity;
  bool checkPressed = false;

  @override
  void initState() {
    super.initState();
    markers = filterMarkers();
    _userLocation = widget.userLocation;
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
            if (markersList.isNotEmpty) {
              Marker closestMarker = markersList.first;
              //double minDistance = double.infinity;
              for (Marker marker in markersList) {
                double distance = calculateDistance(
                  _userLocation.latitude,
                  _userLocation.longitude,
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
                closestMarker.point.longitude - _userLocation.longitude,
                closestMarker.point.latitude - _userLocation.latitude,
              );
              angle = angle * 180 / pi;

              return Positioned(
                bottom: 60,
                right: 0,
                child: FloatingActionButton(
                  onPressed: () {
                    if(checkPressed == false) {
                      checkPressed = true;
                      Flushbar(
                        title: "Closest Building",
                        icon: Transform.rotate(
                          angle: angle * pi / 180,
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.lightGreenAccent,
                          ),
                        ),
                        backgroundColor: const Color.fromRGBO(48, 56, 76, 1.0),
                        message: "${AppLocalizations.of(context)!.close} ${minDistance
                            .toStringAsFixed(2)} km",
                        onTap: (flushbar) {
                          checkPressed = false;
                          flushbar.dismiss();
                        },
                      ).show(context);
                    }
                  },
                  heroTag: null,
                  backgroundColor: const Color.fromRGBO(48, 56, 76, 1.0),
                  child: const Icon(Icons.notifications),
                ),
              );
            }

            return Positioned(
              bottom: 60,
              right: 0,
              child: FloatingActionButton(
                onPressed: () {
                  if(checkPressed == false) {
                    checkPressed = true;
                    Flushbar(
                      title: "${AppLocalizations.of(context)!.building}",
                      icon: Transform.rotate(
                        angle: 0 * pi / 180,
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.lightGreenAccent,
                        ),
                      ),
                      backgroundColor: const Color.fromRGBO(48, 56, 76, 1.0),
                      message: "${AppLocalizations.of(context)!.buildingNotFound}",
                      onTap: (flushbar) {
                        checkPressed = false;
                        flushbar.dismiss();
                      },
                    ).show(context);
                  }
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
    );


      //buildClosestMarkerWidget(_userLocation, markers, context);
  }
}

double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

Widget buildClosestMarkerWidget(LatLng userLocation, List<Marker> markers, BuildContext context) {
  bool checkPressed = false;
  if (markers.isNotEmpty) {
    Marker closestMarker = markers.first;
    double minDistance = double.infinity;
    for (Marker marker in markers) {
      double distance = calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
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
      closestMarker.point.longitude - userLocation.longitude,
      closestMarker.point.latitude - userLocation.latitude,
    );
    angle = angle * 180 / pi;

    return Positioned(
      bottom: 60,
      right: 0,
      child: FloatingActionButton(
        onPressed: () {
          if(checkPressed == false) {
            checkPressed = true;
            Flushbar(
              title: "Closest Building",
              icon: Transform.rotate(
                angle: angle * pi / 180,
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.lightGreenAccent,
                ),
              ),
              backgroundColor: const Color.fromRGBO(48, 56, 76, 1.0),
              message: "${AppLocalizations.of(context)!.close} ${minDistance
                  .toStringAsFixed(2)} km",
              onTap: (flushbar) {
                checkPressed = false;
                flushbar.dismiss();
              },
            ).show(context);
          }
          },
        heroTag: null,
        backgroundColor: const Color.fromRGBO(48, 56, 76, 1.0),
        child: const Icon(Icons.notifications),
      ),
    );
  }

  return Positioned(
    bottom: 60,
    right: 0,
    child: FloatingActionButton(
      onPressed: () {
      if(checkPressed == false) {
        checkPressed = true;
        Flushbar(
          title: "${AppLocalizations.of(context)!.building}",
          icon: Transform.rotate(
            angle: 0 * pi / 180,
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: Colors.lightGreenAccent,
            ),
          ),
          backgroundColor: const Color.fromRGBO(48, 56, 76, 1.0),
          message: "${AppLocalizations.of(context)!.buildingNotFound}",
          onTap: (flushbar) {
            checkPressed = false;
            flushbar.dismiss();
          },
        ).show(context);
      }
        },
      heroTag: null,
      backgroundColor:
      const Color.fromRGBO(48, 56, 76, 1.0),
      child: const Icon(Icons.notifications),
    ),
  );
}