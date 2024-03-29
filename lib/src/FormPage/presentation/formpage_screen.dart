import 'dart:convert';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:full_screen_image/full_screen_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topography_project/Models/Markers.dart';
import 'package:topography_project/src/FormPage/presentation/widgets/save_form_popup.dart';
import 'package:image_picker/image_picker.dart';
import 'package:topography_project/src/HomePage/application/homepage_utilities.dart';
import 'widgets/dynamic_translation.dart';

class Question {
  final int qid;
  final String label;
  final String type;
  final dynamic items;
  final List<int> range;

  Question({
    required this.qid,
    required this.label,
    required this.type,
    this.items,
    this.range = const [],
  });
}

class DynamicForm<T extends State<StatefulWidget>> extends StatefulWidget {
  final Function()? onResultUpdated;
  final List<String>? image;
  final List<Question> questions;
  final int marker;
  final Map<String, dynamic> values;

  const DynamicForm(
      {super.key,
      required this.questions,
      required this.marker,
      this.values = const {},
      this.onResultUpdated,
      this.image});

  @override
  _DynamicFormState createState() => _DynamicFormState();
}

class _DynamicFormState extends State<DynamicForm> {
  String? currentUpdate;
  List<XFile> _imageFiles = [];
  List<Widget> _imageWidgets = [];

  final _formKey = GlobalKey<FormState>();
  Map<int, dynamic> _formValues = {};

  @override
  void initState() {
    super.initState();
    if (widget.image != null) {
      for (String imagePath in widget.image!) {
        XFile imageFile = XFile(imagePath);
        _imageFiles.add(imageFile);
      }
    }
    for (var question in widget.questions) {
      if (question.type == 'number') {
        _formValues[question.qid] = question.range[0];
      } else if (question.type == 'dropdown') {
        _formValues[question.qid] = question.items[0]['value'];
      }
    }
  }

  Future<void> _saveFormLocally(String markerID, Map<int, dynamic> formData,
      List<XFile> imageFiles) async {
    // convert form data to Map<String, dynamic>
    final Map<String, dynamic> data = {};
    formData.forEach((key, value) {
      data[key.toString()] = value;
    });

    // save the form data, image file paths, and the given name to the shared preferences
    final prefs = await SharedPreferences.getInstance();
    final forms = prefs.getStringList('localForm') ?? [];
    print(forms);
    if (forms.contains(markerID)) {
      await prefs.setStringList('localForm', forms);
      await prefs.remove(markerID);
      await prefs.setString(markerID, json.encode(data));

      // save image file paths
      final imagePaths = imageFiles.map((file) => file.path).toList();
      await prefs.setStringList('${markerID}_images', imagePaths);

      await prefs.setInt(
          '${markerID}_date', DateTime.now().millisecondsSinceEpoch);
      if (widget.onResultUpdated != null) {
        widget.onResultUpdated!.call();
      }
    } else {
      forms.add(markerID);
      await prefs.setStringList('localForm', forms);
      await prefs.setString(markerID, json.encode(data));

      // save image file paths
      final imagePaths = imageFiles.map((file) => file.path).toList();
      await prefs.setStringList('${markerID}_images', imagePaths);
      // save date
      await prefs.setInt(
          '${markerID}_date', DateTime.now().millisecondsSinceEpoch);
      if (widget.onResultUpdated != null) {
        widget.onResultUpdated!.call();
      }
    }
  }

  Future<void> _addToFavorites(String name, Map<int, dynamic> formData) async {
    // convert form data to Map<String, dynamic>
    final Map<String, dynamic> data = {};
    formData.forEach((key, value) {
      data[key.toString()] = value;
    });

    // save the form data and the given name to the shared preferences
    final prefs = await SharedPreferences.getInstance();
    final forms = prefs.getStringList('forms') ?? [];
    forms.add(name);
    await prefs.setStringList('forms', forms);
    await prefs.setString(name, json.encode(data));
  }

