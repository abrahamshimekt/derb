import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../application/rooms_controller.dart';
import 'dart:io';

class AddRoomDialog extends ConsumerStatefulWidget {
  final String guestHouseId;
  final VoidCallback onClose;

  const AddRoomDialog({
    super.key,
    required this.guestHouseId,
    required this.onClose,
  });

  @override
  ConsumerState<AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends ConsumerState<AddRoomDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberController = TextEditingController();
  final _priceController = TextEditingController();
  final _facilitiesController = TextEditingController();
  String _status = 'available';
  List<XFile> _selectedImages = [];
  final _picker = ImagePicker();
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _priceController.dispose();
    _facilitiesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (mounted) {
      setState(() {
        _selectedImages = pickedFiles.take(3).toList();
        _animationController.forward(from: 0);
      });
    }
  }

  void _removeImage(int index) {
    if (mounted) {
      setState(() {
        _selectedImages.removeAt(index);
        _animationController.forward(from: 0);
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final price = double.parse(_priceController.text);
      final roomNumber = _roomNumberController.text;
      final facilities = _facilitiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      List<String>? imageUrls;
      if (_selectedImages.isNotEmpty) {
        imageUrls = await ref
            .read(roomsControllerProvider.notifier)
            .uploadImages(
              guestHouseId: widget.guestHouseId,
              images: _selectedImages,
            );
      }

      await ref
          .read(roomsControllerProvider.notifier)
          .createRoom(
            guestHouseId: widget.guestHouseId,
            roomNumber: roomNumber,
            price: price,
            status: _status,
            facilities: facilities,
            roomPictures: imageUrls,
          );

      if (mounted) {
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 900;
        final dialogWidth = isMobile
            ? constraints.maxWidth * 0.9
            : isTablet
            ? 500.0
            : 600.0;
        final fontSizeTitle = isMobile
            ? 18.0
            : isTablet
            ? 20.0
            : 22.0;
        final fontSizeLabel = isMobile
            ? 14.0
            : isTablet
            ? 15.0
            : 16.0;
        final padding = isMobile
            ? 16.0
            : isTablet
            ? 20.0
            : 24.0;
        final imageSize = isMobile
            ? 80.0
            : isTablet
            ? 100.0
            : 120.0;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.9),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Add Room',
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeTitle,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _roomNumberController,
                        decoration: InputDecoration(
                          labelText: 'Room Number',
                          hintText: 'Enter room number',
                          labelStyle: GoogleFonts.poppins(
                            fontSize: fontSizeLabel,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1C9826),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a room number';
                          }
                          return null;
                        },
                      )
                      ,
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price',
                          hintText: 'Enter room price (e.g., 50.00)',
                          labelStyle: GoogleFonts.poppins(
                            fontSize: fontSizeLabel,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1C9826),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a price';
                          }
                          if (double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return 'Please enter a valid price';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: GoogleFonts.poppins(
                            fontSize: fontSizeLabel,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1C9826),
                              width: 2,
                            ),
                          ),
                        ),
                        items: ['available', 'booked', 'maintenance']
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status.capitalize(),
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (mounted && value != null) {
                            setState(() {
                              _status = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _facilitiesController,
                        decoration: InputDecoration(
                          labelText: 'Facilities',
                          hintText:
                              'Enter facilities (comma-separated, e.g., WiFi, TV)',
                          labelStyle: GoogleFonts.poppins(
                            fontSize: fontSizeLabel,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1C9826),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Upload Images (Max 3)',
                          style: GoogleFonts.poppins(
                            fontSize: fontSizeLabel,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedImages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final image = entry.value;
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: Stack(
                              children: [
                                Container(
                                  width: imageSize,
                                  height: imageSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(image.path),
                                      fit: BoxFit.cover,
                                      frameBuilder:
                                          (
                                            context,
                                            child,
                                            frame,
                                            wasSynchronouslyLoaded,
                                          ) {
                                            if (frame == null) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            }
                                            return child;
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.error_outline,
                                                color: Colors.redAccent,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.red,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedImages.length < 3)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _pickImages,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 20 : 24,
                                  vertical: isMobile ? 12 : 14,
                                ),
                                child: Text(
                                  'Pick Images',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: fontSizeLabel,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSubmitting ? null : widget.onClose,
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: fontSizeLabel,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 20 : 24,
                                  vertical: isMobile ? 12 : 14,
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Add Room',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: fontSizeLabel,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
