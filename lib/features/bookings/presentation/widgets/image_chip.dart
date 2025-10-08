import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImageChip extends StatelessWidget {
  final String label;
  final String imageUrl;
  final double imageHeight;
  final double fontSize;
  final VoidCallback onTap;

  const ImageChip({
    required this.label,
    required this.imageUrl,
    required this.imageHeight,
    required this.fontSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: imageHeight * 0.85,
                height: imageHeight * 0.85,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1C9826),
                    strokeWidth: 2,
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image,
                  size: 28,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: fontSize - 3,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}