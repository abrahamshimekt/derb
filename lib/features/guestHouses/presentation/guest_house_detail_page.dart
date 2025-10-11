import 'package:cached_network_image/cached_network_image.dart';
import 'package:derb/features/rooms/presentation/widgets/add_room_dialog.dart';
import 'package:derb/features/rooms/presentation/widgets/room_card.dart';
import 'package:derb/features/rooms/presentation/widgets/rooms_filter.dart';
import 'package:derb/features/rooms/presentation/widgets/rooms_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'widgets/navigation_widget.dart';
import '../../../../core/navigation_service.dart';
import '../../auth/application/auth_controller.dart';
import '../../rooms/application/rooms_controller.dart';
import '../data/models/guest_house.dart';
import '../../../core/providers.dart';

class GuestHouseDetailPage extends ConsumerStatefulWidget {
  final GuestHouse guestHouse;
  final bool isMobile;
  final bool isTablet;

  const GuestHouseDetailPage({
    super.key,
    required this.guestHouse,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  ConsumerState<GuestHouseDetailPage> createState() => _GuestHouseDetailPageState();
}

class _GuestHouseDetailPageState extends ConsumerState<GuestHouseDetailPage> with SingleTickerProviderStateMixin {
  bool _isContentVisible = false;
  final MapController _mapController = MapController();
  String _selectedMapLayer = 'openstreetmap';
  bool _showNavigation = false;
  NavigationState? _navigationState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roomsNotifier = ref.read(roomsControllerProvider.notifier);
      roomsNotifier.fetchRooms(guestHouseId: widget.guestHouse.id);
      roomsNotifier.subscribe(guestHouseId: widget.guestHouse.id);
      
      setState(() {
        _isContentVisible = true;
      });
    });
  }

  void _onNavigationStateChanged(NavigationState state) {
    setState(() {
      _navigationState = state;
    });
    
    // Update map center to follow user when navigating
    if (state.isNavigating && state.currentLocation != null) {
      _mapController.move(state.currentLocation!, _mapController.camera.zoom);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _getTileLayerUrl(String mapType) {
    switch (mapType) {
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'terrain':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';
      case 'dark':
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
      case 'light':
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
      case 'outdoors':
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authControllerProvider);
    final isOwner = authStatus is AuthAuthenticated &&
        authStatus.session.user.userMetadata?['role'] == 'guest_house_owner' &&
        authStatus.session.user.id == widget.guestHouse.ownerId;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = widget.isMobile;
        final isTablet = widget.isTablet;
        final isDesktop = constraints.maxWidth >= 900;
        final padding = isMobile ? 16.0 : isTablet ? 24.0 : 32.0;
        final fontSizeTitle = isMobile ? 20.0 : isTablet ? 24.0 : 28.0;
        final fontSizeSubtitle = isMobile ? 14.0 : isTablet ? 16.0 : 18.0;
        final screenWidth = MediaQuery.of(context).size.width;
        final imageHeight = isMobile ? screenWidth * 0.8 : isTablet ? screenWidth * 0.6 : screenWidth * 0.5;

        return Theme(
          data: ThemeData(
            primaryColor: const Color(0xFF1C9826),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1C9826),
              secondary: Color(0xFF4CAF50),
              surface: Colors.white,
              error: Colors.redAccent,
              surfaceTint: Colors.transparent,
            ),
            textTheme: GoogleFonts.poppinsTextTheme().apply(
              bodyColor: Colors.black87,
              displayColor: Colors.black87,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 6,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
            ),
          ),
          child: PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                debugPrint('Back gesture invoked');
              }
            },
            child: Scaffold(
              body: CustomScrollView(
                slivers: [
                  _buildAppBar(fontSizeTitle),
                  _buildContent(
                    padding,
                    fontSizeSubtitle,
                    isMobile,
                    isTablet,
                    isDesktop,
                    isOwner,
                    ref,
                    imageHeight,
                  ),
                ],
              ),
              floatingActionButton: isOwner ? _buildAddRoomButton(isMobile) : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(double fontSizeTitle) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 100.0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Text(
        widget.guestHouse.guestHouseName,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: fontSizeTitle,
          foreground: Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFF1C9826), Color(0xFF4CAF50)],
            ).createShader(const Rect.fromLTWH(0, 0, 200, 20)),
        ),
      ),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
    );
  }

  Widget _buildContent(
    double padding,
    double fontSizeSubtitle,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    bool isOwner,
    WidgetRef ref,
    double imageHeight,
  ) {
    return SliverToBoxAdapter(
      child: AnimatedOpacity(
        opacity: _isContentVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: widget.guestHouse.pictureUrl != null
                  ? () => _showFullScreenImage(context, widget.guestHouse.pictureUrl!)
                  : null,
              child: SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: widget.guestHouse.pictureUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.guestHouse.pictureUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.grey[300]),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 40,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1C9826).withOpacity(0.05),
                    Colors.white.withOpacity(0.9),
                  ],
                ),
              ),
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Location', fontSizeSubtitle),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.guestHouse.city}, ${widget.guestHouse.subCity}, ${widget.guestHouse.region}',
                    style: GoogleFonts.poppins(
                      fontSize: fontSizeSubtitle,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.guestHouse.relativeLocationDescription,
                    style: GoogleFonts.poppins(
                      fontSize: fontSizeSubtitle - 1,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Map Location', fontSizeSubtitle),
                  const SizedBox(height: 8),
                  _buildMapLayerSelector(isMobile, isTablet),
                  const SizedBox(height: 8),
                  _buildMapSection(isMobile, isTablet),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Description', fontSizeSubtitle),
                  const SizedBox(height: 8),
                  Text(
                    widget.guestHouse.description,
                    style: GoogleFonts.poppins(
                      fontSize: fontSizeSubtitle,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Details', fontSizeSubtitle),
                  const SizedBox(height: 8),
                  Text(
                    'Number of Rooms: ${widget.guestHouse.numberOfRooms}',
                    style: GoogleFonts.poppins(
                      fontSize: fontSizeSubtitle,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (widget.guestHouse.rating != null)
                    _buildGuestHouseRating(widget.guestHouse.rating!, fontSizeSubtitle),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Rooms', fontSizeSubtitle),
                      IconButton(
                        icon: const Icon(
                          Icons.filter_list,
                          color: Color(0xFF1C9826),
                          size: 28,
                        ),
                        tooltip: 'Filter Rooms',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const RoomFilterDialog(),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildRoomsList(isOwner, padding, fontSizeSubtitle, isMobile, isTablet, isDesktop, ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, double fontSizeSubtitle) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: fontSizeSubtitle + 2,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildRoomsList(
    bool isOwner,
    double padding,
    double fontSizeSubtitle,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    WidgetRef ref,
  ) {
    final roomsStatus = ref.watch(roomsControllerProvider);
    final filter = ref.watch(roomFilterProvider);
    final minPrice = filter.minPrice;
    final maxPrice = filter.maxPrice;
    final minRating = filter.minRating;
    final maxRating = filter.maxRating;

    if (roomsStatus is RoomsInitial) {
      return const Text('Initializing...');
    } else if (roomsStatus is RoomsLoading) {
      return const RoomShimmer();
    } else if (roomsStatus is RoomsLoaded) {
      final rooms = roomsStatus.rooms.where((room) {
        final priceInRange = room.price >= minPrice && room.price <= maxPrice;
        final ratingInRange = (room.rating >= minRating && room.rating <= maxRating);
        return priceInRange && ratingInRange;
      }).toList();

      if (rooms.isEmpty) {
        return Text(
          'No rooms match the filters',
          style: GoogleFonts.poppins(
            fontSize: fontSizeSubtitle,
            color: Colors.grey[600],
          ),
        );
      }

      if (isDesktop || isTablet) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 3 : 2,
            crossAxisSpacing: padding,
            mainAxisSpacing: padding,
            childAspectRatio: isDesktop ? 1.2 : 1.0,
          ),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            return AnimatedOpacity(
              opacity: _isContentVisible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300 + index * 100),
              child: RoomCard(
                isOwner: isOwner,
                room: rooms[index],
                padding: padding / 2,
                fontSizeSubtitle: fontSizeSubtitle,
              ),
            );
          },
        );
      } else {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            return AnimatedOpacity(
              opacity: _isContentVisible ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300 + index * 100),
              child: RoomCard(
                isOwner: isOwner,
                room: rooms[index],
                padding: padding / 2,
                fontSizeSubtitle: fontSizeSubtitle,
              ),
            );
          },
        );
      }
    } else if (roomsStatus is RoomsError) {
      return Column(
        children: [
          Text(
            roomsStatus.message,
            style: GoogleFonts.poppins(
              fontSize: fontSizeSubtitle,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 8),
          if (roomsStatus.isNetworkError) _buildRetryButton(padding, isMobile, ref),
          if (roomsStatus.isAuthError) _buildSignInButton(padding, isMobile, ref),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildRetryButton(double padding, bool isMobile, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => ref.read(roomsControllerProvider.notifier).fetchRooms(guestHouseId: widget.guestHouse.id),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1C9826), Color(0xFF4CAF50)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 24,
            vertical: isMobile ? 12 : 14,
          ),
          child: Text(
            'Retry',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(double padding, bool isMobile, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1C9826), Color(0xFF4CAF50)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 24,
            vertical: isMobile ? 12 : 14,
          ),
          child: Text(
            'Sign In',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddRoomButton(bool isMobile) {
    return FloatingActionButton(
      heroTag: "add_room_fab",
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AddRoomDialog(
            guestHouseId: widget.guestHouse.id,
            onClose: () => Navigator.pop(context),
          ),
        );
      },
      elevation: 6,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF1C9826), Color(0xFF4CAF50)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.add_rounded,
            size: isMobile ? 26 : 30,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGuestHouseRating(double rating, double fontSize) {
    return Row(
      children: [
        Text(
          'Rating: ',
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            color: Colors.grey[600],
          ),
        ),
        RatingBarIndicator(
          rating: rating,
          itemBuilder: (context, _) => const Icon(
            Icons.star,
            color: Colors.amber,
          ),
          itemCount: 5,
          itemSize: fontSize + 2,
          unratedColor: Colors.grey[300],
        ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMapLayerSelector(bool isMobile, bool isTablet) {
    final mapLayers = [
      {'key': 'openstreetmap', 'name': 'Standard', 'icon': Icons.map},
      {'key': 'satellite', 'name': 'Satellite', 'icon': Icons.satellite},
      {'key': 'terrain', 'name': 'Terrain', 'icon': Icons.terrain},
      {'key': 'dark', 'name': 'Dark', 'icon': Icons.dark_mode},
      {'key': 'light', 'name': 'Light', 'icon': Icons.light_mode},
      {'key': 'outdoors', 'name': 'Outdoors', 'icon': Icons.hiking},
    ];

    return Container(
      height: isMobile ? 45 : 50,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mapLayers.length,
        itemBuilder: (context, index) {
          final layer = mapLayers[index];
          final isSelected = _selectedMapLayer == layer['key'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    layer['icon'] as IconData,
                    size: isMobile ? 14 : 16,
                    color: isSelected ? Colors.white : const Color(0xFF1C9826),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    layer['name'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF1C9826),
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedMapLayer = layer['key'] as String;
                  });
                }
              },
              selectedColor: const Color(0xFF1C9826),
              backgroundColor: Colors.grey[100],
              side: BorderSide(
                color: isSelected ? const Color(0xFF1C9826) : Colors.grey[300]!,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: isSelected ? 2 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapSection(bool isMobile, bool isTablet) {
    final mapHeight = isMobile ? 280.0 : isTablet ? 350.0 : 420.0;
    
    return Container(
      height: mapHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(widget.guestHouse.latitude, widget.guestHouse.longitude),
            initialZoom: 15.0,
            minZoom: 5.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: _getTileLayerUrl(_selectedMapLayer),
              userAgentPackageName: 'com.example.derb',
              maxZoom: 18,
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            // Route layer (only show when navigating)
            if (_navigationState?.route != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _navigationState!.route!.points,
                    strokeWidth: 4.0,
                    color: const Color(0xFF1C9826),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                // Guest house marker
                Marker(
                  point: LatLng(widget.guestHouse.latitude, widget.guestHouse.longitude),
                  width: 50,
                  height: 50,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedMapLayer == 'dark' ? Colors.orange : const Color(0xFF1C9826),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedMapLayer == 'dark' ? Colors.white : Colors.white, 
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                // Current location marker (only show when navigating)
                if (_navigationState?.currentLocation != null)
                  Marker(
                    point: _navigationState!.currentLocation!,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
            _buildMapControls(),
            // Navigation widget overlay
            if (_showNavigation)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Stack(
                  children: [
                    NavigationWidget(
                      destination: LatLng(widget.guestHouse.latitude, widget.guestHouse.longitude),
                      guestHouseName: widget.guestHouse.guestHouseName,
                      onNavigationStateChanged: _onNavigationStateChanged,
                    ),
                    // Cancel button for navigation overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _showNavigation = false;
                            });
                          },
                          icon: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                          tooltip: 'Close Navigation',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 12,
      right: 12,
      child: Column(
        children: [
          // Navigation Toggle Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FloatingActionButton.small(
              heroTag: "map_navigation_fab",
              onPressed: () {
                setState(() {
                  _showNavigation = !_showNavigation;
                });
              },
              backgroundColor: _showNavigation ? const Color(0xFF1C9826) : Colors.white,
              child: Icon(
                Icons.navigation,
                color: _showNavigation ? Colors.white : const Color(0xFF1C9826),
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Location Center Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FloatingActionButton.small(
              heroTag: "map_location_fab",
              onPressed: () {
                _mapController.move(
                  LatLng(widget.guestHouse.latitude, widget.guestHouse.longitude),
                  _mapController.camera.zoom,
                );
              },
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.my_location,
                color: Color(0xFF1C9826),
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Zoom Controls Container
          Container(
            decoration: BoxDecoration(
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
              children: [
                FloatingActionButton.small(
                  heroTag: "map_zoom_in_fab",
                  onPressed: () {
                    _mapController.move(
                      LatLng(widget.guestHouse.latitude, widget.guestHouse.longitude),
                      _mapController.camera.zoom + 1,
                    );
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.add,
                    color: Color(0xFF1C9826),
                    size: 18,
                  ),
                ),
                Container(
                  height: 1,
                  width: 32,
                  color: Colors.grey[300],
                ),
                FloatingActionButton.small(
                  heroTag: "map_zoom_out_fab",
                  onPressed: () {
                    _mapController.move(
                      LatLng(widget.guestHouse.latitude, widget.guestHouse.longitude),
                      _mapController.camera.zoom - 1,
                    );
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.remove,
                    color: Color(0xFF1C9826),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black87,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.7,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.grey[300]),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}