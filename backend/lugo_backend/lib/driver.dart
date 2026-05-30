import 'package:flutter/material.dart';

class DriverHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Driver Dashboard")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome Driver 🚍"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text("View Assigned Bus"),
            ),
          ],
        ),
      ),
    );
  }
}