  Future<Map<int, dynamic>?> _loadFormLocally(String formName) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(formName) == null) {
      return null;
    }
    final formDataJson = prefs.getString(formName);
    final formData = jsonDecode(formDataJson!) as Map<String, dynamic>;
    final formDataIntKeys =
        formData.map((key, value) => MapEntry(int.parse(key), value));

    return formDataIntKeys;
  }

  Future<List<Map<String, dynamic>>> _getSavedForms() async {
    final prefs = await SharedPreferences.getInstance();
    final formNames = prefs.getStringList('forms') ?? [];
    final forms = <Map<String, dynamic>>[];
    for (final formName in formNames) {
      final formData = await _loadFormLocally(formName);
      forms.add({'name': formName, 'data': formData});
    }
    return forms;
  }

  Future<void> _deleteSavedForm(String formName) async {
    final prefs = await SharedPreferences.getInstance();
    final savedForms = prefs.getStringList('forms') ?? [];
    savedForms.remove(formName);
    await prefs.setStringList('forms', savedForms);
    await prefs.remove(formName);
    setState(() {});
  }

  void _updateFormValues(Map<int, dynamic> savedFormData) {
    for (var question in widget.questions) {
      // Update the value for the current question
      _formValues[question.qid] = savedFormData[question.qid];
    }
    // Trigger a rebuild of the form with the updated values
    setState(() {});
    currentUpdate = "fav";

    print(_formValues);
  }

  Widget _buildQuestion(Question question) {
    var currentValue;
    if (currentUpdate == "fav") {
      currentValue = _formValues[question.qid];
    } else {
      if (widget.values[question.qid.toString()] != null) {
        currentValue = widget.values[question.qid.toString()];
      } else {
        currentValue = _formValues[question.qid];
      }
    }
    switch (question.type) {
      case "dropdown":
        List<DropdownMenuItem<String>> dropdownItems = question.items
            .map<DropdownMenuItem<String>>(
              (item) => DropdownMenuItem<String>(
                key: UniqueKey(),
                value: item['value'],
                child: Text(
                  getLocalizedValue(item['value'], context),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
            .toList();

        return DropdownButtonFormField(
          iconEnabledColor: Colors.white,
          dropdownColor: const Color.fromRGBO(58, 66, 86, 1.0),
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          items: dropdownItems,
          value: currentValue,
          onChanged: (value) {
            print(value);
            _formValues[question.qid] = value;
          },
          validator: (value) {
            if (value.toString() == currentValue) {
              _formValues[question.qid] = currentValue;
            }
            return null;
          },
          decoration: InputDecoration(
            label: Text(getLocalizedLabel(question.label, context),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            border: const OutlineInputBorder(),
          ),
        );

      case "largetext":
        return TextFormField(
          key: Key(currentValue ?? ''),
          initialValue: currentValue ?? '',
          onChanged: (value) {
            print(value);
            _formValues[question.qid] = value;
          },
          validator: (value) {
            if (value.toString() == currentValue) {
              _formValues[question.qid] = currentValue;
            }
            return null;
          },
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          maxLines: null,
          decoration: InputDecoration(
            label: Text(getLocalizedLabel(question.label, context),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            border: const OutlineInputBorder(),
          ),
        );
      case "smalltext":
        return TextFormField(
          key: Key(currentValue ?? ''),
          initialValue: currentValue ?? '',
          onChanged: (value) {
            print(value);

            _formValues[question.qid] = value;
          },
          validator: (value) {
            if (value.toString() == currentValue) {
              _formValues[question.qid] = currentValue;
            }
            return null;
          },
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: getLocalizedLabel(question.label, context),
            border: const OutlineInputBorder(),
          ),
        );
      case "number":
        return TextFormField(
          key: Key(currentValue.toString() ?? ''),
          initialValue: currentValue.toString() ?? '',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            print(value);
            _formValues[question.qid] = value;
          },
          decoration: InputDecoration(
            label: Text(getLocalizedLabel(question.label, context),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value.toString() == currentValue) {
              _formValues[question.qid] = currentValue;
            }
            if (value!.isEmpty) {
              return AppLocalizations.of(context)!.fieldRequired;
            }
            final intVal = int.tryParse(value);
            if (intVal == null ||
                intVal < question.range[0] ||
                intVal > question.range[1]) {
              return AppLocalizations.of(context)!.valueBetween +
                  ' ${question.range[0]}' +
                  AppLocalizations.of(context)!.and +
                  ' ${question.range[1]}';
            }
            return null;
          },
        );
      default:
        return Container();
    }
  }

  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(58, 66, 86, 1.0),
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
                    currentUpdate = null;
                    Navigator.pop(context);
                  }),
              IconButton(
                icon: const Icon(Icons.circle_outlined, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: _isFavorite
                    ? const Icon(Icons.star, color: Colors.yellow)
                    : const Icon(
                        Icons.star_border,
                        color: Colors.white,
                      ),
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                    if (_isFavorite) {
                      showDialog(
                        context: context,
                        builder: (context) => SaveFormPopup(
                          onConfirm: (String value) {
                            _addToFavorites(value, _formValues);
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor:
                                    const Color.fromRGBO(58, 66, 86, 1.0),
                                content: Text(
                                    AppLocalizations.of(context)!.savedLocally +
                                        value),
                              ),
                            );
                          },
                        ),
                      );
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0.1,
        backgroundColor: const Color.fromRGBO(58, 66, 86, 1.0),
        title: Text(AppLocalizations.of(context)!.form),
      ),
      drawer: Drawer(
        backgroundColor: const Color.fromRGBO(58, 66, 86, 1.0),
        child: Column(
          children: [
            DrawerHeader(
              child: Text(
                AppLocalizations.of(context)!.savedForms,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _getSavedForms(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final forms = snapshot.data!;
                    return ListView.builder(
                      itemCount: forms.length,
                      itemBuilder: (context, index) {
                        final form = forms[index];
                        return Card(
                            elevation: 8.0,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10.0, vertical: 6.0),
                            child: Container(
                              decoration: const BoxDecoration(
                                  color: Color.fromRGBO(64, 75, 96, .9)),
                              child: ListTile(
                                title: Text(
                                  form['name'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                onTap: () async {
                                  final formData =
                                      await _loadFormLocally(form['name']);
                                  setState(() {
                                    _formValues = formData!;
                                    _updateFormValues(_formValues);
                                  });
                                  Navigator.pop(context,
                                      true); // pass true as the boolean value
                                },
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _deleteSavedForm(form['name']);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Form "${form['name']}" deleted'),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ));
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Text(AppLocalizations.of(context)!.fetchError);
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                ...widget.questions.map(
                  (question) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: _buildQuestion(question),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        width: MediaQuery.of(context).size.width,
                        child: ElevatedButton(
                          onPressed: () async {
                            _showBottomSheet();
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.blueAccent),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.images,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ))
                  ],
                ),
                showImage(),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      width: MediaQuery.of(context).size.width,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.blueAccent),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (await checkInternetConnectivity()) {
                              // TODO: DELETE THE MARKERS ONCE THE STATUS IS GREEN
                              // TODO: DELETE THE MARKERS ONCE THE STATUS IS GREEN
                              // TODO: DELETE THE MARKERS ONCE THE STATUS IS GREEN
                              // TODO: DELETE THE MARKERS ONCE THE STATUS IS GREEN
                              // TODO: DELETE THE MARKERS ONCE THE STATUS IS GREEN
                              // TODO: DELETE THE MARKERS ONCE THE STATUS IS GREEN
                              print(_formValues);
                              _saveFormLocally(widget.marker.toString(),
                                  _formValues, _imageFiles);
                              if (widget.onResultUpdated != null) {
                                widget.onResultUpdated!.call();
                              }
                              currentUpdate = null;

                              Navigator.of(context).pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!.noInternet,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            } else {
                              _saveFormLocally(widget.marker.toString(),
                                  _formValues, _imageFiles);
                              if (widget.onResultUpdated != null) {
                                widget.onResultUpdated!.call();
                              }
                              currentUpdate = null;
                              Navigator.of(context).pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!.noInternet,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                              /**
                               *  SAVE LOCALLY IF IT DOESN'T HAVE INTERNET
                               *
                               */
                            }
                          }
                        },
                        child: Text(
                          AppLocalizations.of(context)!.submit,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget showImage() {
    if (_imageFiles.isEmpty) {
      return Text(AppLocalizations.of(context)!.selectOne,
          style: const TextStyle(color: Colors.white));
    } else {
      return CarouselSlider(
        options: CarouselOptions(enableInfiniteScroll: false, height: 400.0),
        items: _imageFiles.map((i) {
          return Builder(
            builder: (BuildContext context) {
              return Stack(
                children: [
                  FullScreenWidget(
                    disposeLevel: DisposeLevel.High,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Image.file(File(i.path)),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.red.withAlpha(255),
                      ),
                      onPressed: () {
                        _imageFiles.remove(i);
                        setState(() {});
                      },
                      child: Icon(Icons.delete_outline),
                    ),
                  ),
                ],
              );
            },
          );
        }).toList(),
      );
    }
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 90.0,
          color: const Color.fromRGBO(58, 66, 86, 1.0).withOpacity(0.8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: pickImageGallery,
                icon: const Icon(
                  Icons.photo_library,
                  color: Colors.white,
                  size: 60,
                ),
                tooltip: AppLocalizations.of(context)!.gallery,
              ),
              IconButton(
                onPressed: pickImageCam,
                icon: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 60,
                ),
                tooltip: AppLocalizations.of(context)!.camera,
              ),
            ],
          ),
        );
      },
    );
  }

  pickImageGallery() async {
    List<XFile> images = [];
    final picker = ImagePicker();
    if (_imageFiles.length > 3) {
      return;
    }
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFiles.add(pickedFile);
        _imageWidgets =
            _imageFiles.map((image) => Image.file(File(image.path))).toList();
      });
    }
  }

  pickImageCam() async {
    List<XFile> images = [];
    final picker = ImagePicker();
    if (_imageFiles.length > 3) {
      return;
    }
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFiles.add(pickedFile);
        _imageWidgets =
            _imageFiles.map((image) => Image.file(File(image.path))).toList();
      });
    }
  }

  Future<bool> checkInternetConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    } else {
      return true;
    }
  }
}
