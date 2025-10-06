import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_fonts/google_fonts.dart';

// Provider for the selected filter
final roomFilterProvider = StateProvider<String>((ref) => 'All');

class RoomFilter extends ConsumerWidget {
  const RoomFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(roomFilterProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final fontSize = isMobile ? 14.0 : 16.0;

    return DropdownButton<String>(
      value: selectedFilter,
      isExpanded: true,
      icon: const Icon(Icons.filter_list, color: Color(0xFF1C9826)),
      underline: Container(
        height: 2,
        color: const Color(0xFF1C9826),
      ),
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        color: Colors.black87,
      ),
      items: ['All', 'Available', 'Booked'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          ref.read(roomFilterProvider.notifier).state = newValue;
        }
      },
    );
  }
}
