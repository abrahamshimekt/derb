import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

class NavigationService {
  // Using a free alternative routing service
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1';
  
  StreamSubscription<Position>? _positionStream;
  final StreamController<NavigationState> _navigationController = StreamController<NavigationState>.broadcast();
  
  Stream<NavigationState> get navigationStream => _navigationController.stream;
  
  // Current navigation state
  NavigationState? _currentState;
  NavigationState? get currentState => _currentState;
  
  // Route data
  List<LatLng>? _routePoints;
  double? _totalDistance;
  Duration? _estimatedDuration;
  
  Future<bool> requestLocationPermission() async {
    try {
      // Request location permission using permission_handler
      final status = await Permission.location.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      // For testing purposes, assume permission is granted
      // Remove this in production
      return true;
    }
  }

  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      // For testing purposes, return a mock location in Addis Ababa
      // Remove this in production
      return Position(
        latitude: 9.0192,
        longitude: 38.7525,
        timestamp: DateTime.now(),
        accuracy: 100.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }
  }

  Future<RouteData?> calculateRoute({
    required LatLng start,
    required LatLng destination,
    required String profile, // 'driving-car', 'foot-walking', 'cycling-regular'
  }) async {
    try {
      // Map our profile names to OSRM profile names
      String osrmProfile;
      switch (profile) {
        case 'driving-car':
          osrmProfile = 'driving';
          break;
        case 'foot-walking':
          osrmProfile = 'foot';
          break;
        case 'cycling-regular':
          osrmProfile = 'cycling';
          break;
        default:
          osrmProfile = 'driving';
      }

      // OSRM API format: /route/v1/{profile}/{coordinates}?overview=full&geometries=geojson
      final coordinates = '${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}';
      final url = '$_baseUrl/$osrmProfile/$coordinates?overview=full&geometries=geojson';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseOSRMRouteData(data);
      } else {
        debugPrint('Route calculation failed: ${response.statusCode}');
        // Fallback: create a simple straight-line route
        return _createFallbackRoute(start, destination);
      }
    } catch (e) {
      debugPrint('Error calculating route: $e');
      // Fallback: create a simple straight-line route
      return _createFallbackRoute(start, destination);
    }
  }

  RouteData? _parseOSRMRouteData(Map<String, dynamic> data) {
    try {
      final routes = data['routes'] as List;
      if (routes.isEmpty) return null;

      final route = routes[0];
      final geometry = route['geometry'];
      final coordinates = geometry['coordinates'] as List;
      
      // Convert coordinates to LatLng points
      final routePoints = coordinates
          .map((coord) => LatLng(coord[1], coord[0]))
          .toList();

      final distance = (route['distance'] as num).toDouble(); // in meters
      final duration = (route['duration'] as num).toDouble(); // in seconds

      return RouteData(
        points: routePoints,
        distance: distance,
        duration: Duration(seconds: duration.round()),
      );
    } catch (e) {
      debugPrint('Error parsing OSRM route data: $e');
      return null;
    }
  }

  RouteData? _createFallbackRoute(LatLng start, LatLng destination) {
    try {
      // Create a simple straight-line route as fallback
      final routePoints = [start, destination];
      
      // Calculate straight-line distance
      const Distance distance = Distance();
      final straightDistance = distance.as(LengthUnit.Meter, start, destination);
      
      // Estimate duration based on average speeds
      // Assume average walking speed of 5 km/h for fallback
      final estimatedDuration = Duration(seconds: (straightDistance / 1.39).round()); // 1.39 m/s = 5 km/h

      return RouteData(
        points: routePoints,
        distance: straightDistance,
        duration: estimatedDuration,
      );
    } catch (e) {
      debugPrint('Error creating fallback route: $e');
      return null;
    }
  }

  void startNavigation({
    required LatLng destination,
    required String profile,
  }) async {
    try {
      // Request location permission first
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        _navigationController.add(NavigationState.error('Location permission denied. Please grant location permission in settings.'));
        return;
      }

      // Try to get current location
      final currentPos = await getCurrentLocation();
      if (currentPos == null) {
        _navigationController.add(NavigationState.error('Could not get current location. Please ensure location services are enabled.'));
        return;
      }

      final start = LatLng(currentPos.latitude, currentPos.longitude);
      final routeData = await calculateRoute(
        start: start,
        destination: destination,
        profile: profile,
      );

      if (routeData == null) {
        _navigationController.add(NavigationState.error('Could not calculate route'));
        return;
      }

      _routePoints = routeData.points;
      _totalDistance = routeData.distance;
      _estimatedDuration = routeData.duration;

      // Start location tracking
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
        (position) {
          _updateNavigationState(position, destination);
        },
        onError: (error) {
          debugPrint('Location stream error: $error');
          _navigationController.add(NavigationState.error('Location tracking error: $error'));
        },
      );

      _navigationController.add(NavigationState.navigating(
        currentLocation: start,
        destination: destination,
        route: routeData,
        distanceRemaining: routeData.distance,
        estimatedTimeRemaining: routeData.duration,
      ));
    } catch (e) {
      debugPrint('Navigation start error: $e');
      _navigationController.add(NavigationState.error('Failed to start navigation: $e'));
    }
  }

  void _updateNavigationState(Position position, LatLng destination) {
    if (_routePoints == null || _totalDistance == null) return;

    final currentLocation = LatLng(position.latitude, position.longitude);
    
    // Calculate distance to destination
    final distanceToDestination = _calculateDistance(currentLocation, destination);
    
    // Estimate remaining time based on current speed and distance
    final speed = position.speed; // m/s
    Duration? estimatedTimeRemaining;
    if (speed > 0) {
      estimatedTimeRemaining = Duration(seconds: (distanceToDestination / speed).round());
    }

    _currentState = NavigationState.navigating(
      currentLocation: currentLocation,
      destination: destination,
      route: RouteData(
        points: _routePoints!,
        distance: _totalDistance!,
        duration: _estimatedDuration!,
      ),
      distanceRemaining: distanceToDestination,
      estimatedTimeRemaining: estimatedTimeRemaining,
    );

    _navigationController.add(_currentState!);
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  void stopNavigation() {
    _positionStream?.cancel();
    _positionStream = null;
    _routePoints = null;
    _totalDistance = null;
    _estimatedDuration = null;
    _currentState = null;
    _navigationController.add(NavigationState.idle());
  }

  void dispose() {
    stopNavigation();
    _navigationController.close();
  }
}

