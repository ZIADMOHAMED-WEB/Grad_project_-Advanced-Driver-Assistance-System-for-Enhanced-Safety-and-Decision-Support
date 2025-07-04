import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final Logger _logger = Logger('SleepDetectionScreen');

class SleepDetectionScreen extends StatefulWidget {
  final CameraDescription camera;

  const SleepDetectionScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _SleepDetectionScreenState createState() => _SleepDetectionScreenState();
}

class _SleepDetectionScreenState extends State<SleepDetectionScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  WebSocketChannel? _channel;
  Timer? _frameTimer;
  bool _isConnected = false;

  // State variables
  bool _isStreaming = false;
  String _driverStatus = 'Disconnected';
  double _ear = 0.0;
  double _mouthRatio = 0.0;
  String _gazeStatus = '...';
  bool _isDrowsy = false;
  bool _isYawning = false;
  double _headPose = 0.0;

  // Connection and model parameters
  final String _host = '127.0.0.1'; // Use your server's IP
  final int _port = 65486;
  static const double _eyeArThresh = 0.25;
  static const double _yawnThreshold = 0.37;
  static const double _lookLeftThreshold = -25;
  static const double _lookRightThreshold = 25;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.low,
      imageFormatGroup: ImageFormatGroup.yuv420,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      _connectToService();
    });
  }

  @override
  void dispose() {
    _disconnectFromService();
    _frameTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _connectToService() async {
    try {
      _logger.info('Connecting to WebSocket server at ws://$_host:$_port');
      
      setState(() {
        _isConnected = false;
        _driverStatus = 'Connecting...';
      });
      
      // Create a new WebSocket connection
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://$_host:$_port'),
      );

      setState(() {
        _isConnected = true;
        _driverStatus = 'Connected';
      });

      // Listen for messages from the server
      _channel!.stream.listen(
        (message) {
          if (!mounted) return;
          try {
            final Map<String, dynamic> result = json.decode(message);
            _logger.fine('Received data: $result');
            
            setState(() {
              _ear = result['ear']?.toDouble() ?? 0.0;
              _mouthRatio = result['mouth_ratio']?.toDouble() ?? 0.0;
              _headPose = result['yaw']?.toDouble() ?? 0.0;

              _gazeStatus = _headPose < _lookLeftThreshold
                  ? 'Looking Left'
                  : _headPose > _lookRightThreshold
                      ? 'Looking Right'
                      : 'Looking Forward';

              _isDrowsy = _ear < _eyeArThresh;
              _isYawning = _mouthRatio > _yawnThreshold;

              _driverStatus = _isDrowsy || _isYawning ? 'Drowsy' : 'Awake';
            });
          } catch (e) {
            _logger.severe('Error processing server data: $e');
          }
        },
        onError: (error) {
          _logger.severe('WebSocket error: $error');
          _disconnectFromService();
          _reconnect();
        },
        onDone: () {
          _logger.info('WebSocket connection closed');
          _disconnectFromService();
          _reconnect();
        },
      );
    } catch (e) {
      _logger.severe('Failed to connect to WebSocket server: $e');
      _reconnect();
    }
  }

  void _disconnectFromService() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    setState(() {
      _isConnected = false;
      _isStreaming = false;
      _driverStatus = 'Disconnected';
    });
  }

  void _reconnect() {
    if (mounted) {
      setState(() {
        _driverStatus = 'Reconnecting...';
      });
      // Try to reconnect after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _connectToService();
        }
      });
    }
  }

  Future<void> _sendFrame() async {
    if (!_controller.value.isInitialized || !_isStreaming || _channel == null) {
      return;
    }

    try {
      final XFile imageFile = await _controller.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      if (_channel != null) {
        _channel!.sink.add(imageBytes);
      }
    } catch (e) {
      _logger.severe('Error capturing/sending frame: $e');
      if (mounted) {
        _toggleStreaming();
      }
    }
  }

  void _toggleStreaming() {
    if (!mounted) return;
    
    if (!_isConnected) {
      _connectToService();
      return;
    }
    
    setState(() {
      _isStreaming = !_isStreaming;
      if (_isStreaming) {
        _frameTimer = Timer.periodic(
          const Duration(milliseconds: 200), // 5 FPS
          (_) => _sendFrame(),
        );
        _driverStatus = 'Streaming';
      } else {
        _frameTimer?.cancel();
        _frameTimer = null;
        _driverStatus = 'Paused';
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drowsiness Detection')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                CameraPreview(_controller),
                _buildInfoOverlay(),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleStreaming,
        child: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
      ),
    );
  }

  Widget _buildInfoOverlay() {
    return Container(
      height: 200,
      width: double.infinity,
      color: const Color.fromRGBO(0, 0, 0, 0.5), // Fix for deprecated withOpacity
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Status: $_driverStatus', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('EAR: ${_ear.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
            Text('MAR: ${_mouthRatio.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
            Text('Gaze: $_gazeStatus', style: const TextStyle(color: Colors.white)),
            Text('Head Pose (Yaw): ${_headPose.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
