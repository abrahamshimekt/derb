import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/navigation_service.dart';

class NavigationWidget extends ConsumerStatefulWidget {
  final LatLng destination;
  final String guestHouseName;
  final Function(NavigationState)? onNavigationStateChanged;

  const NavigationWidget({
    super.key,
    required this.destination,
    required this.guestHouseName,
    this.onNavigationStateChanged,
  });

  @override
  ConsumerState<NavigationWidget> createState() => _NavigationWidgetState();
}

class _NavigationWidgetState extends ConsumerState<NavigationWidget> {
  final NavigationService _navigationService = NavigationService();
  StreamSubscription<NavigationState>? _navigationSubscription;
  NavigationState? _currentState;
  String _selectedProfile = 'driving-car';
  bool _isNavigating = false;

  final Map<String, Map<String, dynamic>> _transportProfiles = {
    'driving-car': {
      'name': 'Driving',
      'icon': Icons.directions_car,
      'color': Colors.blue,
    },
    'foot-walking': {
      'name': 'Walking',
      'icon': Icons.directions_walk,
      'color': Colors.green,
    },
    'cycling-regular': {
      'name': 'Cycling',
      'icon': Icons.directions_bike,
      'color': Colors.orange,
    },
  };

  @override
  void initState() {
    super.initState();
    _navigationSubscription = _navigationService.navigationStream.listen((state) {
      setState(() {
        _currentState = state;
        _isNavigating = state.isNavigating;
      });
      widget.onNavigationStateChanged?.call(state);
    });
  }

  @override
  void dispose() {
    _navigationSubscription?.cancel();
    _navigationService.dispose();
    super.dispose();
  }

  void _startNavigation() {
    _navigationService.startNavigation(
      destination: widget.destination,
      profile: _selectedProfile,
    );
  }

  void _stopNavigation() {
    _navigationService.stopNavigation();
  }

  String _formatDistance(double? distanceInMeters) {
    if (distanceInMeters == null) return 'Unknown';
    
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'Unknown';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      margin: EdgeInsets.all(isMobile ? 12 : 16),
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.4, // Limit height to 40% of screen
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Navigation Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.navigation,
                      color: const Color(0xFF1C9826),
                      size: isMobile ? 20 : 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Navigate to ${widget.guestHouseName}',
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (_isNavigating)
                      IconButton(
                        onPressed: _stopNavigation,
                        icon: const Icon(Icons.stop, color: Colors.red),
                        tooltip: 'Stop Navigation',
                      )
                    else
                      IconButton(
                        onPressed: () {
                          // This will be handled by the parent widget
                          // The close button in the parent will handle this
                        },
                        icon: const Icon(Icons.close, color: Colors.grey),
                        tooltip: 'Close Navigation',
                      ),
                  ],
                ),
                
                if (_currentState?.error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentState!.error!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (_isNavigating && _currentState != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.straighten,
                          label: 'Distance',
                          value: _formatDistance(_currentState!.distanceRemaining),
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.access_time,
                          label: 'ETA',
                          value: _formatDuration(_currentState!.estimatedTimeRemaining),
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Transport Mode Selector
          if (!_isNavigating) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transport Mode',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _transportProfiles.entries.map((entry) {
                      final isSelected = _selectedProfile == entry.key;
                      final profile = entry.value;
                      
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedProfile = entry.key;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? profile['color'] as Color
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected 
                                      ? profile['color'] as Color
                                      : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    profile['icon'] as IconData,
                                    size: 14,
                                    color: isSelected 
                                        ? Colors.white
                                        : profile['color'] as Color,
                                  ),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      profile['name'] as String,
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected 
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _startNavigation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C9826),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.navigation, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Start Navigation',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
