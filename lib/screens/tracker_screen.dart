import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:waypoint/services/location_service.dart';
import 'package:waypoint/screens/login_screen.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final _locationService = LocationService();

  bool _tracking = false;
  String _status = 'idle';
  LocationPoint? _lastPoint;
  StreamSubscription? _locSub;
  StreamSubscription? _statusSub;

  final List<_LogEntry> _log = [];

  @override
  void initState() {
    super.initState();

    _locSub = _locationService.onLocation.listen((p) {
      setState(() {
        _lastPoint = p;
        _log.insert(
          0,
          _LogEntry(timestamp: DateTime.now(), lat: p.latitude, lng: p.longitude),
        );
        if (_log.length > 200) _log.removeLast();
      });
    });

    _statusSub = _locationService.statusStream.listen((s) {
      setState(() => _status = s);
      if (s == 'permission_denied' || s == 'start_failed') {
        if (_tracking) _tracking = false;
        _showSnack('Location permission required to start tracking.');
      }
    });
  }

  @override
  void dispose() {
    _locSub?.cancel();
    _statusSub?.cancel();
    _locationService.dispose();
    super.dispose();
  }

  Future<void> _onToggle(bool value) async {
    if (value) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Location services are disabled.');
        setState(() => _tracking = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnack('Permission denied. Enable location to track.');
        setState(() => _tracking = false);
        return;
      }

      await _locationService.startTracking();
      setState(() => _tracking = true);
      _showSnack('Tracking started');
    } else {
      await _locationService.stopTracking();
      setState(() => _tracking = false);
      _showSnack('Tracking stopped');
    }
  }

  Future<void> _logout() async {
    // Stop location updates if running
    await _locationService.stopTracking();
    if (!mounted) return;
    // Navigate back to Login, clearing stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _clearLog() => setState(() => _log.clear());

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fmtTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    final s = d.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final coords = _lastPoint == null
        ? '—'
        : '${_lastPoint!.latitude.toStringAsFixed(6)}, '
          '${_lastPoint!.longitude.toStringAsFixed(6)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracker'),
        actions: [
          IconButton(
            tooltip: 'Clear log',
            onPressed: _log.isEmpty ? null : _clearLog,
            icon: const Icon(Icons.delete_sweep),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Share live location'),
                    const Spacer(),
                    Switch(
                      value: _tracking,
                      onChanged: (v) => _onToggle(v),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Status:'),
                    const SizedBox(width: 8),
                    Text(_status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Latest:'),
                    const SizedBox(width: 8),
                    Expanded(child: Text(coords)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Location log (newest first)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text('${_log.length}'),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: _log.isEmpty
                ? const Center(child: Text('No points yet. Toggle ON to start.'))
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, i) {
                      final e = _log[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${e.lat.toStringAsFixed(6)}, ${e.lng.toStringAsFixed(6)}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        subtitle: Text(_fmtTime(e.timestamp)),
                        leading: const Icon(Icons.place_outlined),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemCount: _log.length,
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogEntry {
  final DateTime timestamp;
  final double lat;
  final double lng;

  _LogEntry({
    required this.timestamp,
    required this.lat,
    required this.lng,
  });
}
