import 'package:n04_app/dummy_firebase.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../core/services/localization_service.dart';

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
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _photoUrl;
  File? _imageFile;
  DateTime? _dateOfBirth;
  String? _gender; // 'male', 'female', 'other'

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // First, get user role from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = userDoc.data()['role'] as String? ?? 'user';

      // Determine which collection to load from based on role
      DocumentSnapshot? profileDoc;

      if (role == 'user') {
        // Load from profiles collection (legacy)
        profileDoc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .get();
      }

      // If no profile doc found, try to load from users collection
      if (profileDoc == null || !profileDoc.exists) {
        profileDoc = userDoc;
      }

      if (profileDoc.exists) {
        final data = profileDoc.data() as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            // Load photo
            if (data.containsKey('photoBase64') &&
                data['photoBase64'] != null) {
              _photoUrl = data['photoBase64'] as String;
            } else if (data.containsKey('photoUrl') &&
                data['photoUrl'] != null) {
              _photoUrl = data['photoUrl'] as String;
            }

            // Load phone number (only in users collection)
            if (data.containsKey('phoneNumber') &&
                data['phoneNumber'] != null) {
              _phoneController.text = data['phoneNumber'] as String;
            }

            // Load gender (only in users collection)
            if (data.containsKey('gender') && data['gender'] != null) {
              _gender = data['gender'] as String;
            }

            // Load date of birth (only in users collection)
            if (data.containsKey('dateOfBirth') &&
                data['dateOfBirth'] != null) {
              _dateOfBirth = (data['dateOfBirth'] as DateTime).toDate();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Read image file as bytes
      final bytes = await _imageFile!.readAsBytes();

      // Convert to Base64
      final base64String = base64Encode(bytes);

      // Get user role to determine which collections to update
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final role = userDoc.data()['role'] as String? ?? 'user';

      final photoData = {
        'photoBase64': base64String,
        'updatedAt': FieldValue.serverDateTime(),
      };

      // Always update users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(photoData, SetOptions(merge: true));

      // Update role-specific collections
      if (role == 'user') {
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .set(photoData, SetOptions(merge: true));
      }

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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update display name in Firebase Auth
        if (_nameController.text != user.displayName) {
          await user.updateDisplayName(_nameController.text.trim());
        }

        // Prepare data to save
        final profileData = <String, dynamic>{
          'displayName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'updatedAt': FieldValue.serverDateTime(),
        };

        // Add optional fields only if they have values
        if (_phoneController.text.isNotEmpty) {
          profileData['phoneNumber'] = _phoneController.text.trim();
        }

        if (_gender != null) {
          profileData['gender'] = _gender;
        }

        if (_dateOfBirth != null) {
          profileData['dateOfBirth'] = (_dateOfBirth!);
        }

        // Get user role to determine which collections to update
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final role = userDoc.data()['role'] as String? ?? 'user';

        // Always update users collection (for admin system)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(profileData, SetOptions(merge: true));

        // Update role-specific collections
        if (role == 'user') {
          // Update profiles collection (legacy for regular users)
          await FirebaseFirestore.instance
              .collection('profiles')
              .doc(user.uid)
              .set(profileData, SetOptions(merge: true));
        }
        // Admin doesn't need extra collection, only 'users' is enough

        // Update email if changed
        if (_emailController.text != user.email) {
          await user.verifyBeforeUpdateEmail(_emailController.text.trim());

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Verification email sent. Please check your inbox.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }

        // Reload user to get updated data
        await user.reload();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Color(0xFF8BC34A),
            ),
          );
          Navigator.pop(context, true); // Return true to indicate update
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Error updating profile';
        if (e.code == 'requires-recent-login') {
          message = 'Please login again to change email';
        } else if (e.code == 'email-already-in-use') {
          message = 'This email is already in use';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email address';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
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
    final user = FirebaseAuth.instance.currentUser;

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

                // Avatar with Camera
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
                                            : user?.displayName
                                                      ?.substring(0, 1)
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

                // Full Name Field
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
                    setState(() {}); // Update avatar initial
                  },
                ),

                const SizedBox(height: 20),

                // Email Field
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

                // Phone Number Field
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

                // Date of Birth Field
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

                // Gender Field
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

                // User ID (Read-only)
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
                              user?.uid ?? 'N/A',
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

                // Save Button
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

                // Change Password Link
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
                final user = FirebaseAuth.instance.currentUser;
                if (user?.email != null) {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: user!.email!,
                  );
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
