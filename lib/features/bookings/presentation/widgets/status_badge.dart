import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        style: GoogleFonts.poppins(
          fontSize: isMobile ? 12 : 14,
          color: color,
        ),
      ),
    );
  }
}