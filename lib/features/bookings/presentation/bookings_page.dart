import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:derb/features/bookings/data/bookings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../application/bookings_controller.dart';
import '../../auth/application/auth_controller.dart';

class BooksPage extends ConsumerStatefulWidget {
  const BooksPage({super.key});

  @override
  ConsumerState<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends ConsumerState<BooksPage> {
  bool _hasFetched = false; // Prevent repeated fetch calls

  @override
  void initState() {
    super.initState();
    _hasFetched = false;
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authControllerProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final isTablet =
        MediaQuery.sizeOf(context).width >= 600 &&
        MediaQuery.sizeOf(context).width < 900;

    String? userId;
    bool isTenant = false;
    bool isOwner = false;
    if (authStatus is AuthAuthenticated) {
      final session = ref.read(authRepositoryProvider).session;
      userId = session?.user.id;
      isTenant = session?.user.userMetadata?['role'] == 'tenant';
      isOwner = session?.user.userMetadata?['role'] == 'guest_house_owner';
    }

    ref.listen(bookingsControllerProvider, (previous, next) {
      if (next is BookingsError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message, style: GoogleFonts.poppins()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: next.isAuthError
                ? SnackBarAction(
                    label: 'Sign Out',
                    textColor: Colors.white,
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                  )
                : SnackBarAction(
                    label: 'Dismiss',
                    textColor: Colors.white,
                    onPressed: () =>
                        ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  ),
          ),
        );
      }
    });

