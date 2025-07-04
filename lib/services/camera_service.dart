import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class CameraService {
  CameraController? _cameraController;
  WebSocketChannel? _channel;
  Timer? _frameTimer;
  final Function(Map<String, dynamic>) onDetectionResult;
  final String serverUrl;

  CameraService({
    required this.onDetectionResult,
    this.serverUrl = 'ws://10.0.2.2:8000/ws', // Use your server IP
  });

  Future<void> initialize() async {
    // Initialize camera
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController?.initialize();

    // Initialize WebSocket connection
    _channel = IOWebSocketChannel.connect(Uri.parse(serverUrl));
    _channel?.stream.listen(
      (data) {
        final result = json.decode(data);
        onDetectionResult(Map<String, dynamic>.from(result));
      },
      onError: (error) => print('WebSocket error: $error'),
      onDone: () => print('WebSocket connection closed'),
    );
  }

  void startFrameCapture() {
    // Stop any existing timer
    _frameTimer?.cancel();

    // Start new timer to capture frames every 30 seconds
    _frameTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_cameraController?.value.isInitialized ?? false) {
        try {
          // Capture image
          final image = await _cameraController!.takePicture();
          final imageFile = File(image.path);
          final imageBytes = await imageFile.readAsBytes();

          // Send frame to server
          _channel?.sink.add(imageBytes);

          // Delete the temporary image file
          await imageFile.delete();
        } catch (e) {
          print('Error capturing/sending frame: $e');
        }
      }
    });
  }

  // Public getter for the camera controller
  CameraController? get cameraController => _cameraController;

  Future<void> dispose() async {
    _frameTimer?.cancel();
    await _cameraController?.dispose();
    await _channel?.sink.close();
  }
}
