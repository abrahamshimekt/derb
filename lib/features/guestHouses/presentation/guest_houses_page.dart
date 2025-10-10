import 'package:derb/core/providers.dart';
import 'package:derb/core/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'widgets/create_guest_house_dialog.dart';
import 'widgets/guest_house_card.dart';
import 'widgets/guest_houses_filter_dialog.dart';
import 'widgets/guest_houses_shimmer.dart';
import '../application/guest_houses_controller.dart';
import '../../auth/application/auth_controller.dart';
import '../data/models/guest_house.dart';
import 'package:rxdart/rxdart.dart';

class GuestHousesPage extends ConsumerStatefulWidget {
  const GuestHousesPage({super.key});

  @override
  ConsumerState<GuestHousesPage> createState() => _GuestHousesPageState();
}

class _GuestHousesPageState extends ConsumerState<GuestHousesPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _debouncer = PublishSubject<String>();
  String _sortOption = 'Default';
  String? _cityFilter;
  String? _regionFilter;
  String? _subCityFilter;
  late AnimationController _filterAnimationController;
  late Animation<double> _filterRotation;

  @override
  void initState() {
    super.initState();
    _debouncer.stream.debounceTime(const Duration(milliseconds: 300)).listen((
      value,
    ) {
      setState(() {});
    });
    _filterAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filterRotation = Tween<double>(begin: 0, end: 0.25).animate(
      CurvedAnimation(
        parent: _filterAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.close();
    _filterAnimationController.dispose();
    super.dispose();
  }

  List<GuestHouse> _filterGuestHouses(
    List<GuestHouse> guestHouses,
    String query,
  ) {
    // Single-pass filtering for better performance
    final lowercaseQuery = query.toLowerCase();
    return guestHouses.where((gh) {
      // Search query filter
      if (query.isNotEmpty) {
        final city = gh.city.toLowerCase();
        final subCity = gh.subCity.toLowerCase();
        final guestHouseName = gh.guestHouseName.toLowerCase();
        final matchesSearch = city.contains(lowercaseQuery) ||
            subCity.contains(lowercaseQuery) ||
            guestHouseName.contains(lowercaseQuery);
        if (!matchesSearch) return false;
      }
      
      // City filter
      if (_cityFilter != null && gh.city != _cityFilter) return false;
      
      // Region filter
      if (_regionFilter != null && gh.region != _regionFilter) return false;
      
      // Sub-city filter
      if (_subCityFilter != null && gh.subCity != _subCityFilter) return false;
      
      return true;
    }).toList();
  }

  List<GuestHouse> _sortGuestHouses(List<GuestHouse> guestHouses) {
    if (_sortOption == 'Rating') {
      return guestHouses
        ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    } else if (_sortOption == 'Rooms') {
      return guestHouses
        ..sort((a, b) => b.numberOfRooms.compareTo(a.numberOfRooms));
    }
    return guestHouses;
  }

  void _showCreateGuestHouseDialog(String ownerId) {
    showDialog(
      context: context,
      builder: (context) => CreateGuestHouseDialog(
        ownerId: ownerId,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _showFilterDialog(List<GuestHouse> guestHouses) {
    _filterAnimationController.forward();
    showDialog(
      context: context,
      builder: (context) => GuestHousesFilterDialog(
        guestHouses: guestHouses,
        initialCityFilter: _cityFilter,
        initialRegionFilter: _regionFilter,
        initialSubCityFilter: _subCityFilter,
        initialSortOption: _sortOption,
        onApply: (city, region, subCity, sortOption) {
          setState(() {
            _cityFilter = city;
            _regionFilter = region;
            _subCityFilter = subCity;
            _sortOption = sortOption;
          });
          _filterAnimationController.reverse();
        },
      ),
    ).then((_) => _filterAnimationController.reverse());
  }

  Future<void> _refreshData() async {
    final authState = ref.read(authStateProvider);
    if (authState.isAuthenticated && authState.userId != null) {
      final role = authState.isOwner ? 'guest_house_owner' : 'tenant';
      await ref
          .read(guestHousesControllerProvider.notifier)
          .fetchGuestHouses(userId: authState.userId, role: role);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet =
        MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 900;
    final padding = isMobile
        ? 16.0
        : isTablet
        ? 24.0
        : 32.0;
    final fontSizeTitle = isMobile
        ? 20.0
        : isTablet
        ? 24.0
        : 28.0;

    return Theme(
      data: ThemeData(
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
          hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white.withOpacity(0.2),
          clipBehavior: Clip.antiAlias,
        ),
      ),
      child: Consumer(
        builder: (context, ref, child) {
          // Watch auth state and guest houses state once
          final authState = ref.watch(authStateProvider);
          final guestHousesState = ref.watch(guestHousesControllerProvider);
          
          // Listen to refresh trigger for tab index 0 (Home)
          ref.listen(tabRefreshProvider, (previous, next) {
            if (next.getRefreshCount(0) > (previous?.getRefreshCount(0) ?? 0)) {
              _refreshData();
            }
          });

          return SafeArea(
            child: Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1C9826).withOpacity(0.05),
                      Colors.white.withOpacity(0.9),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Fixed AppBar and Search Bar
                    Material(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.1),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            AppBar(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              title: Text(
                                'Guest Houses',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: fontSizeTitle,
                                  foreground: Paint()
                                    ..shader =
                                        const LinearGradient(
                                          colors: [
                                            Color(0xFF1C9826),
                                            Color(0xFF4CAF50),
                                          ],
                                        ).createShader(
                                          const Rect.fromLTWH(0, 0, 200, 20),
                                        ),
                                ),
                              ),
                              centerTitle: true,
                              actions: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTapDown: (_) =>
                                        _filterAnimationController.forward(),
                                    onTapUp: (_) =>
                                        _filterAnimationController.reverse(),
                                    child: AnimatedBuilder(
                                      animation: _filterAnimationController,
                                      builder: (context, child) => Transform.rotate(
                                        angle:
                                            _filterRotation.value * 2 * 3.14159,
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.filter_list_rounded,
                                            size: isMobile ? 26 : 30,
                                            color: const Color(0xFF1C9826),
                                          ),
                                          onPressed: () => _showFilterDialog(
                                            guestHousesState is GuestHousesLoaded
                                                ? guestHousesState.guestHouses
                                                : [],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                padding,
                                8,
                                padding,
                                16,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 8,
                                    sigmaY: 8,
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Search Guest Houses...',
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: const Color(0xFF1C9826),
                                        size: isMobile ? 22 : 24,
                                      ),
                                      suffixIcon: AnimatedOpacity(
                                        opacity:
                                            _searchController.text.isNotEmpty
                                            ? 1.0
                                            : 0.0,
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.clear_rounded,
                                            color: const Color(0xFF1C9826),
                                            size: isMobile ? 22 : 24,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.9),
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 14 : 16,
                                    ),
                                    onChanged: (value) => _debouncer.add(value),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Scrollable Content
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshData,
                        color: const Color(0xFF1C9826),
                        backgroundColor: Colors.white,
                        child: CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: padding,
                                vertical: 16,
                              ),
                              sliver: guestHousesState is GuestHousesLoading
                                  ? GuestHousesShimmer(
                                      width: MediaQuery.of(context).size.width,
                                      isMobile: isMobile,
                                      isTablet: isTablet,
                                    )
                                  : guestHousesState is GuestHousesError
                                  ? SliverToBoxAdapter(
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error_outline_rounded,
                                              size: isMobile ? 40 : 48,
                                              color: Colors.redAccent,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              guestHousesState.message,
                                              style: GoogleFonts.poppins(
                                                color: Colors.redAccent,
                                                fontSize: isMobile ? 14 : 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 16),
                                            if (guestHousesState.isNetworkError)
                                              ElevatedButton(
                                                onPressed: () {
                                                  final role = authState.isOwner ? 'guest_house_owner' : 'tenant';
                                                  ref
                                                      .read(
                                                        guestHousesControllerProvider
                                                            .notifier,
                                                      )
                                                      .fetchGuestHouses(
                                                        userId: authState.userId,
                                                        role: role,
                                                      );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                child: Ink(
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                          colors: [
                                                            Color(0xFF1C9826),
                                                            Color(0xFF4CAF50),
                                                          ],
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: isMobile
                                                              ? 20
                                                              : 24,
                                                          vertical: isMobile
                                                              ? 12
                                                              : 14,
                                                        ),
                                                    child: Text(
                                                      'Retry',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color: Colors.white,
                                                            fontSize: isMobile
                                                                ? 14
                                                                : 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            if (guestHousesState.isAuthError)
                                              ElevatedButton(
                                                onPressed: () => ref
                                                    .read(
                                                      authControllerProvider
                                                          .notifier,
                                                    )
                                                    .signOut(),
                                                style: ElevatedButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                child: Ink(
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                          colors: [
                                                            Color(0xFF1C9826),
                                                            Color(0xFF4CAF50),
                                                          ],
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: isMobile
                                                              ? 20
                                                              : 24,
                                                          vertical: isMobile
                                                              ? 12
                                                              : 14,
                                                        ),
                                                    child: Text(
                                                      'Sign In',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color: Colors.white,
                                                            fontSize: isMobile
                                                                ? 14
                                                                : 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : guestHousesState is GuestHousesLoaded
                                  ? Builder(
                                      builder: (context) {
                                        final filteredGuestHouses =
                                            _filterGuestHouses(
                                              guestHousesState.guestHouses,
                                              _searchController.text.trim(),
                                            );
                                        final sortedGuestHouses =
                                            _sortGuestHouses(
                                              filteredGuestHouses,
                                            );
                                        if (sortedGuestHouses.isEmpty) {
                                          return SliverToBoxAdapter(
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.search_off_rounded,
                                                    size: isMobile ? 40 : 48,
                                                    color: Colors.grey[500],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'No guest houses match your search',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: isMobile
                                                          ? 14
                                                          : 16,
                                                      color: Colors.grey[700],
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }
                                        return isMobile
                                            ? SliverList(
                                                delegate: SliverChildBuilderDelegate(
                                                  (context, index) {
                                                    final guestHouse =
                                                        sortedGuestHouses[index];
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 16,
                                                          ),
                                                      child: AnimatedScale(
                                                        scale: 1.0,
                                                        duration:
                                                            const Duration(
                                                              milliseconds: 300,
                                                            ),
                                                        curve:
                                                            Curves.easeOutCubic,
                                                        child: GuestHouseCard(
                                                          guestHouse:
                                                              guestHouse,
                                                          isMobile: isMobile,
                                                          isTablet: isTablet,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  childCount:
                                                      sortedGuestHouses.length,
                                                ),
                                              )
                                            : SliverGrid(
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: isTablet
                                                          ? 2
                                                          : 3,
                                                      crossAxisSpacing: 16,
                                                      mainAxisSpacing: 16,
                                                      childAspectRatio: isTablet
                                                          ? 0.75
                                                          : 0.8,
                                                    ),
                                                delegate:
                                                    SliverChildBuilderDelegate(
                                                      (context, index) {
                                                        final guestHouse =
                                                            sortedGuestHouses[index];
                                                        return AnimatedScale(
                                                          scale: 1.0,
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    300,
                                                              ),
                                                          curve: Curves
                                                              .easeOutCubic,
                                                          child: GuestHouseCard(
                                                            guestHouse:
                                                                guestHouse,
                                                            isMobile: isMobile,
                                                            isTablet: isTablet,
                                                          ),
                                                        );
                                                      },
                                                      childCount:
                                                          sortedGuestHouses
                                                              .length,
                                                    ),
                                              );
                                      },
                                    )
                                  : SliverToBoxAdapter(
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error_outline_rounded,
                                              size: isMobile ? 40 : 48,
                                              color: Colors.redAccent,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Unable to load guest houses. Please try again.',
                                              style: GoogleFonts.poppins(
                                                fontSize: isMobile ? 14 : 16,
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              floatingActionButton: authState.isOwner && authState.userId != null
                  ? FloatingActionButton(
                      onPressed: () => _showCreateGuestHouseDialog(authState.userId!),
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
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
