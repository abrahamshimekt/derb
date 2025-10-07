import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../data/models/guest_house.dart';

class GuestHousesFilterDialog extends StatefulWidget {
  final List<GuestHouse> guestHouses;
  final String? initialCityFilter;
  final String? initialRegionFilter;
  final String? initialSubCityFilter;
  final String initialSortOption;
  final Function(String?, String?, String?, String) onApply;

  const GuestHousesFilterDialog({
    super.key,
    required this.guestHouses,
    required this.initialCityFilter,
    required this.initialRegionFilter,
    required this.initialSubCityFilter,
    required this.initialSortOption,
    required this.onApply,
  });

  @override
  State<GuestHousesFilterDialog> createState() =>
      _GuestHousesFilterDialogState();
}

class _GuestHousesFilterDialogState extends State<GuestHousesFilterDialog>
    with SingleTickerProviderStateMixin {
  late String? tempCityFilter;
  late String? tempRegionFilter;
  late String? tempSubCityFilter;
  late String tempSortOption;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    tempCityFilter = widget.initialCityFilter;
    tempRegionFilter = widget.initialRegionFilter;
    tempSubCityFilter = widget.initialSubCityFilter;
    tempSortOption = widget.initialSortOption;
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
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
        ? 20.0
        : 24.0;
    final fontSizeTitle = isMobile ? 18.0 : 20.0;
    final fontSizeLabel = isMobile ? 14.0 : 16.0;
    final cities = widget.guestHouses.map((gh) => gh.city).toSet().toList()
      ..sort();
    final regions = widget.guestHouses.map((gh) => gh.region).toSet().toList()
      ..sort();
    final subCities =
        widget.guestHouses.map((gh) => gh.subCity).toSet().toList()..sort();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white.withOpacity(0.95),
      elevation: 8,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile
              ? MediaQuery.of(context).size.width * 0.9
              : isTablet
              ? 450
              : 500,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Guest Houses',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: fontSizeTitle,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [Color(0xFF1C9826), Color(0xFF4CAF50)],
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 20)),
                      ),
                      semanticsLabel: 'Filter Guest Houses',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sort By',
                      style: GoogleFonts.poppins(
                        fontSize: fontSizeLabel,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Sort Options',
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: Text(
                              'Default',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeLabel - 2,
                              ),
                            ),
                            value: 'Default',
                            groupValue: tempSortOption,
                            onChanged: (value) =>
                                setState(() => tempSortOption = value!),
                            activeColor: const Color(0xFF1C9826),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                          RadioListTile<String>(
                            title: Text(
                              'Rating (High to Low)',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeLabel - 2,
                              ),
                            ),
                            value: 'Rating',
                            groupValue: tempSortOption,
                            onChanged: (value) =>
                                setState(() => tempSortOption = value!),
                            activeColor: const Color(0xFF1C9826),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                          RadioListTile<String>(
                            title: Text(
                              'Number of Rooms (High to Low)',
                              style: GoogleFonts.poppins(
                                fontSize: fontSizeLabel - 2,
                              ),
                            ),
                            value: 'Rooms',
                            groupValue: tempSortOption,
                            onChanged: (value) =>
                                setState(() => tempSortOption = value!),
                            activeColor: const Color(0xFF1C9826),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Filter By',
                      style: GoogleFonts.poppins(
                        fontSize: fontSizeLabel,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'City Filter',
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'City',
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1C9826),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          prefixIcon: Icon(
                            Icons.location_city_rounded,
                            color: Colors.grey[600],
                            size: isMobile ? 20 : 22,
                          ),
                        ),
                        value: tempCityFilter,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Cities'),
                          ),
                          ...cities.map(
                            (city) => DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => tempCityFilter = value),
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: fontSizeLabel - 2,
                        ),
                        dropdownColor: Colors.white.withOpacity(0.95),
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: const Color(0xFF1C9826),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: 'Region Filter',
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Region',
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1C9826),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          prefixIcon: Icon(
                            Icons.map_rounded,
                            color: Colors.grey[600],
                            size: isMobile ? 20 : 22,
                          ),
                        ),
                        value: tempRegionFilter,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Regions'),
                          ),
                          ...regions.map(
                            (region) => DropdownMenuItem(
                              value: region,
                              child: Text(region),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => tempRegionFilter = value),
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: fontSizeLabel - 2,
                        ),
                        dropdownColor: Colors.white.withOpacity(0.95),
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: const Color(0xFF1C9826),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: 'Sub City Filter',
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Sub City',
                          labelStyle: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1C9826),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          prefixIcon: Icon(
                            Icons.location_on_rounded,
                            color: Colors.grey[600],
                            size: isMobile ? 20 : 22,
                          ),
                        ),
                        value: tempSubCityFilter,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Sub Cities'),
                          ),
                          ...subCities.map(
                            (subCity) => DropdownMenuItem(
                              value: subCity,
                              child: Text(subCity),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => tempSubCityFilter = value),
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: fontSizeLabel - 2,
                        ),
                        dropdownColor: Colors.white.withOpacity(0.95),
                        icon: Icon(
                          Icons.arrow_drop_down_rounded,
                          color: const Color(0xFF1C9826),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTapDown: (_) {
                            HapticFeedback.lightImpact();
                            _buttonAnimationController.forward();
                          },
                          onTapUp: (_) {
                            _buttonAnimationController.reverse();
                            setState(() {
                              tempCityFilter = null;
                              tempRegionFilter = null;
                              tempSubCityFilter = null;
                              tempSortOption = 'Default';
                            });
                          },
                          onTapCancel: () =>
                              _buttonAnimationController.reverse(),
                          child: AnimatedBuilder(
                            animation: _buttonScaleAnimation,
                            builder: (context, child) => Transform.scale(
                              scale: _buttonScaleAnimation.value,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    tempCityFilter = null;
                                    tempRegionFilter = null;
                                    tempSubCityFilter = null;
                                    tempSortOption = 'Default';
                                  });
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  textStyle: GoogleFonts.poppins(
                                    fontSize: fontSizeLabel - 2,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Clear'),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTapDown: (_) {
                                HapticFeedback.lightImpact();
                                _buttonAnimationController.forward();
                              },
                              onTapUp: (_) {
                                _buttonAnimationController.reverse();
                                Navigator.pop(context);
                              },
                              onTapCancel: () =>
                                  _buttonAnimationController.reverse(),
                              child: AnimatedBuilder(
                                animation: _buttonScaleAnimation,
                                builder: (context, child) => Transform.scale(
                                  scale: _buttonScaleAnimation.value,
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey[600],
                                      textStyle: GoogleFonts.poppins(
                                        fontSize: fontSizeLabel - 2,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTapDown: (_) {
                                HapticFeedback.lightImpact();
                                _buttonAnimationController.forward();
                              },
                              onTapUp: (_) {
                                _buttonAnimationController.reverse();
                                widget.onApply(
                                  tempCityFilter,
                                  tempRegionFilter,
                                  tempSubCityFilter,
                                  tempSortOption,
                                );
                                Navigator.pop(context);
                              },
                              onTapCancel: () =>
                                  _buttonAnimationController.reverse(),
                              child: AnimatedBuilder(
                                animation: _buttonScaleAnimation,
                                builder: (context, child) => Transform.scale(
                                  scale: _buttonScaleAnimation.value,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      widget.onApply(
                                        tempCityFilter,
                                        tempRegionFilter,
                                        tempSubCityFilter,
                                        tempSortOption,
                                      );
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF1C9826),
                                            Color(0xFF4CAF50),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 20 : 24,
                                          vertical: isMobile ? 12 : 14,
                                        ),
                                        child: Text(
                                          'Apply',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: fontSizeLabel - 2,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
