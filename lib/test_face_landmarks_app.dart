import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void main() {
  runApp(const FaceLandmarksApp());
}

class FaceLandmarksApp extends StatelessWidget {
  const FaceLandmarksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Face Landmark Types')),
        body: ListView.builder(
          itemCount: FaceLandmarkType.values.length,
          itemBuilder: (context, index) {
            final type = FaceLandmarkType.values[index];
            return ListTile(
              title: Text(type.toString().split('.').last),
              subtitle: Text('Value: $type'),
            );
          },
        ),
      ),
    );
  }
}
