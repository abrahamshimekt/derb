import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  File? _selectedImage;
  bool _isEditing = false;
  bool _isUpdating = false;
  late AnimationController _gearAnimationController;
  late Animation<double> _gearRotation;

  @override
  void initState() {
    super.initState();
    _gearAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _gearRotation = Tween<double>(begin: 0, end: 0.25).animate(
      CurvedAnimation(
        parent: _gearAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    return null;
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(v.trim())) return 'Enter a valid phone number';
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
    }
  }

  void _toggleEditMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        final user = ref.read(authRepositoryProvider).session?.user;
        _fullNameController.text = user?.userMetadata?['full_name'] ?? '';
        _phoneNumberController.text = user?.userMetadata?['phone_number'] ?? '';
        _selectedImage = null;
      } else {
        _fullNameController.clear();
        _phoneNumberController.clear();
        _selectedImage = null;
      }
    });
  }

  Future<void> _updateProfile(String userId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);
    final ctrl = ref.read(profileControllerProvider.notifier);
    await ctrl.updateProfile(
      userId: userId,
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
      avatarFile: _selectedImage,
    );
    setState(() => _isUpdating = false);
    _toggleEditMode();
  }

  void _changePassword() {
    HapticFeedback.lightImpact();
    final ctrl = ref.read(authControllerProvider.notifier);
    final session = ref.read(authRepositoryProvider).session;
    final userEmail = session?.user.email;
    
    if (userEmail != null) {
      ctrl.sendPasswordResetEmail(userEmail);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password reset email sent to $userEmail',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF1C9826),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to get user email',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _confirmDeleteAccount() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white.withOpacity(0.95),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF1C9826)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(profileControllerProvider.notifier).deleteAccount();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerProfile(double width) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!.withOpacity(0.5),
      highlightColor: Colors.grey[100]!.withOpacity(0.3),
      period: const Duration(milliseconds: 800),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: width * 0.15,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(width: width * 0.6, height: 20, color: Colors.white),
          const SizedBox(height: 8),
          Container(width: width * 0.8, height: 16, color: Colors.white),
          const SizedBox(height: 8),
          Container(width: width * 0.5, height: 16, color: Colors.white),
          const SizedBox(height: 8),
          Container(width: width * 0.4, height: 16, color: Colors.white),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _gearAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet =
        MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 900;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final profileStatus = ref.watch(profileControllerProvider);
    final session = ref.read(authRepositoryProvider).session;
    final user = session?.user;
    final isOwner = user?.userMetadata?['role'] == 'guest_house_owner';

    ref.listen(profileControllerProvider, (previous, next) {
      if (next is ProfileError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message, style: GoogleFonts.poppins()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      } else if (next is ProfileUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF1C9826),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });

    return Theme(
      data: ThemeData(
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
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
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
            backgroundColor: const Color(0xFF1C9826),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              vertical: isMobile ? 12 : 16,
              horizontal: isMobile ? 16 : 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
            ),
            elevation: 2,
            shadowColor: Colors.black26,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1C9826),
            textStyle: GoogleFonts.poppins(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          color: Colors.white.withOpacity(0.2),
        ),
        popupMenuTheme: PopupMenuThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          textStyle: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16),
          color: Colors.white.withOpacity(0.95),
        ),
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF1C9826).withOpacity(0.1), Colors.white],
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Profile',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 20 : 24,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [Color(0xFF1C9826), Color(0xFF4CAF50)],
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 20)),
                      ),
                    ),
                    centerTitle: true,
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTapDown: (_) => _gearAnimationController.forward(),
                        onTapUp: (_) => _gearAnimationController.reverse(),
                        child: PopupMenuButton<String>(
                          icon: AnimatedBuilder(
                            animation: _gearAnimationController,
                            builder: (context, child) => Transform.rotate(
                              angle: _gearRotation.value * 2 * 3.14159,
                              child: Icon(
                                Icons.settings,
                                size: isMobile ? 26 : 28,
                                color: const Color(0xFF1C9826),
                              ),
                            ),
                          ),
                          onSelected: (value) {
                            HapticFeedback.lightImpact();
                            if (value == 'edit') {
                              _toggleEditMode();
                            } else if (value == 'change_password') {
                              _changePassword();
                            } else if (value == 'delete_account') {
                              _confirmDeleteAccount();
                            } else if (value == 'sign_out') {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .signOut();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    color: const Color(0xFF1C9826),
                                    size: isMobile ? 18 : 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isEditing ? 'Cancel Edit' : 'Edit Profile',
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 14 : 16,
                                      color: const Color(0xFF1C9826),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'change_password',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    color: const Color(0xFF1C9826),
                                    size: isMobile ? 18 : 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Change Password',
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 14 : 16,
                                      color: const Color(0xFF1C9826),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'delete_account',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: isMobile ? 18 : 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Delete Account',
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 14 : 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'sign_out',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: Colors.redAccent,
                                    size: isMobile ? 18 : 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sign Out',
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 14 : 16,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final padding = isMobile
                          ? 16.0
                          : isTablet
                          ? 24.0
                          : 32.0;
                      return Padding(
                        padding: EdgeInsets.all(padding),
                        child: profileStatus is ProfileLoading
                            ? _buildShimmerProfile(width)
                            : AnimatedOpacity(
                                opacity: profileStatus is ProfileLoading
                                    ? 0.0
                                    : 1.0,
                                duration: const Duration(milliseconds: 400),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: AnimatedScale(
                                        scale: _isEditing ? 1.05 : 1.0,
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF1C9826),
                                                    Color(0xFF4CAF50),
                                                  ],
                                                ),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Colors.black26,
                                                    blurRadius: 10,
                                                    offset: Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              padding: const EdgeInsets.all(2),
                                              child: CircleAvatar(
                                                radius: isMobile
                                                    ? width * 0.15
                                                    : width * 0.1,
                                                backgroundImage:
                                                    _selectedImage != null
                                                    ? FileImage(_selectedImage!)
                                                    : user?.userMetadata?['avatar_url'] !=
                                                          null
                                                    ? NetworkImage(
                                                        user!.userMetadata!['avatar_url']
                                                            as String,
                                                      )
                                                    : null,
                                                backgroundColor:
                                                    Colors.grey[200],
                                                child:
                                                    user?.userMetadata?['avatar_url'] ==
                                                            null &&
                                                        _selectedImage == null
                                                    ? Icon(
                                                        Icons.person,
                                                        size: isMobile
                                                            ? 40
                                                            : 60,
                                                        color: Colors.grey[600],
                                                      )
                                                    : null,
                                              ),
                                            ),
                                            if (_isEditing)
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: GestureDetector(
                                                  onTap: _pickImage,
                                                  child: CircleAvatar(
                                                    radius: isMobile ? 16 : 20,
                                                    backgroundColor: Colors
                                                        .white
                                                        .withOpacity(0.9),
                                                    child: Icon(
                                                      Icons.camera_alt,
                                                      size: isMobile ? 16 : 20,
                                                      color: const Color(
                                                        0xFF1C9826,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeInOut,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 10,
                                            sigmaY: 10,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.3,
                                                ),
                                              ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(
                                                isMobile ? 16 : 24,
                                              ),
                                              child: _isEditing
                                                  ? Form(
                                                      key: _formKey,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          TextFormField(
                                                            controller:
                                                                _fullNameController,
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Full Name',
                                                              prefixIcon: const Icon(
                                                                Icons
                                                                    .person_outlined,
                                                                color: Color(
                                                                  0xFF1C9826,
                                                                ),
                                                              ),
                                                            ),
                                                            style:
                                                                GoogleFonts.poppins(
                                                                  fontSize:
                                                                      isMobile
                                                                      ? 14
                                                                      : 16,
                                                                ),
                                                            validator:
                                                                _requiredValidator,
                                                          ),
                                                          const SizedBox(
                                                            height: 16,
                                                          ),
                                                          TextFormField(
                                                            controller:
                                                                _phoneNumberController,
                                                            decoration: InputDecoration(
                                                              labelText:
                                                                  'Phone Number',
                                                              prefixIcon: const Icon(
                                                                Icons
                                                                    .phone_outlined,
                                                                color: Color(
                                                                  0xFF1C9826,
                                                                ),
                                                              ),
                                                            ),
                                                            keyboardType:
                                                                TextInputType
                                                                    .phone,
                                                            style:
                                                                GoogleFonts.poppins(
                                                                  fontSize:
                                                                      isMobile
                                                                      ? 14
                                                                      : 16,
                                                                ),
                                                            validator:
                                                                _phoneValidator,
                                                          ),
                                                          const SizedBox(
                                                            height: 24,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              TextButton(
                                                                onPressed:
                                                                    _isUpdating
                                                                    ? null
                                                                    : _toggleEditMode,
                                                                child: Text(
                                                                  'Cancel',
                                                                  style:
                                                                      GoogleFonts.poppins(),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              ElevatedButton(
                                                                onPressed:
                                                                    _isUpdating
                                                                    ? null
                                                                    : () => _updateProfile(
                                                                        user!
                                                                            .id,
                                                                      ),
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .transparent,
                                                                  shadowColor:
                                                                      Colors
                                                                          .transparent,
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          16,
                                                                        ),
                                                                  ),
                                                                ),
                                                                child: Ink(
                                                                  decoration: BoxDecoration(
                                                                    gradient: const LinearGradient(
                                                                      colors: [
                                                                        Color(
                                                                          0xFF1C9826,
                                                                        ),
                                                                        Color(
                                                                          0xFF4CAF50,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          16,
                                                                        ),
                                                                  ),
                                                                  child: Container(
                                                                    padding: EdgeInsets.symmetric(
                                                                      vertical:
                                                                          isMobile
                                                                          ? 12
                                                                          : 16,
                                                                      horizontal:
                                                                          isMobile
                                                                          ? 16
                                                                          : 24,
                                                                    ),
                                                                    child:
                                                                        _isUpdating
                                                                        ? const SizedBox(
                                                                            width:
                                                                                20,
                                                                            height:
                                                                                20,
                                                                            child: CircularProgressIndicator(
                                                                              strokeWidth: 2,
                                                                              color: Colors.white,
                                                                            ),
                                                                          )
                                                                        : Text(
                                                                            'Save',
                                                                            style: GoogleFonts.poppins(
                                                                              color: Colors.white,
                                                                            ),
                                                                          ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                  : Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        _buildProfileField(
                                                          'Email',
                                                          user?.email ?? 'N/A',
                                                          isMobile,
                                                        ),
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        _buildProfileField(
                                                          'Full Name',
                                                          user?.userMetadata?['full_name'] ??
                                                              'N/A',
                                                          isMobile,
                                                        ),
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        _buildProfileField(
                                                          'Phone Number',
                                                          user?.userMetadata?['phone_number'] ??
                                                              'N/A',
                                                          isMobile,
                                                        ),
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        _buildProfileField(
                                                          'Role',
                                                          user?.userMetadata?['role'] ??
                                                              'N/A',
                                                          isMobile,
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 14 : 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    IconData icon,
    bool isMobile,
  ) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1C9826), size: isMobile ? 20 : 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 14 : 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
