import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:derb/features/bookings/application/bookings_controller.dart';
import 'package:derb/features/rooms/data/models/room.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../auth/application/auth_controller.dart';

class NewBookingPage extends ConsumerStatefulWidget {
  final Room bedroom;

  const NewBookingPage({super.key, required this.bedroom});

  @override
  ConsumerState<NewBookingPage> createState() => _NewBookingPageState();
}

class _NewBookingPageState extends ConsumerState<NewBookingPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  XFile? _idImage;
  XFile? _receiptImage;
  final String _status = 'pending';
  final _transactionIdController = TextEditingController();

  @override
  void dispose() {
    _transactionIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (type == 'id') {
            _idImage = image;
          } else {
            _receiptImage = image;
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to pick image: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now().add(const Duration(days: 1)));
    final firstDate = DateTime.now();
    final lastDate = firstDate.add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1C9826),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String? _validateForm() {
    if (_startDate == null) return 'Please select a start date.';
    if (_endDate == null) return 'Please select an end date.';
    if (_endDate!.isBefore(_startDate!))
      return 'End date must be after start date.';
    if (_idImage == null) return 'Please upload an identification card.';
    if (_receiptImage == null) return 'Please upload a payment receipt.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final padding = isMobile
        ? 16.0
        : isTablet
        ? 24.0
        : 32.0;
    final fontSize = isMobile
        ? 16.0
        : isTablet
        ? 18.0
        : 20.0;
    final authStatus = ref.watch(authControllerProvider);
    final isAuthenticated = authStatus is AuthAuthenticated;
    final tenantId = isAuthenticated ? authStatus.session.user.id : '';

    return Theme(
      data: _buildTheme(isMobile),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Book Room ${widget.bedroom.roomNumber}',
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [Color(0xFF1C9826), Color(0xFF4CAF50)],
                ).createShader(const Rect.fromLTWH(0, 0, 200, 20)),
            ),
          ),
          backgroundColor: Colors.white.withOpacity(0.9),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
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
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: GradientCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRoomPreview(isMobile, isTablet),
                    const SizedBox(height: 16),
                    Text(
                      'New Booking',
                      style: GoogleFonts.poppins(
                        fontSize: fontSize + 2,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDatePicker(
                            context,
                            title: 'Start Date',
                            value: _startDate,
                            onTap: () => _selectDate(context, true),
                            fontSize: fontSize,
                            isMobile: isMobile,
                          ),
                          const SizedBox(height: 16),
                          _buildDatePicker(
                            context,
                            title: 'End Date',
                            value: _endDate,
                            onTap: () => _selectDate(context, false),
                            fontSize: fontSize,
                            isMobile: isMobile,
                          ),
                          const SizedBox(height: 16),
                          _buildTransactionIdField(fontSize, isMobile),
                          const SizedBox(height: 16),
                          _buildImagePicker(
                            context,
                            title: 'Identification Card',
                            file: _idImage,
                            onTap: () => _pickImage('id'),
                            fontSize: fontSize,
                            isMobile: isMobile,
                          ),
                          const SizedBox(height: 16),
                          _buildImagePicker(
                            context,
                            title: 'Payment Receipt',
                            file: _receiptImage,
                            onTap: () => _pickImage('receipt'),
                            fontSize: fontSize,
                            isMobile: isMobile,
                          ),
                          const SizedBox(height: 16),
                          _buildStatusField(fontSize),
                          const SizedBox(height: 24),
                          _buildTotalPrice(fontSize),
                          const SizedBox(height: 24),
                          _buildSubmitButton(
                            isMobile,
                            isAuthenticated,
                            tenantId,
                          ),
                          _buildErrorMessage(fontSize),
                        ],
                      ),
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
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
      ),
    );
  }

  Widget _buildRoomPreview(bool isMobile, bool isTablet) {
    final imgUrl = widget.bedroom.roomPictures![0];
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: isMobile
            ? 400
            : isTablet
            ? 420
            : 440,
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey[200]),
        child: imgUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imgUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1C9826)),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.meeting_room_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
              )
            : const Icon(
                Icons.meeting_room_outlined,
                size: 48,
                color: Colors.grey,
              ),
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context, {
    required String title,
    required DateTime? value,
    required VoidCallback onTap,
    required double fontSize,
    required bool isMobile,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: fontSize, color: Colors.grey[600]),
      ),
      subtitle: Text(
        value == null
            ? 'Select $title.toLowerCase()'
            : DateFormat('MMM dd, yyyy').format(value),
        style: GoogleFonts.poppins(fontSize: fontSize - 2),
      ),
      trailing: const Icon(Icons.calendar_today, color: Color(0xFF1C9826)),
      onTap: onTap,
    );
  }

  Widget _buildTransactionIdField(double fontSize, bool isMobile) {
    return TextFormField(
      controller: _transactionIdController,
      decoration: InputDecoration(
        labelText: 'Transaction ID (Optional)',
        labelStyle: GoogleFonts.poppins(
          fontSize: fontSize - 2,
          color: Colors.grey[600],
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      style: GoogleFonts.poppins(fontSize: fontSize - 2),
    );
  }

  Widget _buildImagePicker(
    BuildContext context, {
    required String title,
    required XFile? file,
    required VoidCallback onTap,
    required double fontSize,
    required bool isMobile,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: fontSize, color: Colors.grey[600]),
      ),
      subtitle: Text(
        file == null ? 'No file selected' : file.name,
        style: GoogleFonts.poppins(fontSize: fontSize - 2),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.upload_file, color: Color(0xFF1C9826)),
      onTap: onTap,
    );
  }

  Widget _buildStatusField(double fontSize) {
    return Text(
      'Status: $_status',
      style: GoogleFonts.poppins(fontSize: fontSize, color: Colors.grey[600]),
    );
  }

  Widget _buildTotalPrice(double fontSize) {
    if (_startDate == null || _endDate == null) return const SizedBox.shrink();
    final days = _endDate!.difference(_startDate!).inDays;
    final totalPrice = widget.bedroom.price * (days <= 0 ? 1 : days);
    return Text(
      'Total Price: ${totalPrice.toStringAsFixed(2)} ETB',
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSubmitButton(
    bool isMobile,
    bool isAuthenticated,
    String tenantId,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final bookingState = ref.watch(bookingsControllerProvider);
        return GradientButton(
          onPressed: bookingState is BookingsLoading
              ? null
              : () async {
                  final validationError = _validateForm();
                  if (validationError != null || !isAuthenticated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          validationError ?? 'Please sign in to book.',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                    return;
                  }
                  final days = _endDate!.difference(_startDate!).inDays;
                  final totalPrice =
                      widget.bedroom.price * (days <= 0 ? 1 : days);
                  try {
                    await ref
                        .read(bookingsControllerProvider.notifier)
                        .createBooking(
                          bedroomId: widget.bedroom.id,
                          tenantId: tenantId,
                          startDate: _startDate!,
                          endDate: _endDate!,
                          totalPrice: totalPrice,
                          transactionId: _transactionIdController.text.isEmpty
                              ? null
                              : _transactionIdController.text,
                          idImage: _idImage!,
                          receiptImage: _receiptImage!,
                        );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Booking created successfully!',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF1C9826),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to create booking: $e',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  }
                },
          text: bookingState is BookingsLoading
              ? 'Submitting...'
              : 'Submit Booking',
          isMobile: isMobile,
        );
      },
    );
  }

  Widget _buildErrorMessage(double fontSize) {
    return Consumer(
      builder: (context, ref, child) {
        final bookingState = ref.watch(bookingsControllerProvider);
        if (bookingState is BookingsError) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              bookingState.message,
              style: GoogleFonts.poppins(
                fontSize: fontSize - 2,
                color: Colors.redAccent,
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;

  const GradientCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Card(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1C9826).withOpacity(0.05),
                  Colors.white.withOpacity(0.9),
                ],
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
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
    return AnimatedScale(
      scale: onPressed == null ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1C9826), Color(0xFF4CAF50)],
            ),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 12 : 16,
            ),
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
      ),
    );
  }
}
