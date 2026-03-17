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
      
      // Override for bad demo locations (e.g., Chrome defaulting to Europe or US)
      if (position.longitude < 60 || position.longitude > 100 || position.latitude < 5 || position.latitude > 40) {
        AppLogger.log('Location way out of bounds (probably wrong Chrome/Emulator test GPS), mocking to Pune');
        return const LatLng(18.5300, 73.8500); // Simulate ambulance in Pune
      }

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      AppLogger.log('Error getting current location: $e');
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        if (lastKnown.longitude < 60 || lastKnown.longitude > 100) {
           return const LatLng(18.5300, 73.8500);
        }
        return LatLng(lastKnown.latitude, lastKnown.longitude);
      }
      return const LatLng(18.5300, 73.8500); // Fallback to Pune unconditionally
    }
  }

  Stream<LatLng> getLocationStream() async* {
    try {
      yield* Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).map((position) {
         if (position.longitude < 60 || position.longitude > 100 || position.latitude < 5 || position.latitude > 40) {
           return const LatLng(18.5300, 73.8500);
         }
         return LatLng(position.latitude, position.longitude);
      });
      return;
    } catch (e) {
      AppLogger.log('Location stream error: $e');
    }

    // Fallback: poll current position periodically, then mock if unavailable.
    while (true) {
      await Future.delayed(const Duration(seconds: 10));
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (pos.longitude < 60 || pos.longitude > 100 || pos.latitude < 5 || pos.latitude > 40) {
           yield const LatLng(18.5300, 73.8500);
        } else {
           yield LatLng(pos.latitude, pos.longitude);
        }
        continue;
      } catch (_) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          if (lastKnown.longitude < 60 || lastKnown.longitude > 100) {
             yield const LatLng(18.5300, 73.8500);
          } else {
             yield LatLng(lastKnown.latitude, lastKnown.longitude);
          }
          continue;
        }
      }
      yield const LatLng(18.5300, 73.8500);
    }
  }
}
