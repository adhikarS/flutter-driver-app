// lib/services/location_service.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationPoint {
  final double latitude;
  final double longitude;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  LocationService._();
  static final LocationService _instance = LocationService._();
  factory LocationService() => _instance;

  // Broadcast streams live for the whole app lifetime; do NOT close them.
  final _locationStream = StreamController<LocationPoint>.broadcast();
  Stream<LocationPoint> get onLocation => _locationStream.stream;

  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  Timer? _timer;
  bool _running = false;

  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _statusSafeAdd('location_service_disabled');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _statusSafeAdd('permission_denied');
      return false;
    }

    return true;
  }

  /// Starts polling current position every 5s and emits to [onLocation].
  Future<void> startTracking() async {
    if (_running) return; // already running
    final ok = await _ensurePermission();
    if (!ok) {
      _statusSafeAdd('start_failed');
      return;
    }

    _running = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _locationSafeAdd(
          LocationPoint(latitude: pos.latitude, longitude: pos.longitude),
        );
      } catch (_) {
        // ignore transient errors
      }
    });

    _statusSafeAdd('started');
  }

  Future<void> stopTracking() async {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _statusSafeAdd('stopped');
  }

  /// For a shared singleton, don't close controllers; just stop the timer.
  void dispose() {
    stopTracking();
    // Intentionally not closing _locationStream or _statusController
  }

  // ---- Safe add helpers (avoid adding to closed controllers) ----
  void _locationSafeAdd(LocationPoint p) {
    if (!_locationStream.isClosed) {
      _locationStream.add(p);
    }
  }

  void _statusSafeAdd(String s) {
    if (!_statusController.isClosed) {
      _statusController.add(s);
    }
  }
}
