import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/localization_service.dart';
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
  final _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final SupabaseService _supabaseService = SupabaseService();
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _photoUrl;
  File? _imageFile;
  DateTime? _dateOfBirth;
  String? _gender;

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
          _photoUrl = profileData['photo_url'] as String?;
          _phoneController.text = profileData['phone_number'] ?? '';
          _gender = profileData['gender'] as String?;
          final dob = profileData['date_of_birth'];
          if (dob != null) {
            _dateOfBirth = DateTime.tryParse(dob.toString());
          }
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
        setState(() {
          _imageFile = File(image.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
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

      await _supabaseService.updateUser(user.id, {
        'photo_url': base64String,
      });

      setState(() {
        _photoUrl = base64String;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: Color(0xFF8BC34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

      if (_phoneController.text.isNotEmpty) {
        profileData['phone_number'] = _phoneController.text.trim();
      }

      if (_gender != null) {
        profileData['gender'] = _gender;
      }

      if (_dateOfBirth != null) {
        profileData['date_of_birth'] = _dateOfBirth!.toIso8601String();
      }

      await _supabaseService.updateUser(user.id, profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF8BC34A),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.editProfile,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8BC34A).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: _isUploadingPhoto
                          ? CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 56,
                                backgroundColor: const Color(
                                  0xFF8BC34A,
                                ).withValues(alpha: 0.1),
                                child: const CircularProgressIndicator(
                                  color: Color(0xFF689F38),
                                ),
                              ),
                            )
                          : CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 56,
                                backgroundColor: const Color(
                                  0xFF8BC34A,
                                ).withValues(alpha: 0.1),
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : (_photoUrl != null &&
                                              _photoUrl!.isNotEmpty
                                          ? MemoryImage(
                                                  base64Decode(_photoUrl!),
                                                )
                                                as ImageProvider
                                          : null),
                                child:
                                    (_imageFile == null &&
                                        (_photoUrl == null ||
                                            _photoUrl!.isEmpty))
                                    ? Text(
                                        _nameController.text.isNotEmpty
                                            ? _nameController.text[0]
                                                  .toUpperCase()
                                            : user?.userMetadata?['full_name']
                                                      ?.toString()
                                                      .substring(0, 1)
                                                      .toUpperCase() ??
                                                  'U',
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF689F38),
                                        ),
                                      )
                                    : null,
                              ),
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
                            color: const Color(0xFF8BC34A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: context.l10n.fullName,
                    hintText: 'Enter your full name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF8BC34A),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name is too short';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: context.l10n.email,
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF8BC34A),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Invalid email address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter your phone number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF8BC34A),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!RegExp(r'^\+?[\d\s-()]+$').hasMatch(value)) {
                        return 'Invalid phone number';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                InkWell(
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
                              primary: Color(0xFF8BC34A),
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => _dateOfBirth = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      hintText: 'Select your date of birth',
                      prefixIcon: const Icon(Icons.cake_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF8BC34A),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    child: Text(
                      _dateOfBirth != null
                          ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                          : 'Not set',
                      style: TextStyle(
                        color: _dateOfBirth != null
                            ? Colors.black87
                            : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    hintText: 'Select your gender',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF8BC34A),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    setState(() => _gender = value);
                  },
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fingerprint, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User ID',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.id ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
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
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8BC34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey[300],
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    _showChangePasswordDialog();
                  },
                  child: const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8BC34A),
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

  void _showChangePasswordDialog() {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: const Text(
          'We will send a password reset link to your email address.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.l10n.cancel,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
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
                        backgroundColor: Color(0xFF8BC34A),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (parentContext.mounted) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8BC34A),
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
