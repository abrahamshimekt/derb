import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import '../../application/guest_houses_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateGuestHouseDialog extends ConsumerStatefulWidget {
  final String ownerId;
  final VoidCallback onClose;

  const CreateGuestHouseDialog({
    super.key,
    required this.ownerId,
    required this.onClose,
  });

  @override
  ConsumerState<CreateGuestHouseDialog> createState() =>
      _CreateGuestHouseDialogState();
}

class _CreateGuestHouseDialogState extends ConsumerState<CreateGuestHouseDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _relativeLocationDescription = TextEditingController();
  final _numberOfRooms = TextEditingController();
  final _city = TextEditingController();
  final _region = TextEditingController();
  final _subCity = TextEditingController();
  final _guestHouseName = TextEditingController();
  final _description = TextEditingController();
  File? _selectedImage;
  bool _isCreating = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    return null;
  }

  String? _numberValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    final number = double.tryParse(v.trim());
    if (number == null) return 'Enter a valid number';
    return null;
  }

  String? _integerValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    final number = int.tryParse(v.trim());
    if (number == null || number <= 0) return 'Enter a valid positive integer';
    return null;
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      _animationController.forward(from: 0);
    }
  }

  Future<void> _createGuestHouse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);
    final ctrl = ref.read(guestHousesControllerProvider.notifier);
    await ctrl.createGuestHouse(
      ownerId: widget.ownerId,
      latitude: double.parse(_latitude.text.trim()),
      longitude: double.parse(_longitude.text.trim()),
      relativeLocationDescription: _relativeLocationDescription.text.trim(),
      numberOfRooms: int.parse(_numberOfRooms.text.trim()),
      city: _city.text.trim(),
      region: _region.text.trim(),
      subCity: _subCity.text.trim(),
      imageFile: _selectedImage,
      guestHouseName: _guestHouseName.text.trim(),
      description: _description.text.trim(),
    );

    setState(() => _isCreating = false);
    _latitude.clear();
    _longitude.clear();
    _relativeLocationDescription.clear();
    _numberOfRooms.clear();
    _city.clear();
    _region.clear();
    _subCity.clear();
    _guestHouseName.clear();
    _description.clear();
    setState(() => _selectedImage = null);
    widget.onClose();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _relativeLocationDescription.dispose();
    _numberOfRooms.dispose();
    _city.dispose();
    _region.dispose();
    _subCity.dispose();
    _guestHouseName.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 900;
    final isDesktop = size.width >= 900;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white.withOpacity(0.98),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop
              ? 600
              : isTablet
              ? 500
              : size.width * 0.9,
          maxHeight: size.height * 0.85,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  'Add Guest House',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile
                        ? 18
                        : isTablet
                        ? 20
                        : 22,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFF1C9826), Color(0xFF4CAF50)],
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 20)),
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 28,
                    color: Colors.black87,
                  ),
                  onPressed: widget.onClose,
                ),
              ),
              body: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(
                    isMobile
                        ? 16
                        : isTablet
                        ? 24
                        : 32,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _guestHouseName,
                          label: 'Guest House Name',
                          icon: Icons.home_outlined,
                          isMobile: isMobile,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _description,
                          label: 'Description',
                          icon: Icons.description_outlined,
                          isMobile: isMobile,
                          maxLines: 3,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _latitude,
                                label: 'Latitude',
                                icon: Icons.location_on_outlined,
                                isMobile: isMobile,
                                keyboardType: TextInputType.number,
                                validator: _numberValidator,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _longitude,
                                label: 'Longitude',
                                icon: Icons.location_on_outlined,
                                isMobile: isMobile,
                                keyboardType: TextInputType.number,
                                validator: _numberValidator,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _relativeLocationDescription,
                          label: 'Location Description',
                          icon: Icons.description_outlined,
                          isMobile: isMobile,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _numberOfRooms,
                          label: 'Number of Rooms',
                          icon: Icons.meeting_room_outlined,
                          isMobile: isMobile,
                          keyboardType: TextInputType.number,
                          validator: _integerValidator,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _city,
                                label: 'City',
                                icon: Icons.location_city_outlined,
                                isMobile: isMobile,
                                validator: _requiredValidator,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _region,
                                label: 'Region',
                                icon: Icons.map_outlined,
                                isMobile: isMobile,
                                validator: _requiredValidator,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _subCity,
                          label: 'Sub City',
                          icon: Icons.map_outlined,
                          isMobile: isMobile,
                          validator: _requiredValidator,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _pickImage,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: isMobile
                                ? 120
                                : isTablet
                                ? 150
                                : 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              gradient: _selectedImage == null
                                  ? null
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF1C9826),
                                        Color(0xFF4CAF50),
                                      ],
                                    ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _selectedImage == null
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_outlined,
                                            color: const Color(0xFF1C9826),
                                            size: isMobile ? 36 : 42,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Tap to select an image',
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey[600],
                                              fontSize: isMobile ? 12 : 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isCreating ? null : widget.onClose,
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[700],
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isCreating ? null : _createGuestHouse,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
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
                                    horizontal: isMobile ? 20 : 28,
                                    vertical: isMobile ? 12 : 14,
                                  ),
                                  child: _isCreating
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          'Add',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: isMobile ? 14 : 16,
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isMobile,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: isMobile ? 14 : 16,
          color: Colors.grey[700],
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF1C9826),
          size: isMobile ? 20 : 24,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1C9826), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        contentPadding: EdgeInsets.symmetric(
          vertical: isMobile ? 12 : 16,
          horizontal: 16,
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.poppins(
        fontSize: isMobile ? 14 : 16,
        color: Colors.black87,
      ),
      validator: validator,
      onTap: () => HapticFeedback.selectionClick(),
    );
  }
}
