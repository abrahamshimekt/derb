import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double fontSize;
  final Color? textColor;
  final VoidCallback? onCopy;

  const InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.fontSize,
    this.textColor,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: fontSize, color: const Color(0xFF1C9826)),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: GoogleFonts.poppins(
            fontSize: fontSize - 3,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: fontSize - 3,
              color: textColor ?? Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onCopy != null) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: onCopy,
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(Icons.copy, size: 16, color: Color(0xFF1C9826)),
            ),
          ),
        ],
      ],
    );
  }
}
