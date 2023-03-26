import 'dart:convert';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topography_project/src/FormPage/presentation/widgets/save_form_popup.dart';
import 'package:image_picker/image_picker.dart';
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
class DynamicForm extends StatefulWidget {
  final List<Question> questions;

  const DynamicForm({super.key, required this.questions});

  @override
  _DynamicFormState createState() => _DynamicFormState();
}

class _DynamicFormState extends State<DynamicForm> {
  XFile? _imageFile;
  XFile? _imageFile1;
  XFile? _imageFile2;

  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  Map<int, dynamic> _formValues = {};

  @override
  void initState() {
    super.initState();
    for (var question in widget.questions) {
      if (question.type == 'number') {
        _formValues[question.qid] = question.range[0];
      } else if (question.type == 'dropdown') {
        _formValues[question.qid] = question.items[0]['value'];
      }
    }
  }


  Future<void> _saveFormLocally(String name, Map<int, dynamic> formData) async {
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
    print(_formValues);
    // Trigger a rebuild of the form with the updated values
    setState(() {});
  }

  Widget _buildQuestion(Question question) {
    switch (question.type) {
      case "dropdown":
        List<DropdownMenuItem<String>> dropdownItems = question.items
            .map<DropdownMenuItem<String>>(
              (item) => DropdownMenuItem<String>(
                key: UniqueKey(),
                value: item['value'],
                child: Text(getLocalizedValue(item['value'], context)),
              ),
            )
            .toList();
        return DropdownButtonFormField(
          items: dropdownItems,
          value: _formValues[question.qid],
          onChanged: (value) {
            setState(() {
              _formValues[question.qid] = value;
            });
          },
          decoration: InputDecoration(
            labelText: getLocalizedLabel(question.label, context),
            border: const OutlineInputBorder(),
          ),
        );
      case "largetext":
        final controller =
            TextEditingController(text: _formValues[question.qid].toString());
        return TextFormField(
          controller: controller,
          maxLines: null,
          onChanged: (value) {
            setState(() {
              _formValues[question.qid] = value;
            });
          },
          decoration: InputDecoration(
            labelText: getLocalizedLabel(question.label, context),
            border: const OutlineInputBorder(),
          ),
        );
      case "smalltext":
        final controller =
            TextEditingController(text: _formValues[question.qid].toString());
        return TextFormField(
          controller: controller,
          onChanged: (value) {
            setState(() {
              _formValues[question.qid] = value;
            });
          },
          decoration: InputDecoration(
            labelText: getLocalizedLabel(question.label, context),
            border: const OutlineInputBorder(),
          ),
        );
      case "number":
        final controller =
            TextEditingController(text: _formValues[question.qid].toString());

        return TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              _formValues[question.qid] = int.parse(value);
            });
          },
          decoration: InputDecoration(
            labelText: getLocalizedLabel(question.label, context),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value!.isEmpty) {
              return AppLocalizations.of(context)!.fieldRequired;
            }
            final intVal = int.tryParse(value);
            if (intVal == null ||
                intVal < question.range[0] ||
                intVal > question.range[1]) {
              return AppLocalizations.of(context)!.valueBetween +
                  '${question.range[0]}' +
                  AppLocalizations.of(context)!.and +
                  '${question.range[1]}';
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.form),
        actions: [
          IconButton(
            icon: _isFavorite
                ? const Icon(Icons.star, color: Colors.yellow)
                : const Icon(Icons.star_border),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
                if (_isFavorite) {
                  showDialog(
                    context: context,
                    builder: (context) => SaveFormPopup(
                      onConfirm: (String value) {
                        _saveFormLocally(value, _formValues);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
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
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              child: Text(AppLocalizations.of(context)!.savedForms),
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
                        return ListTile(
                          title: Text(form['name']),
                          onTap: () async {
                            final formData =
                                await _loadFormLocally(form['name']);
                            setState(() {
                              _formValues = formData!;
                              _updateFormValues(_formValues);
                            });
                            Navigator.of(context).pop();
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _deleteSavedForm(form['name']);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Form "${form['name']}" deleted'),
                                ),
                              );
                            },
                          ),
                        );
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
                image(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  if(_imageFile != null) Image(image: FileImage(File(_imageFile!.path)), height: 90,width: 50,),
                  if(_imageFile1 != null) Image(image: FileImage(File(_imageFile1!.path)), height: 90,width: 50,),
                  if(_imageFile2 != null) Image(image: FileImage(File(_imageFile2!.path)), height: 90,width: 50,),
                ],),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if(await checkInternetConnectivity()) {
                              /**
                               * SEND TO THE API IF IT HAS INTERNET
                               *
                               */
                              print(_formValues);
                            }else{
                              /**
                               *  SAVE LOCALLY IF IT DOESN'T HAVE INTERNET
                               *
                               */
                            }
                          }
                        },
                        child: Text(AppLocalizations.of(context)!.submit),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget image(){
    return Column(
      children:  <Widget>[
        const Text("Image 1"),
      GestureDetector(
        onTap: () {
          takePhoto(ImageSource.camera);
        },
        child: const Icon(Icons.camera_alt, color: Colors.teal, size: 28.0,),
        ),
        const Text("Image 2"),

        GestureDetector(
          onTap: () {
            takePhoto1(ImageSource.camera);
          },
          child: const Icon(Icons.camera_alt, color: Colors.teal, size: 28.0,),
        ),
        const Text("Image 3"),
        GestureDetector(
          onTap: () {
            takePhoto2(ImageSource.camera);
          },
          child: const Icon(Icons.camera_alt, color: Colors.teal, size: 28.0,),
        ),
      ]
    );
  }

  void takePhoto(ImageSource source) async{
    final pickedFile = await _picker.pickImage(source: source);
    setState(() {
      _imageFile = pickedFile!;
    });
  }

  void takePhoto1(ImageSource source) async{
    final pickedFile = await _picker.pickImage(source: source);
    setState(() {
      _imageFile1 = pickedFile!;
    });
  }

  void takePhoto2(ImageSource source) async{
    final pickedFile = await _picker.pickImage(source: source);
    setState(() {
      _imageFile2 = pickedFile!;
    });
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

