import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> registerUser() async {
  var response = await http.post(
    Uri.parse('http://localhost:8080/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "name": "Najifa",
      "email": "test@gmail.com",
      "student_id": "123",
      "phone": "017xxxx",
      "password": "1234"
    }),
  );

  print(response.body);
}