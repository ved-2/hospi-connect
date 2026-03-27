import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../utils/app_logger.dart';

class LocationService {
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.log('Location services are disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    AppLogger.log('Initial location permission: $permission');
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.log('Location permission denied by user.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.log('Location permission permanently denied.');
      return false;
    }

    return true;
  }

  Future<LatLng?> getCurrentLocation() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      AppLogger.log('No permission for location.');
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LatLng(lastKnown.latitude, lastKnown.longitude);
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        AppLogger.log('No permission on Windows, using mock location');
        return const LatLng(18.5204, 73.8567);
      }
      return null;
    }

    try {
      AppLogger.log('Fetching current position...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      AppLogger.log('Position found: ${position.latitude}, ${position.longitude}');
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      AppLogger.log('Error getting current location: $e');
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LatLng(lastKnown.latitude, lastKnown.longitude);
      }
      return null; 
    }
  }

  Stream<LatLng> getLocationStream() async* {
    try {
      yield* Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).map((position) => LatLng(position.latitude, position.longitude));
      return;
    } catch (e) {
      AppLogger.log('Location stream error: $e');
    }

    while (true) {
      await Future.delayed(const Duration(seconds: 10));
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        yield LatLng(pos.latitude, pos.longitude);
      } catch (_) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          yield LatLng(lastKnown.latitude, lastKnown.longitude);
        }
      }
    }
  }
}
