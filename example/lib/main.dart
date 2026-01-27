import 'package:flutter/material.dart';
import 'package:foursquare_movement_sdk/foursquare_movement_sdk.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  String? _installId;
  String? _currentVenue;
  bool? _isEnabled;
  String? _error;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }
    if (status.isGranted) {
      setState(() => _permissionGranted = true);
    } else {
      _showError('Location permission is required to use the Movement SDK');
    }
  }

  void _showError(String message) {
    setState(() => _error = message);
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _start() async {
    if (!_permissionGranted) {
      await _requestPermissions();
      if (!_permissionGranted) return;
    }
    try {
      await MovementSdk.start();
      final enabled = await MovementSdk.isEnabled();
      setState(() {
        _isEnabled = enabled;
        _error = null;
      });
    } catch (e) {
      _showError('Failed to start SDK: $e');
    }
  }

  Future<void> _stop() async {
    try {
      await MovementSdk.stop();
      final enabled = await MovementSdk.isEnabled();
      setState(() {
        _isEnabled = enabled;
        _error = null;
      });
    } catch (e) {
      _showError('Failed to stop SDK: $e');
    }
  }

  Future<void> _getInstallId() async {
    try {
      final id = await MovementSdk.getInstallId();
      setState(() {
        _installId = id;
        _error = null;
      });
    } catch (e) {
      _showError('Failed to get install ID: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!_permissionGranted) {
      await _requestPermissions();
      if (!_permissionGranted) return;
    }
    try {
      final current = await MovementSdk.getCurrentLocation();
      setState(() {
        _currentVenue = current.currentPlace.venue?.name ?? 'Unknown';
        _error = null;
      });
    } catch (e) {
      _showError('Failed to get current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: Scaffold(
        appBar: AppBar(title: const Text('Foursquare Movement SDK Example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton(onPressed: _start, child: const Text('Start')),
                  ElevatedButton(onPressed: _stop, child: const Text('Stop')),
                  ElevatedButton(
                    onPressed: _getInstallId,
                    child: const Text('Get Install ID'),
                  ),
                  ElevatedButton(
                    onPressed: _getCurrentLocation,
                    child: const Text('Get Current Location'),
                  ),
                  ElevatedButton(
                    onPressed: MovementSdk.showDebugScreen,
                    child: const Text('Debug Screen'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Enabled: ${_isEnabled ?? 'Unknown'}'),
              Text('Install ID: ${_installId ?? 'Unknown'}'),
              Text('Venue: ${_currentVenue ?? 'Unknown'}'),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
