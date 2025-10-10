import 'package:derb/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class RoomFilterDialog extends ConsumerStatefulWidget {
  const RoomFilterDialog({super.key});

  @override
  ConsumerState<RoomFilterDialog> createState() => _RoomFilterDialogState();
}

class _RoomFilterDialogState extends ConsumerState<RoomFilterDialog> {
  // Define price and rating ranges
  final List<Map<String, dynamic>> priceRanges = [
    {'label': '200 - 500 ETB', 'minPrice': 200.0, 'maxPrice': 500.0},
    {'label': '500 - 1200 ETB', 'minPrice': 500.0, 'maxPrice': 1200.0},
    {'label': '1200 - 2000 ETB', 'minPrice': 1200.0, 'maxPrice': 2000.0},
    {'label': '2000 - 3000 ETB', 'minPrice': 2000.0, 'maxPrice': 3000.0},
    {'label': '3000 - 5000 ETB', 'minPrice': 3000.0, 'maxPrice': 5000.0},
  ];

  final List<Map<String, dynamic>> ratingRanges = [
    {'label': '0 - 1', 'minRating': 0.0, 'maxRating': 1.0},
    {'label': '1 - 2', 'minRating': 1.0, 'maxRating': 2.0},
    {'label': '2 - 3', 'minRating': 2.0, 'maxRating': 3.0},
    {'label': '3 - 4', 'minRating': 3.0, 'maxRating': 4.0},
    {'label': '4 - 5', 'minRating': 4.0, 'maxRating': 5.0},
  ];

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(roomFilterProvider);
    final minPrice = filter.minPrice;
    final maxPrice = filter.maxPrice;
    final minRating = filter.minRating;
    final maxRating = filter.maxRating;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final fontSize = isMobile ? 14.0 : 16.0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Filter Rooms',
        style: GoogleFonts.poppins(
          fontSize: fontSize + 4,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Price Range',
              style: GoogleFonts.poppins(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: priceRanges.map((range) {
                final isSelected = minPrice == range['minPrice'] && maxPrice == range['maxPrice'];
                return ChoiceChip(
                  label: Text(
                    range['label'],
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF1C9826),
                  backgroundColor: Colors.grey[200],
                  checkmarkColor: Colors.white,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(roomFilterProvider.notifier).updateFilter(
                        minPrice: range['minPrice'] as double,
                        maxPrice: range['maxPrice'] as double,
                      );
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Rating Range',
              style: GoogleFonts.poppins(
                fontSize: fontSize + 2,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ratingRanges.map((range) {
                final isSelected = minRating == range['minRating'] && maxRating == range['maxRating'];
                return ChoiceChip(
                  label: Text(
                    range['label'],
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF1C9826),
                  backgroundColor: Colors.grey[200],
                  checkmarkColor: Colors.white,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(roomFilterProvider.notifier).updateFilter(
                        minRating: range['minRating'] as double,
                        maxRating: range['maxRating'] as double,
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(roomFilterProvider.notifier).resetFilter();
            Navigator.of(context).pop();
          },
          child: Text(
            'Reset',
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              color: const Color(0xFF1C9826),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1C9826),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            'Apply',
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}