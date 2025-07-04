import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Configuration Parameters
const double yawnThreshold = 0.37;
const double yawnMinDuration = 1.0;
const double eyeArThresh = 0.25;
const int eyeArConsecFrames = 20;
const double lookLeftThreshold = -25.0;
const double lookRightThreshold = 25.0;
const int alertFramesRequired = 20;
const int smoothingWindow = 10;
const double neutralZone = 20.0;
const int alertDuration = 3;

class DriverMonitoringScreen extends StatefulWidget {
  const DriverMonitoringScreen({super.key});

  @override
  DriverMonitoringScreenState createState() => DriverMonitoringScreenState();
}

class DriverMonitoringScreenState extends State<DriverMonitoringScreen> {
  Timer? _timer;
  String _driverStatus = 'Loading...';
  String _gazeStatus = 'Loading...';
  double _ear = 0.0;
  double _mouthRatio = 0.0;
  String _alert = 'None';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      try {
        final response =
            await http.get(Uri.parse('http://localhost:8000/status'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _driverStatus = data['driver_status'] ?? 'Unknown';
            _gazeStatus = data['gaze_status'] ?? 'Unknown';
            _ear = (data['ear'] ?? 0.0).toDouble();
            _mouthRatio = (data['mouth_ratio'] ?? 0.0).toDouble();
            _alert = data['alert'] ?? 'None';
            _loading = false;
          });
        }
      } catch (e) {
        setState(() {
          _driverStatus = 'Error connecting to backend';
          _gazeStatus = '-';
          _ear = 0.0;
          _mouthRatio = 0.0;
          _alert = 'None';
          _loading = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        Container(
          color: Colors.black,
        ),
        Positioned(
          top: 10,
          left: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Driver Status: 4{_driverStatus}',
                  style: const TextStyle(color: Colors.yellow, fontSize: 20)),
              Text('Gaze Direction: $_gazeStatus',
                  style: const TextStyle(color: Colors.yellow, fontSize: 20)),
              Text('EAR: ${_ear.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 20)),
              Text('Mouth Ratio: ${_mouthRatio.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green, fontSize: 20)),
            ],
          ),
        ),
        if (_alert != 'None')
          Container(
            color: const Color.fromRGBO(255, 0, 0, 0.4),
            child: Center(
              child: Text(
                _alert == 'yawn'
                    ? 'DROWSINESS ALERT! Yawning detected'
                    : _alert == 'sleep'
                        ? 'DROWSINESS ALERT! Driver is sleeping'
                        : 'ALERT! $_gazeStatus',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
