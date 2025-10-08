import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:derb/features/bookings/data/models/booking.dart';
import 'package:derb/features/bookings/presentation/widgets/gradient_card.dart';
import 'package:derb/features/bookings/presentation/widgets/image_chip.dart';
import 'package:derb/features/bookings/presentation/widgets/info_row.dart';
import 'package:derb/features/bookings/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BooksCard extends StatelessWidget {
  final bool isOwner;
  final Booking booking;
  final bool isMobile;
  final bool isTablet;
  final VoidCallback? onApprove;  // New callback for approve action
  final VoidCallback? onCheckIn;  // New callback for check-in action
  final VoidCallback? onCheckOut; // New callback for check-out action
  final VoidCallback? onCancel;   // New callback for cancel action

  const BooksCard({
    super.key,
    required this.isOwner,
    required this.booking,
    required this.isMobile,
    required this.isTablet,
    this.onApprove,
    this.onCheckIn,
    this.onCheckOut,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = isMobile
        ? 16.0
        : isTablet
        ? 20.0
        : 24.0;
    final fontSize = isMobile
        ? 15.0
        : isTablet
        ? 17.0
        : 19.0;
    final imageHeight = isMobile
        ? 160.0
        : isTablet
        ? 200.0
        : 240.0;

    final String roomNumber = booking.roomNumber ?? 'Unknown';
    final String guestHouseName = booking.guestHouseName ?? 'Unknown';
    final String city = booking.city ?? 'Unknown';
    final String subCity = booking.subCity ?? 'Unknown';
    final statusColor = _getStatusColor(booking.status);
    String formatDate(DateTime? dt) =>
        dt == null ? '-' : DateFormat('MMM dd, yyyy').format(dt);

    return GestureDetector(
      onTap: () => HapticFeedback.lightImpact(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: GradientCard(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Images Gallery
              if (booking.roomPictures != null &&
                  booking.roomPictures!.isNotEmpty)
                SizedBox(
                  height: imageHeight,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: booking.roomPictures!.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GestureDetector(
                          onTap: () => _showImageDialog(
                            context,
                            booking.roomPictures![index],
                          ),
                          child: Container(
                            width: imageHeight * 1.6,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CachedNetworkImage(
                              imageUrl: booking.roomPictures![index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1C9826),
                                  strokeWidth: 3,
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.broken_image,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: imageHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.meeting_room_outlined,
                      size: 56,
                      color: Colors.grey,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Info Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow(
                      icon: Icons.hotel,
                      label: 'Guest House',
                      value: guestHouseName,
                      fontSize: fontSize,
                    ),
                    const SizedBox(height: 8),
                    InfoRow(
                      icon: Icons.location_city,
                      label: 'City',
                      value: city,
                      fontSize: fontSize,
                    ),
                    const SizedBox(height: 8),
                    InfoRow(
                      icon: Icons.map,
                      label: 'Sub-City',
                      value: subCity,
                      fontSize: fontSize,
                    ),
                    const SizedBox(height: 8),
                    InfoRow(
                      icon: Icons.door_front_door,
                      label: 'Room Number',
                      value: roomNumber,
                      fontSize: fontSize,
                    ),
                    const SizedBox(height: 8),
                    InfoRow(
                      icon: Icons.calendar_today,
                      label: 'From',
                      value: formatDate(booking.startDate),
                      fontSize: fontSize,
                    ),
                    const SizedBox(height: 8),
                    InfoRow(
                      icon: Icons.calendar_month,
                      label: 'To',
                      value: formatDate(booking.endDate),
                      fontSize: fontSize,
                    ),
                    const SizedBox(height: 8),
                    InfoRow(
                      icon: Icons.attach_money,
                      label: 'Price',
                      value: '${booking.totalPrice.toStringAsFixed(2)} ETB',
                      fontSize: fontSize,
                      textColor: const Color(0xFF1C9826),
                    ),
                    const SizedBox(height: 8),
                    InfoRow(
                      icon: Icons.receipt_long,
                      label: 'Transaction ID',
                      value: ((booking.transactionId?.length ?? 0) > 24)
                          ? '${booking.transactionId!.substring(0, 24)}…'
                          : (booking.transactionId ?? '-'),
                      fontSize: fontSize,
                      onCopy:
                          booking.transactionId != null &&
                              booking.transactionId!.isNotEmpty
                          ? () => _copy(
                              context,
                              'Transaction ID',
                              booking.transactionId,
                            )
                          : null,
                    ),
                    // Add payment status
                    if (booking.hasPaid)
                      const SizedBox(height: 8),
                    if (booking.hasPaid)
                      InfoRow(
                        icon: Icons.check_circle,
                        label: 'Payment Status',
                        value: 'Paid',
                        fontSize: fontSize,
                        textColor: const Color(0xFF1C9826),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ID and Receipt Chips
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (booking.idUrl != null && booking.idUrl!.isNotEmpty)
                    ImageChip(
                      label: 'ID Image',
                      imageUrl: booking.idUrl!,
                      imageHeight: isMobile ? 70.0 : 90.0,
                      fontSize: fontSize,
                      onTap: () => _showImageDialog(context, booking.idUrl!),
                    ),
                  if (booking.paymentReceiptUrl != null &&
                      booking.paymentReceiptUrl!.isNotEmpty)
                    ImageChip(
                      label: 'Receipt',
                      imageUrl: booking.paymentReceiptUrl!,
                      imageHeight: isMobile ? 70.0 : 90.0,
                      fontSize: fontSize,
                      onTap: () =>
                          _showImageDialog(context, booking.paymentReceiptUrl!),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Status + Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  StatusBadge(
                    status: booking.status,
                    color: statusColor,
                    isMobile: isMobile,
                  ),
                  Row(
                    children: [
                      if (booking.status.toLowerCase() == 'pending' && isOwner)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton(
                            onPressed: onApprove,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1C9826)
                                  .withOpacity(0.1),
                              foregroundColor: const Color(0xFF1C9826),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Approve',
                              style: GoogleFonts.poppins(
                                fontSize: fontSize - 2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (booking.status.toLowerCase() == 'approved' && isOwner)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ElevatedButton(
                            onPressed: onCheckIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1C9826)
                                  .withOpacity(0.1),
                              foregroundColor: const Color(0xFF1C9826),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Check In',
                              style: GoogleFonts.poppins(
                                fontSize: fontSize - 2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (booking.status.toLowerCase() == 'checked_in' && isOwner)
                        ElevatedButton(
                          onPressed: onCheckOut,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C9826)
                                .withOpacity(0.1),
                            foregroundColor: const Color(0xFF1C9826),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Check Out',
                            style: GoogleFonts.poppins(
                              fontSize: fontSize - 2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (booking.status.toLowerCase() != 'checked_in' &&
                          booking.status.toLowerCase() != 'checked_out' &&
                          booking.status.toLowerCase() != 'cancelled')
                        ElevatedButton(
                          onPressed: onCancel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: fontSize - 2,
                              fontWeight: FontWeight.w600,
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
    );
  }

  Future<void> _copy(BuildContext context, String label, String? value) async {
    if (value == null || value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label copied',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: const Color(0xFF1C9826),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1C9826),
                    strokeWidth: 3,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[100],
                  child: const Icon(
                    Icons.broken_image,
                    size: 56,
                    color: Colors.grey,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                    shadows: [BoxShadow(color: Colors.black54, blurRadius: 8)],
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'checked_in':
      case 'approved':
        return const Color(0xFF1C9826);
      case 'pending':
        return Colors.amber[700]!;
      case 'cancelled':
      case 'checked_out':
        return Colors.redAccent[400]!;
      default:
        return Colors.grey[600]!;
    }
  }
}