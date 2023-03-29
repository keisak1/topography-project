import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ClosestMarkerWidget extends StatefulWidget {
  final LatLng userLocation;
  final List<Marker> markers;

  const ClosestMarkerWidget(
      {super.key, required this.userLocation, required this.markers});

  @override
  State<ClosestMarkerWidget> createState() => _ClosestMarkerWidget();
}

class _ClosestMarkerWidget extends State<ClosestMarkerWidget> {
  late LatLng _userLocation;

  @override
  void initState() {
    super.initState();
    _userLocation = widget.userLocation;
  }

  @override
  void didUpdateWidget(ClosestMarkerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userLocation != oldWidget.userLocation) {
      setState(() {
        _userLocation = widget.userLocation;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildClosestMarkerWidget(_userLocation, widget.markers, context);
  }
}

double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

Widget buildClosestMarkerWidget(
    LatLng userLocation, List<Marker> markers, BuildContext context) {
  // Find the closest marker to the user
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
      bottom: 5,
      child: Card(
          elevation: 8.0,
          child: Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(64, 75, 96, .9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Transform.rotate(
                  angle: angle * pi / 180,
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.lightGreenAccent,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppLocalizations.of(context)!.close} ${minDistance.toStringAsFixed(2)} km',
                  style: const TextStyle(color: Colors.white70, fontSize: 20),
                ),
              ],
            ),
          )));
}
