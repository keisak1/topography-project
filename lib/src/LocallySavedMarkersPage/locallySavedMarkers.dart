import 'dart:convert';
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../FormPage/application/form_request.dart';
import '../FormPage/presentation/formpage_screen.dart';

class MarkerData {
  String markerID;
  List<String> imagePaths;
  Map<String, dynamic> formData;
  DateTime date;

  MarkerData(this.markerID, this.imagePaths, this.formData, this.date);
}

class locallySavedMarkers extends StatefulWidget {
  const locallySavedMarkers({super.key});

  @override
  State<locallySavedMarkers> createState() => _locallySavedMarkersState();
}

class _locallySavedMarkersState extends State<locallySavedMarkers> {
  List<MarkerData> markers = [];
  final selectedItems = <MarkerData>{};
  bool isSelecting = false;

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
      final dateInt = prefs.getInt('${markerID}_date');
      DateTime dt = DateTime.fromMillisecondsSinceEpoch(dateInt!);
      final markerData = MarkerData(markerID, imagePaths!, formData, dt);
      markers.add(markerData);
    }
    setState(() {});
  }

  Future<void> deleteMarker(String markerID) async {
    final prefs = await SharedPreferences.getInstance();

    // delete the form data and image file paths for the given marker ID
    await prefs.remove(markerID);
    await prefs.remove('${markerID}_images');
    await prefs.remove('${markerID}_date');
    // remove the marker ID from the list of local forms
    final forms = prefs.getStringList('localForm') ?? [];
    forms.remove(markerID);
    await prefs.setStringList('localForm', forms);

    // remove the marker data from the list of markers being displayed
    setState(() {
      markers.removeWhere((markerData) => markerData.markerID == markerID);
    });
  }

  Future<void> _deleteSelectedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final forms = prefs.getStringList('localForm') ?? [];

    selectedItems.forEach((element) async {
      await prefs.remove(element.markerID);
      await prefs.remove('${element.markerID}_images');
      forms.remove(element.markerID);
      await prefs.setStringList('localForm', forms);
    });
    setState(() {
      markers.removeWhere((item) => selectedItems.contains(item));
      selectedItems.clear();
      isSelecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        height: 55.0,
        child: BottomAppBar(
          color: const Color.fromRGBO(58, 66, 86, 1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              IconButton(
                icon: const Icon(Icons.circle_outlined, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () {
                  if (isSelecting) {
                    //TODO: UPLOAD ALL SELECTED FUNCTION
                  } else {
                    //TODO: UPLOAD ALL FUNCTION
                  }
                },
              ),
              if (isSelecting)
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    _deleteSelectedItems();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(AppLocalizations.of(context)!.selectDelete),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color.fromRGBO(58, 66, 86, 1.0),
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0.1,
        backgroundColor: const Color.fromRGBO(58, 66, 86, 1.0),
        title: Text(AppLocalizations.of(context)!.locallySavedMarkers),
      ),
      body: Container(
        child: ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: markers.length,
          itemBuilder: (context, index) {
            final markerData = markers[index];
            final isSelected = selectedItems.contains(markerData);
            print(markerData.formData);
            // display the first image if available
            final image = markerData.imagePaths.isNotEmpty
                ? Image.file(File(markerData.imagePaths[0]))
                : Container();

            return Card(
              elevation: 8.0,
              margin:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              child: Container(
                decoration:
                    const BoxDecoration(color: Color.fromRGBO(64, 75, 96, .9)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  selectedTileColor: Colors.teal,
                  selectedColor: Colors.white,
                  leading: Container(
                    padding: const EdgeInsets.only(right: 12.0),
                    decoration: const BoxDecoration(
                        border: Border(
                            right:
                                BorderSide(width: 1.0, color: Colors.white24))),
                    child: image,
                  ),
                  title: Text("Marker ID: ${markerData.markerID}",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Row(
                    children:  <Widget>[
                      Icon(Icons.watch_later_outlined, color: Colors.yellowAccent),
                      Text(' ${markerData.date.year}/${markerData.date.month}/${markerData.date.day} ${markerData.date.hour}:${markerData.date.minute}',
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => DynamicForm(
                                      marker: int.parse(markerData.markerID) /*ID DO MARKER*/,
                                      questions: questions,
                                  values: markerData.formData)));
                        },
                        icon: const Icon(Icons.edit_document,
                            color: Colors.white, size: 30.0)),
                    IconButton(
                        onPressed: () async {
                          deleteMarker(markerData.markerID);
                        },
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 30.0,
                        )),
                  ]),
                  selected: isSelected,
                  onTap: () {
                    if (isSelecting) {
                      setState(() {
                        if (isSelected) {
                          selectedItems.remove(markerData);
                          if (selectedItems.isEmpty) {
                            isSelecting = false;
                          }
                        } else {
                          selectedItems.add(markerData);
                        }
                      });
                    }
                  },
                  onLongPress: () {
                    setState(() {
                      isSelecting = true;
                      selectedItems.add(markerData);
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
