import 'package:http/http.dart' as http;
import 'dart:convert';


Future<void> login(String username, String password) async {
  final url = Uri.parse('https://reqres.in/api/login');
  final headers = {'Content-Type': 'application/json'};
  final body = json.encode({'username': username, 'password': password});

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    print('POST request successful');

    print(response.body);
  } else {
    print('POST request failed');
  }
}