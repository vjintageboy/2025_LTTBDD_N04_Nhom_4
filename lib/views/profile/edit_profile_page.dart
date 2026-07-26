import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/localization_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/image_source.dart';
import '../../services/supabase_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final SupabaseService _supabaseService = SupabaseService();
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _photoUrl;
  File? _imageFile;
  DateTime? _dateOfBirth;
  String? _gender;

  static const Color _kBg = Color(0xFFDBFCDF);

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _nameController.text = user.userMetadata?['full_name'] ?? '';
      _emailController.text = user.email ?? '';
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final profileData = await _supabaseService.getUserProfile(user.id);
      if (profileData != null && mounted) {
        setState(() {
          _photoUrl = profileData['avatar_url'] as String?;
          _gender = profileData['gender'] as String?;
          final dob = profileData['date_of_birth'];
          if (dob != null) _dateOfBirth = DateTime.tryParse(dob.toString());
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (image != null) {
        setState(() => _imageFile = File(image.path));
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppColors.osError,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;
    setState(() => _isUploadingPhoto = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final bytes = await _imageFile!.readAsBytes();
      final base64String = base64Encode(bytes);
      await _supabaseService.updateUser(user.id, {'avatar_url': base64String});
      setState(() => _photoUrl = base64String);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: AppColors.osPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: AppColors.osError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final profileData = <String, dynamic>{
        'full_name': _nameController.text.trim(),
      };
      if (_gender != null) profileData['gender'] = _gender;
      if (_dateOfBirth != null) {
        profileData['date_of_birth'] = _dateOfBirth!.toIso8601String();
      }
      await _supabaseService.updateUser(user.id, profileData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.osPrimary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.error}: $e'),
            backgroundColor: AppColors.osError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(IconsaxPlusLinear.arrow_left),
          color: AppColors.osOnSurface,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.editProfile,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.osOnSurface,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildAvatar(user),
                const SizedBox(height: 32),
                _buildField(
                  controller: _nameController,
                  label: context.l10n.fullName,
                  hint: 'Enter your full name',
                  icon: IconsaxPlusLinear.user,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your name';
                    if (v.trim().length < 2) return 'Name is too short';
                    return null;
                  },
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _emailController,
                  label: context.l10n.email,
                  hint: 'Enter your email',
                  icon: IconsaxPlusLinear.sms,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                      return 'Invalid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildDatePicker(),
                const SizedBox(height: 16),
                _buildGenderDropdown(),
                const SizedBox(height: 16),
                _buildUserIdCard(user),
                const SizedBox(height: 28),
                _buildSaveButton(),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _showChangePasswordDialog,
                  child: Text(
                    'Change Password',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.osPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(User? user) {
    // avatar_url holds base64 or a legacy URL, so it cannot be decoded blindly.
    final avatar = _imageFile != null
        ? FileImage(_imageFile!) as ImageProvider
        : imageProviderFromSource(_photoUrl);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.osPrimary.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _isUploadingPhoto
              ? CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.osPrimaryContainer,
                  child: const CircularProgressIndicator(
                    color: AppColors.osPrimary,
                    strokeWidth: 2,
                  ),
                )
              : CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.osPrimaryContainer,
                  backgroundImage: avatar,
                  child: avatar == null
                      ? Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : user?.userMetadata?['full_name']
                                      ?.toString()
                                      .substring(0, 1)
                                      .toUpperCase() ??
                                  'U',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: AppColors.osOnPrimaryContainer,
                          ),
                        )
                      : null,
                ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _isUploadingPhoto ? null : _pickImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.osPrimary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.osSurfaceContainerLowest,
                  width: 3,
                ),
              ),
              child: const Icon(
                IconsaxPlusLinear.camera,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged != null ? (_) => onChanged() : null,
      style: GoogleFonts.manrope(
        color: AppColors.osOnSurface,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.osOnSurfaceVariant, size: 20),
        labelStyle: GoogleFonts.manrope(color: AppColors.osOnSurfaceVariant),
        hintStyle: GoogleFonts.manrope(color: AppColors.osOnSurfaceVariant),
        filled: true,
        fillColor: AppColors.osSurfaceContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.osPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.osError),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _dateOfBirth ?? DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.osPrimary,
                    onPrimary: Colors.white,
                    onSurface: AppColors.osOnSurface,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) setState(() => _dateOfBirth = picked);
        },
        borderRadius: BorderRadius.circular(14),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: const Icon(
              PhosphorIconsRegular.cake,
              color: AppColors.osOnSurfaceVariant,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.osSurfaceContainer,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          child: Text(
            _dateOfBirth != null
                ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                : 'Not set',
            style: GoogleFonts.manrope(
              color: _dateOfBirth != null
                  ? AppColors.osOnSurface
                  : AppColors.osOnSurfaceVariant,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _gender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(
          IconsaxPlusLinear.user,
          color: AppColors.osOnSurfaceVariant,
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.osSurfaceContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.osPrimary, width: 2),
        ),
      ),
      style: GoogleFonts.manrope(color: AppColors.osOnSurface),
      items: const [
        DropdownMenuItem(value: 'male', child: Text('Male')),
        DropdownMenuItem(value: 'female', child: Text('Female')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ],
      onChanged: (value) => setState(() => _gender = value),
    );
  }

  Widget _buildUserIdCard(User? user) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.osSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.osOnSurface.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            PhosphorIconsRegular.fingerprint,
            color: AppColors.osOnSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User ID',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppColors.osOnSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.id ?? 'N/A',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColors.osOnSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.osPrimary,
          disabledBackgroundColor: AppColors.osSurfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                context.l10n.saveChanges,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: AppColors.osSurfaceContainerLowest,
        title: Text(
          'Change Password',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          'We will send a password reset link to your email address.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: AppColors.osOnSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.cancel,
              style: GoogleFonts.manrope(
                color: AppColors.osOnSurfaceVariant,
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final user = Supabase.instance.client.auth.currentUser;
                if (user?.email != null) {
                  await Supabase.instance.client.auth
                      .resetPasswordForEmail(user!.email!);
                  if (parentContext.mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent!'),
                        backgroundColor: AppColors.osPrimary,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.osError,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.osPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }
}
