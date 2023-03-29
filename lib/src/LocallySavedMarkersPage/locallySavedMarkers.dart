import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MarkerData {
  String markerID;
  List<String> imagePaths;
  Map<String, dynamic> formData;

  MarkerData(this.markerID, this.imagePaths, this.formData);
}


class locallySavedMarkers extends StatefulWidget {

  const locallySavedMarkers({super.key});

  @override
  State<locallySavedMarkers> createState() => _locallySavedMarkersState();
}

class _locallySavedMarkersState extends State<locallySavedMarkers> {

  List<MarkerData> markers = [];

  void initState() {
    loadMarkers();
  }
  Future<void> loadMarkers() async {
    final prefs = await SharedPreferences.getInstance();
    final markerIDs = prefs.getStringList('localForm') ?? [];

    for (final markerID in markerIDs) {
      final formDataJson = prefs.getString(markerID);
      final formData = json.decode(formDataJson!);
      final imagePaths = prefs.getStringList('${markerID}_images');

      final markerData = MarkerData(markerID, imagePaths!, formData);
      markers.add(markerData);

    }
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Marker List')),
      body: ListView.builder(
        itemCount: markers.length,
        itemBuilder: (context, index) {
          final markerData = markers[index];

          // display the first image if available
          final image = markerData.imagePaths.isNotEmpty
              ? Image.file(File(markerData.imagePaths[0]))
              : Container();

          return ListTile(
            leading: image,
            title: Text(markerData.markerID),
            subtitle: Text('Form Data: ${markerData.formData}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // TODO: implement edit button functionality
                    print('Edit button pressed for ${markerData.markerID}');
                  },
                  child: Text('Edit'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // TODO: implement delete button functionality
                    print('Delete button pressed for ${markerData.markerID}');
                  },
                  child: Text('Delete'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}