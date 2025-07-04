import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void main() {
  print('Available face landmark types:');
  FaceLandmarkType.values.forEach((type) {
    print('${type.name}: $type');
  });
}
