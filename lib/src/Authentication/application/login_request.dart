import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:topography_project/src/HomePage/presentation/homepage_screen.dart';


Future<void> login(String username, String password, context) async {
  final url = Uri.parse('https://reqres.in/api/login');
  final headers = {'Content-Type': 'application/json'};
  final body = json.encode({'username': username, 'password': password});
  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    print('POST request successful');
    print(response.body);
    Navigator.push(
      context!,
      MaterialPageRoute(builder: (context) => MyHomePage(title: 'Logged in',)),
    );
  } else {
    print('POST request failed');
  }
}