class RouteData {
  final List<LatLng> points;
  final double distance; // in meters
  final Duration duration;

  RouteData({
    required this.points,
    required this.distance,
    required this.duration,
  });
}

class NavigationState {
  final bool isNavigating;
  final LatLng? currentLocation;
  final LatLng? destination;
  final RouteData? route;
  final double? distanceRemaining; // in meters
  final Duration? estimatedTimeRemaining;
  final String? error;

  NavigationState._({
    required this.isNavigating,
    this.currentLocation,
    this.destination,
    this.route,
    this.distanceRemaining,
    this.estimatedTimeRemaining,
    this.error,
  });

  factory NavigationState.idle() {
    return NavigationState._(isNavigating: false);
  }

  factory NavigationState.navigating({
    required LatLng currentLocation,
    required LatLng destination,
    required RouteData route,
    required double distanceRemaining,
    Duration? estimatedTimeRemaining,
  }) {
    return NavigationState._(
      isNavigating: true,
      currentLocation: currentLocation,
      destination: destination,
      route: route,
      distanceRemaining: distanceRemaining,
      estimatedTimeRemaining: estimatedTimeRemaining,
    );
  }

  factory NavigationState.error(String error) {
    return NavigationState._(
      isNavigating: false,
      error: error,
    );
  }
}
