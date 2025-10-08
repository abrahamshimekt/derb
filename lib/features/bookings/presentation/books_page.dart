import 'package:derb/features/bookings/data/models/booking.dart';
import 'package:derb/features/bookings/presentation/widgets/books_card.dart';
import 'package:derb/features/bookings/presentation/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../application/bookings_controller.dart';
import '../../auth/application/auth_controller.dart';

class BooksPage extends ConsumerStatefulWidget {
  const BooksPage({super.key});

  @override
  ConsumerState<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends ConsumerState<BooksPage> {
  String? _userId;
  bool _isTenant = false;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();

    // One-time listener for errors
    ref.listenManual<BookingsStatus>(bookingsControllerProvider, (prev, next) {
      if (!mounted) return;
      if (next is BookingsError) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message, style: GoogleFonts.poppins()),
            backgroundColor: theme.colorScheme.error,
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

    // Kick off initial load after first frame so ref reads are safe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authStatus = ref.read(authControllerProvider);
      if (authStatus is AuthAuthenticated) {
        final session = ref.read(authRepositoryProvider).session;
        _userId = session?.user.id;
        _isTenant = session?.user.userMetadata?['role'] == 'tenant';
        _isOwner = session?.user.userMetadata?['role'] == 'guest_house_owner';

        if (_userId != null) {
          final notifier = ref.read(bookingsControllerProvider.notifier);
          if (_isTenant) {
            notifier.fetchUserBookings(_userId!);
          } else if (_isOwner) {
            notifier.fetchGuestHouseBookings(_userId!);
          }
        }
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 900;

    return Theme(
      data: _buildTheme(isMobile),
      child: SafeArea(
        child: Scaffold(
          body: Container(
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
            child: CustomScrollView(
              slivers: [
                _buildAppBar(isMobile),
                SliverToBoxAdapter(child: SizedBox(height: isMobile ? 16 : 24)),
                ..._buildRoleSlivers(
                  _userId,
                  _isTenant,
                  _isOwner,
                  isMobile,
                  isTablet,
                ),
                SliverToBoxAdapter(child: SizedBox(height: isMobile ? 16 : 24)),
              ],
            ),
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
          backgroundColor: const Color(0xFF1C9826), // Default color for buttons
          foregroundColor: Colors.white, // Ensure text/icon is white
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 2, // Slight elevation for visibility
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

  SliverAppBar _buildAppBar(bool isMobile) {
    final title = _isTenant ? 'My Bookings' : 'Active Guest House Bookings';
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white.withOpacity(0.9),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
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
    final state = ref.watch(bookingsControllerProvider);

    if (userId == null || (!isTenant && !isOwner)) {
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

    if (state is BookingsLoading || state is BookingsInitial) {
      return [_buildShimmerLoading(isMobile, isTablet)];
    }

    if (state is BookingsLoaded && state.userBookings.isNotEmpty) {
      return [_buildBookingListOrGrid(state.userBookings, isMobile, isTablet)];
    }

    // Error or empty
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
          child: _buildErrorBlock(
            state is BookingsError ? state : null,
            isMobile,
            onRetry: () {
              final notifier = ref.read(bookingsControllerProvider.notifier);
              if (isTenant) {
                notifier.fetchUserBookings(userId);
              } else {
                notifier.fetchGuestHouseBookings(userId);
              }
            },
          ),
        ),
      ),
    ];
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
              duration: const Duration(milliseconds: 150),
              child: BooksCard(
                isOwner: _isOwner,
                booking: bookings[index],
                isMobile: isMobile,
                isTablet: isTablet,
                onApprove: _isOwner && bookings[index].status.toLowerCase() == 'pending'
                    ? () => ref.read(bookingsControllerProvider.notifier).approveBooking(bookings[index].id)
                    : null,
                onCheckIn: _isOwner && bookings[index].status.toLowerCase() == 'approved'
                    ? () => ref.read(bookingsControllerProvider.notifier).checkInBooking(bookings[index].id)
                    : null,
                onCheckOut: _isOwner && bookings[index].status.toLowerCase() == 'checked_in'
                    ? () => ref.read(bookingsControllerProvider.notifier).checkOutBooking(bookings[index].id)
                    : null,
                onCancel: bookings[index].status.toLowerCase() != 'checked_in' &&
                          bookings[index].status.toLowerCase() != 'checked_out' &&
                          bookings[index].status.toLowerCase() != 'cancelled'
                    ? () => ref.read(bookingsControllerProvider.notifier).cancelBooking(bookings[index].id)
                    : null,
              ),
            ),
          ),
          childCount: bookings.length,
        ),
      );
    }

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
            duration: const Duration(milliseconds: 150),
            child: BooksCard(
              isOwner: _isOwner,
              booking: bookings[index],
              isMobile: isMobile,
              isTablet: isTablet,
              onApprove: _isOwner && bookings[index].status.toLowerCase() == 'pending'
                  ? () => ref.read(bookingsControllerProvider.notifier).approveBooking(bookings[index].id)
                  : null,
              onCheckIn: _isOwner && bookings[index].status.toLowerCase() == 'approved'
                  ? () => ref.read(bookingsControllerProvider.notifier).checkInBooking(bookings[index].id)
                  : null,
              onCheckOut: _isOwner && bookings[index].status.toLowerCase() == 'checked_in'
                  ? () => ref.read(bookingsControllerProvider.notifier).checkOutBooking(bookings[index].id)
                  : null,
              onCancel: bookings[index].status.toLowerCase() != 'checked_in' &&
                        bookings[index].status.toLowerCase() != 'checked_out' &&
                        bookings[index].status.toLowerCase() != 'cancelled'
                  ? () => ref.read(bookingsControllerProvider.notifier).cancelBooking(bookings[index].id)
                  : null,
            ),
          ),
          childCount: bookings.length,
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(bool isMobile, bool isTablet) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!.withOpacity(0.5),
          highlightColor: Colors.grey[100]!.withOpacity(0.3),
          period: const Duration(milliseconds: 900),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 8,
            ),
            height: isMobile ? 120 : (isTablet ? 140 : 160),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
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
        childCount: 5,
      ),
    );
  }

  Widget _buildErrorBlock(
    BookingsError? error,
    bool isMobile, {
    VoidCallback? onRetry,
  }) {
    final isAuth = error?.isAuthError == true;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            error != null ? 'No bookings available' : 'No bookings found',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 14 : 16,
              color: error != null ? Colors.redAccent : Colors.grey,
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
          if (isAuth)
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
}