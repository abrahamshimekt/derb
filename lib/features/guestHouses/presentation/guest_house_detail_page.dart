import 'package:cached_network_image/cached_network_image.dart';
import 'package:derb/features/rooms/presentation/widgets/add_room_dialog.dart';
import 'package:derb/features/rooms/presentation/widgets/room_card.dart';
import 'package:derb/features/rooms/presentation/widgets/rooms_filter.dart';
import 'package:derb/features/rooms/presentation/widgets/rooms_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../auth/application/auth_controller.dart';
import '../../rooms/application/rooms_controller.dart';
import '../data/models/guest_house.dart';

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

class _GuestHouseDetailPageState extends ConsumerState<GuestHouseDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roomsNotifier = ref.read(roomsControllerProvider.notifier);
      roomsNotifier.fetchRooms(guestHouseId: widget.guestHouse.id);
      roomsNotifier.subscribe(guestHouseId: widget.guestHouse.id);
    });
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
        final padding = isMobile ? 16.0 : isTablet ? 24.0 : 32.0;
        final fontSizeTitle = isMobile ? 20.0 : isTablet ? 24.0 : 28.0;
        final fontSizeSubtitle = isMobile ? 16.0 : isTablet ? 18.0 : 20.0;
        final screenWidth = MediaQuery.sizeOf(context).width;
        final imageHeight = isMobile ? screenWidth * 0.95 : isTablet ? screenWidth * 0.65 : screenWidth * 0.55;

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
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8.0),
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
      expandedHeight: 80.0,
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
    );
  }

  Widget _buildContent(
    double padding,
    double fontSizeSubtitle,
    bool isMobile,
    bool isOwner,
    WidgetRef ref,
    double imageHeight,
  ) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: imageHeight,
            width: double.infinity,
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
                  Text(
                    'Rating: ${widget.guestHouse.rating}',
                    style: GoogleFonts.poppins(
                      fontSize: fontSizeSubtitle,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(height: 16),
                _buildSectionTitle('Rooms', fontSizeSubtitle),
                const SizedBox(height: 8),
                const RoomFilter(),
                const SizedBox(height: 8),
                _buildRoomsList(isOwner,padding, fontSizeSubtitle, isMobile, ref),
              ],
            ),
          ),
        ],
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
    WidgetRef ref,
  ) {
    final roomsStatus = ref.watch(roomsControllerProvider);
    if (roomsStatus is RoomsInitial) {
      return const Text('Initializing...');
    } else if (roomsStatus is RoomsLoading) {
      return const RoomShimmer();
    } else if (roomsStatus is RoomsLoaded) {
      final selectedFilter = ref.watch(roomFilterProvider);
      final rooms = roomsStatus.rooms.where((room) {
        if (selectedFilter == 'All') return true;
        return room.status.toLowerCase() == selectedFilter.toLowerCase();
      }).toList();
      if (rooms.isEmpty) {
        return Text(
          'No rooms available',
          style: GoogleFonts.poppins(
            fontSize: fontSizeSubtitle,
            color: Colors.grey[600],
          ),
        );
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          return RoomCard(
            isOwner:isOwner,
            room: rooms[index],
            padding: padding / 2,
            fontSizeSubtitle: fontSizeSubtitle,
          );
        },
      );
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
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AddRoomDialog(
            guestHouseId: widget.guestHouse.id,
            onClose: () => Navigator.pop(context),
          ),
        );
      },
      elevation: 4,
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
}