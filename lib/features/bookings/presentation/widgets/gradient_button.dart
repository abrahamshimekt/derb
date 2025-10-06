import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          gradient: LinearGradient(colors: [Color(0xFF1C9826), Color(0xFF4CAF50)]),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 12 : 16,
          ),
          alignment: Alignment.center,
          child: Text(
            text,
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
}