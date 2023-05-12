import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:topography_project/src/HomePage/presentation/homepage_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


Future<void> login(String username, String password, context) async {
  final url = Uri.parse('https://reqres.in/api/login');
  final headers = {'Content-Type': 'application/json'};
  final body = json.encode({'username': username, 'password': password});
  print(body);
  final response = await http.post(url, headers: headers, body: body);
  print(response.statusCode);
  if (response.statusCode == 200) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final responseBody = response.body;
    final responseJson = json.decode(responseBody);
    final token = responseJson['token'];
    await prefs.setString('token', token);
    await prefs.setBool('loggedOut', false);
    // Save the current date to shared preferences
    DateTime currentDate = DateTime.now();
    await prefs.setInt('startTimestamp', currentDate.millisecondsSinceEpoch);
    // Check if 30 days have passed since the start date
    int? startTimestamp = prefs.getInt('startTimestamp');
    if (startTimestamp != null) {
      DateTime startDate = DateTime.fromMillisecondsSinceEpoch(startTimestamp);
      Duration difference = currentDate.difference(startDate);
      if (difference.inDays >= 30) {
        await prefs.clear();
      }
    }

    Navigator.pushReplacement(
      context!,
      MaterialPageRoute(builder: (context) => MyHomePage()),
    );
  } else {
    showDialog(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.failedTitle),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(AppLocalizations.of(context)!.failed1),
                  Text(AppLocalizations.of(context)!.failed2),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
    );
    print('POST request failed');
  }
}