    return Theme(
      data: _buildTheme(isMobile),
      child: Scaffold(
        body: Container(
          decoration:  BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1C9826).withOpacity(0.05),
                  Colors.white.withOpacity(0.9),
                ],
              ),
          ),
          child: CustomScrollView(
            slivers: [
              _buildAppBar(isMobile, isTenant),
              SliverToBoxAdapter(child: SizedBox(height: isMobile ? 16 : 24)),
              ..._buildRoleSlivers(
                userId,
                isTenant,
                isOwner,
                isMobile,
                isTablet,
              ),
              SliverToBoxAdapter(child: SizedBox(height: isMobile ? 16 : 24)),
            ],
          ),
        ),
      ),
    );
  }

  ThemeData _buildTheme(bool isMobile) {
    return ThemeData(
      primaryColor: const Color(0xFF1C9826),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1C9826),
        primary: const Color(0xFF1C9826),
        secondary: const Color(0xFF4CAF50),
        surface: Colors.white.withOpacity(0.95),
        error: Colors.redAccent,
        surfaceTint: Colors.transparent,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1C9826), width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 10 : 12,
        ),
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        errorStyle: GoogleFonts.poppins(color: Colors.redAccent),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF1C9826),
          textStyle: GoogleFonts.poppins(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isMobile, bool isTenant) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white.withOpacity(0.9),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          isTenant ? 'My Bookings' : 'Active Guest House Bookings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 20 : 24,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xFF1C9826), Color(0xFF4CAF50)],
              ).createShader(const Rect.fromLTWH(0, 0, 200, 20)),
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  List<Widget> _buildRoleSlivers(
    String? userId,
    bool isTenant,
    bool isOwner,
    bool isMobile,
    bool isTablet,
  ) {
    if (isTenant && userId != null) {
      return _buildTenantBookingSlivers(userId, isMobile, isTablet);
    } else if (isOwner && userId != null) {
      return _buildOwnerBookingSlivers(userId, isMobile, isTablet);
    } else {
      return [
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Text(
                'Please sign in as a tenant to view your bookings or as an owner to view active bookings',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 18 : 20,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ];
    }
  }

  List<Widget> _buildTenantBookingSlivers(
    String tenantId,
    bool isMobile,
    bool isTablet,
  ) {
    final bookingsStatus = ref.watch(bookingsControllerProvider);

    if (!_hasFetched && bookingsStatus is BookingsInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(bookingsControllerProvider.notifier)
            .fetchUserBookings(tenantId);
        _hasFetched = true;
      });
    }

    if (bookingsStatus is BookingsLoaded &&
        bookingsStatus.userBookings.isNotEmpty) {
      return [
        _buildBookingListOrGrid(
          bookingsStatus.userBookings,
          isMobile,
          isTablet,
        ),
      ];
    } else if (bookingsStatus is BookingsError ||
        bookingsStatus is BookingsLoaded) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
            child: _buildErrorBlock(
              bookingsStatus is BookingsError ? bookingsStatus : null,
              isMobile,
              onRetry: () {
                ref
                    .read(bookingsControllerProvider.notifier)
                    .fetchUserBookings(tenantId);
                _hasFetched = true;
              },
            ),
          ),
        ),
      ];
    } else {
      return [_buildShimmerLoading(isMobile, isTablet)];
    }
  }

  List<Widget> _buildOwnerBookingSlivers(
    String ownerId,
    bool isMobile,
    bool isTablet,
  ) {
    final bookingsStatus = ref.watch(bookingsControllerProvider);

    if (!_hasFetched && bookingsStatus is BookingsInitial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(bookingsControllerProvider.notifier)
            .fetchGuestHouseBookings(ownerId);
        _hasFetched = true;
      });
    }

    if (bookingsStatus is BookingsLoaded &&
        bookingsStatus.userBookings.isNotEmpty) {
      return [
        _buildBookingListOrGrid(
          bookingsStatus.userBookings,
          isMobile,
          isTablet,
        ),
      ];
    } else if (bookingsStatus is BookingsError ||
        bookingsStatus is BookingsLoaded) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
            child: _buildErrorBlock(
              bookingsStatus is BookingsError ? bookingsStatus : null,
              isMobile,
              onRetry: () {
                ref
                    .read(bookingsControllerProvider.notifier)
                    .fetchGuestHouseBookings(ownerId);
                _hasFetched = true;
              },
            ),
          ),
        ),
      ];
    } else {
      return [_buildShimmerLoading(isMobile, isTablet)];
    }
  }

  Widget _buildBookingListOrGrid(
    List<Booking> bookings,
    bool isMobile,
    bool isTablet,
  ) {
    if (isMobile) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 8,
            ),
            child: AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 200),
              child: _buildBookingCard(bookings[index], isMobile, isTablet),
            ),
          ),
          childCount: bookings.length,
        ),
      );
    } else {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 2 : 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isTablet ? 1.5 : 1.7,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => AnimatedScale(
              scale: 1.0,
              duration: const Duration(milliseconds: 200),
              child: _buildBookingCard(bookings[index], isMobile, isTablet),
            ),
            childCount: bookings.length,
          ),
        ),
      );
    }
  }

  Widget _buildShimmerLoading(bool isMobile, bool isTablet) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!.withOpacity(0.5),
          highlightColor: Colors.grey[100]!.withOpacity(0.3),
          period: const Duration(milliseconds: 800),
          child: GradientCard(
            child: Container(
              height: isMobile
                  ? 120
                  : isTablet
                  ? 140
                  : 160,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: isMobile ? 80 : 100,
                    height: isMobile ? 80 : 100,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 120, height: 16, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 160, height: 12, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 80, height: 12, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        childCount: 5,
      ),
    );
  }

  Widget _buildErrorBlock(
    BookingsError? error,
    bool isMobile, {
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            error != null ? 'No bookings available' : 'No bookings found',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 14 : 16,
              color: error != null
                  ? Theme.of(context).colorScheme.error
                  : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (onRetry != null)
            GradientButton(
              onPressed: onRetry,
              text: 'Retry',
              isMobile: isMobile,
            ),
          if (error?.isAuthError == true)
            GradientButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              text: 'Sign Out',
              isMobile: isMobile,
            ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, bool isMobile, bool isTablet) {
    final data = booking.toJson();
    final bedroomData = data['rooms'] as Map? ?? {};
    final guestHouse = bedroomData['guest_houses'] as Map? ?? {};
    final roomNumber = bedroomData['room_number']?.toString() ?? 'Unknown';
    final city = guestHouse['city']?.toString() ?? 'Unknown';
    final subCity = guestHouse['sub_city']?.toString() ?? 'Unknown';
    final imgUrl =
        bedroomData['room_pictures']?.toString().split(',')?.first ?? '';
    final statusColor = _getStatusColor(booking.status);

    String formatDate(DateTime? dt) =>
        dt == null ? '-' : DateFormat('MMM dd, yyyy').format(dt);

    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: GradientCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: isMobile
                    ? 100
                    : isTablet
                    ? 120
                    : 140,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200]),
                child: imgUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imgUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1C9826),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.meeting_room_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(
                        Icons.meeting_room_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Room $roomNumber in $city - $subCity',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 16 : 18,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [Color(0xFF1C9826), Color(0xFF4CAF50)],
                  ).createShader(const Rect.fromLTWH(0, 0, 200, 20)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'From: ${formatDate(booking.startDate)}',
              style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14),
            ),
            Text(
              'To: ${formatDate(booking.endDate)}',
              style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14),
            ),
            Text(
              'Total: ${booking.totalPrice} ETB',
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 12 : 14,
                color: const Color(0xFF1C9826),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(
                  status: booking.status,
                  color: statusColor,
                  isMobile: isMobile,
                ),
                if (booking.status.toLowerCase() == 'pending')
                  TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // TODO: Implement cancel booking
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'checked_in':
        return const Color(0xFF1C9826);
      case 'pending':
        return Colors.amber;
      case 'cancelled':
      case 'checked_out':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;

  const GradientCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Card(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1C9826).withOpacity(0.05),
                  Colors.white.withOpacity(0.9),
                ],
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isMobile;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
      child: Ink(
        decoration: const BoxDecoration(
          
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 12 : 16,
          ),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: isMobile ? 14 : 16,
            ),
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  final bool isMobile;

  const StatusBadge({
    super.key,
    required this.status,
    required this.color,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Status: $status',
        style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14, color: color),
      ),
    );
  }
}
