import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:topography_project/src/HomePage/presentation/homepage_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


Future<void> login(String username, String password, context) async {
  final url = Uri.parse('https://reqres.in/api/login');
  final headers = {'Content-Type': 'application/json'};
  final body = json.encode({'username': username, 'password': password});
  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    print('POST request successful');
    print(response.body);
    Navigator.pushReplacement(
      context!,
      MaterialPageRoute(builder: (context) => MyHomePage(title: 'Logged in',)),
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