// lib/services/dms_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';

class DMSResult {
  final String status;
  final double ear;
  final double mouthRatio;
  final String gazeStatus;

  DMSResult({
    required this.status,
    required this.ear,
    required this.mouthRatio,
    required this.gazeStatus,
  });

  factory DMSResult.fromJson(Map<String, dynamic> json) {
    return DMSResult(
      status: json['status'] ?? 'unknown',
      ear: (json['ear'] ?? 0.3).toDouble(),
      mouthRatio: (json['mouth_ratio'] ?? 0.0).toDouble(),
      gazeStatus: json['gaze_status'] ?? 'unknown',
    );
  }
}

class DMSService {
  static const String _baseUrl = 'http://YOUR_SERVER_IP:8000';

  Future<DMSResult> detectFromCamera(CameraImage image) async {
    try {
      final jpegBytes = _convertCameraImageToJpeg(image);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/detect'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          jpegBytes,
          filename: 'frame.jpg',
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);

      if (response.statusCode == 200) {
        return DMSResult.fromJson(jsonData);
      } else {
        throw Exception('Failed to detect face: ${jsonData['error']}');
      }
    } catch (e) {
      throw Exception('Error in detection: $e');
    }
  }

  Uint8List _convertCameraImageToJpeg(CameraImage image) {
    // The image conversion logic is simplified and currently just uses the Y plane.
    // The width, height, and UV plane data are available in the 'image' object
    // if a full YUV to RGB conversion is needed in the future.

    // For now, just return the first plane (Y channel)
    return Uint8List.fromList(image.planes[0].bytes);
  }
}
