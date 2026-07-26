import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/news_post.dart';
import '../../services/news_service.dart';
import '../../services/supabase_service.dart';
import '../../core/services/localization_service.dart';

// Organic Sanctuary color palette
const _kSurface = Color(0xFFDDFFE2);
const _kPrimary = Color(0xFF006B1B);
const _kPrimaryDim = Color(0xFF005D16);
const _kPrimaryContainer = Color(0xFF76FB7A);
const _kOnPrimary = Color(0xFFD1FFC8);
const _kOnSurface = Color(0xFF0B361D);
const _kOnSurfaceVariant = Color(0xFF3B6447);
const _kSurfaceContainerLowest = Color(0xFFFFFFFF);
const _kSurfaceContainerLow = Color(0xFFCAFDD4);
const _kSurfaceContainerHigh = Color(0xFFB5F0C2);
const _kSurfaceContainerHighest = Color(0xFFACECBB);

class CreatePostPage extends StatefulWidget {
  final NewsPost? postToEdit;

  const CreatePostPage({super.key, this.postToEdit});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final NewsService _newsService = NewsService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();

  PostCategory _selectedCategory = PostCategory.community;
  bool _isSubmitting = false;
  bool _postAnonymously = false;
  String? _imageUrl; // base64 string or remote URL

  @override
  void initState() {
    super.initState();
    if (widget.postToEdit != null) {
      _titleController.text = widget.postToEdit!.title;
      _contentController.text = widget.postToEdit!.content;
      _selectedCategory = widget.postToEdit!.category;
      _postAnonymously = widget.postToEdit!.authorName == 'Anonymous';
      _imageUrl = widget.postToEdit!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (picked == null) return;
      // ponytail: base64 in the image_url column, mirroring how avatars are
      // stored in this app. Upgrade path: upload to a Supabase Storage bucket
      // if post images grow large/numerous.
      // XFile.readAsBytes() works on web too; dart:io File(picked.path) throws
      // "Unsupported operation" there.
      final bytes = await picked.readAsBytes();
      setState(() => _imageUrl = base64Encode(bytes));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  /// Asks for a URL and appends it to the post content.
  Future<void> _attachLink() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kSurfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.attachLink,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: _kOnSurface,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          style: GoogleFonts.manrope(color: _kOnSurface),
          decoration: InputDecoration(
            hintText: 'https://...',
            hintStyle: GoogleFonts.manrope(
              color: _kOnSurfaceVariant.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: _kSurfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.manrope(color: _kOnSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(
              l10n.confirm,
              style: GoogleFonts.manrope(
                color: _kPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    if (url == null || url.trim().isEmpty) return;
    var link = url.trim();
    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      link = 'https://$link';
    }
    final existing = _contentController.text;
    final sep = existing.isEmpty || existing.endsWith('\n') ? '' : '\n';
    _contentController.text = '$existing$sep$link';
    _contentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _contentController.text.length),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    final l10n = context.l10n;

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterTitle)),
      );
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterContent)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final supabaseService = SupabaseService.instance;
      final user = supabaseService.currentUser!;

      String authorName;
      String? authorAvatarUrl;
      String authorRole;

      if (_postAnonymously) {
        authorName = 'Anonymous';
        authorAvatarUrl = null;
        authorRole = 'user';
      } else {
        final userData = await supabaseService.client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        authorName = userData?['full_name'] ?? 'User';
        authorAvatarUrl = userData?['avatar_url'];
        authorRole = userData?['role'] ?? 'user';
      }

      final post = NewsPost(
        postId: widget.postToEdit?.postId ?? '',
        authorId: user.id,
        isAnonymous: _postAnonymously,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        authorRole: authorRole,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageUrl: _imageUrl,
        category: _selectedCategory,
      );

      if (widget.postToEdit != null) {
        await _newsService.updatePost(post);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.postUpdated),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        await _newsService.createPost(post);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.postCreated),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.errorCreatingPost}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEditMode = widget.postToEdit != null;
    final titleLength = _titleController.text.length;
    final contentLength = _contentController.text.length;

    return Scaffold(
      backgroundColor: _kSurface,
      body: Column(
        children: [
          // Glassmorphic Header
          _buildGlassHeader(l10n, isEditMode),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Category Section
                  _buildSectionHeader(l10n.category, l10n.required),
                  const SizedBox(height: 12),
                  _buildCategoryPills(),
                  const SizedBox(height: 32),

                  // Anonymity Toggle Card
                  _buildAnonymityCard(),
                  const SizedBox(height: 32),

                  // Title Field
                  _buildTitleField(titleLength),
                  const SizedBox(height: 24),

                  // Content Field
                  _buildContentField(contentLength),
                  const SizedBox(height: 32),

                  // Attached image preview
                  if (_imageUrl != null && _imageUrl!.isNotEmpty) ...[
                    _buildImagePreview(),
                    const SizedBox(height: 16),
                  ],

                  // Media Attachment Buttons
                  _buildMediaButtons(),
                  const SizedBox(height: 32),

                  // Guidelines Decorative Card
                  _buildGuidelinesCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isSubmitting)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: _kPrimary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassHeader(AppLocalizations l10n, bool isEditMode) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface.withValues(alpha: 0.80),
        boxShadow: [
          BoxShadow(
            color: _kOnSurface.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Back button
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(
                        IconsaxPlusLinear.arrow_left_2,
                        color: _kPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                  // Title
                  Expanded(
                    child: Center(
                      child: Text(
                        isEditMode ? l10n.editPost : l10n.createPost,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  // CTA Button
                  InkWell(
                    onTap: _isSubmitting ? null : _submitPost,
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_kPrimary, _kPrimaryDim],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: [
                          BoxShadow(
                            color: _kPrimary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        isEditMode ? l10n.updateAction : l10n.postAction,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kOnPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _kOnSurface,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _kSurfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badge,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kOnSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPills() {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PostCategory.values.map((category) {
        final isSelected = _selectedCategory == category;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _kPrimary : _kSurfaceContainerHighest,
              borderRadius: BorderRadius.circular(9999),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _kPrimary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              categoryDisplayName(category, l10n),
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _kOnPrimary : _kOnSurfaceVariant,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnonymityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kOnSurface.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kSurfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _postAnonymously ? IconsaxPlusLinear.eye_slash : IconsaxPlusLinear.eye,
              color: _kPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.postAnonymously,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kOnSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.identityHidden,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: _kOnSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Custom toggle
          GestureDetector(
            onTap: () => setState(() => _postAnonymously = !_postAnonymously),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: _postAnonymously ? _kPrimary : _kSurfaceContainerHighest,
                borderRadius: BorderRadius.circular(9999),
              ),
              padding: const EdgeInsets.all(2),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: _postAnonymously
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField(int length) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.postTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kOnSurface,
              ),
            ),
            Text(
              '$length / 80',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: _kOnSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _FocusTextField(
          controller: _titleController,
          focusNode: _titleFocus,
          placeholder: context.l10n.titlePlaceholder,
          maxLines: 1,
          maxLength: 80,
        ),
      ],
    );
  }

  Widget _buildContentField(int length) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.content,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kOnSurface,
              ),
            ),
            Text(
              '$length / 2000',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: _kOnSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _FocusTextField(
          controller: _contentController,
          focusNode: _contentFocus,
          placeholder: context.l10n.contentPlaceholder,
          maxLines: 8,
          maxLength: 2000,
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    final url = _imageUrl!;
    final isRemote = url.startsWith('http://') || url.startsWith('https://');
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: isRemote
                ? Image.network(url, width: double.infinity, fit: BoxFit.cover)
                : Image.memory(
                    base64Decode(url),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _imageUrl = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaButtons() {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _MediaButton(
            icon: IconsaxPlusLinear.gallery,
            label: l10n.addPhoto,
            onTap: _pickImage,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MediaButton(
            icon: IconsaxPlusLinear.link,
            label: l10n.attachLink,
            onTap: _attachLink,
          ),
        ),
      ],
    );
  }

  Widget _buildGuidelinesCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kPrimaryContainer.withValues(alpha: 0.3),
            _kSurfaceContainerLowest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
        children: [
          // Decorative blur orb
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kPrimary.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.guidelines,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _kPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.guidelinesText,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: _kOnSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Decorative icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kSurfaceContainerHighest,
                    border: Border.all(color: _kSurfaceContainerLow, width: 3),
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.leaf,
                    color: _kPrimary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

/// Custom text field with focus animation and no borders
class _FocusTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final int maxLines;
  final int maxLength;

  const _FocusTextField({
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.maxLines,
    required this.maxLength,
  });

  @override
  State<_FocusTextField> createState() => _FocusTextFieldState();
}

class _FocusTextFieldState extends State<_FocusTextField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() => _isFocused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        style: GoogleFonts.manrope(
          fontSize: widget.maxLines == 1 ? 16 : 15,
          fontWeight: widget.maxLines == 1 ? FontWeight.w600 : FontWeight.normal,
          color: _kOnSurface,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          hintStyle: GoogleFonts.manrope(
            fontSize: 15,
            color: _kOnSurfaceVariant.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          counterText: '',
        ),
      ),
    );
  }
}

/// Media attachment button widget
class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MediaButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _kSurfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _kPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
