import 'package:flutter/material.dart';

class StudentHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Student Dashboard")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("See Bus ETA 🚌"),
          SizedBox(height: 20),
          ElevatedButton(onPressed: () {}, child: Text("View Buses")),
        ],
      ),
    );
  }
}
