import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../main.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/localization_service.dart';
import 'login_page.dart';
import 'signup_page.dart';

// ============================================================================
// WELCOME PAGE - CEO MODERN DESIGN
// ============================================================================
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Scale animation (controller kept for dispose, animation removed)
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scaleController.forward();

    // Slide animation
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _navigateToPage(Widget page) async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /* ============================================================================
   * ADMIN SETUP - ĐÃ TẠO XONG, COMMENT ĐỂ TRÁNH TẠO LẠI
   * ============================================================================
   * Uncomment nếu cần tạo admin mới hoặc debug
   * 
  // Secret admin setup - Long press on logo (only in debug mode)
  void _showAdminSetupDialog() {
    if (!kDebugMode) return; // Only in debug mode

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: const [
            Icon(IconsaxPlusLinear.user_tick, color: Color(0xFF4CAF50)),
            SizedBox(width: 12),
            Text(
              'Admin Setup',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tạo admin account để quản lý app.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Email:', 'admin@mindfulmoments.com'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Password:', 'Admin@123456'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '⚠️ Chỉ chạy 1 lần khi setup app',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Hủy',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                  ),
                ),
              );

              try {
                await createAdminAccount();
                
                // Use Navigator.of with rootNavigator to ensure we have valid context
                if (!mounted) return;
                
                // Close loading dialog
                Navigator.of(context, rootNavigator: true).pop();
                
                // Show success snackbar
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Admin account created successfully!'),
                    backgroundColor: Color(0xFF4CAF50),
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                // Close loading dialog
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop();
                
                // Show error snackbar
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Tạo Admin',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
  */ // End of commented admin setup code

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.osSurface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo + MOODIKI wordmark on the same row
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Small logo
                      Hero(
                        tag: 'app_logo',
                        child: GestureDetector(
                          onLongPress: () {
                            if (kDebugMode) {
                              _navigateToPage(const OnboardingPage());
                            }
                          },
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.osOnSurface.withValues(alpha: 0.06),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // MOODIKI wordmark
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.osPrimary, AppColors.osPrimaryDim],
                        ).createShader(bounds),
                        child: Text(
                          'MOODIKI',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Tagline
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    context.l10n.appTagline,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.osOnSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.25,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Sub-description
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    context.l10n.welcomeTagline,
                    style: GoogleFonts.manrope(
                      color: AppColors.osOnSurfaceVariant,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Feature highlights
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FeatureItem(
                        icon: PhosphorIconsRegular.brain,
                        text: context.l10n.aiPoweredInsights,
                      ),
                      const SizedBox(height: 14),
                      _FeatureItem(
                        icon: IconsaxPlusLinear.trend_up,
                        text: context.l10n.trackProgress,
                      ),
                      const SizedBox(height: 14),
                      _FeatureItem(
                        icon: IconsaxPlusLinear.shield,
                        text: context.l10n.privateSecure,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Animated Buttons
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Sign Up Button
                        _PrimaryButton(
                          text: context.l10n.getStarted,
                          onPressed: () => _navigateToPage(const SignUpPage()),
                        ),

                        const SizedBox(height: 16),

                        // Login Button
                        _SecondaryButton(
                          text: context.l10n.signIn,
                          onPressed: () => _navigateToPage(const LoginPage()),
                        ),

                        const SizedBox(height: 16),

                        // Terms link
                        Text.rich(
                          TextSpan(
                            text: context.l10n.termsAgreement,
                            style: GoogleFonts.manrope(
                              color: AppColors.osOnSurfaceVariant,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: context.l10n.termsPrivacy,
                                style: GoogleFonts.manrope(
                                  color: AppColors.osOnSurface,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.osOnSurface,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ), // end Column
                  ), // end FadeTransition
                ), // end SlideTransition

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// FEATURE ITEM COMPONENT
// ============================================================================
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.osPrimaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.osPrimary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.manrope(
            color: AppColors.osOnSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PRIMARY BUTTON COMPONENT
// ============================================================================
class _PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.text, required this.onPressed});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isPressed
                  ? [
                      AppColors.osPrimaryDim,
                      AppColors.osPrimaryDim,
                    ]
                  : [
                      AppColors.osPrimary,
                      AppColors.osPrimaryDim,
                    ],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: AppColors.osOnSurface.withValues(alpha: 0.06),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(999),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.text,
                      style: GoogleFonts.manrope(
                        color: AppColors.osOnPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      IconsaxPlusLinear.arrow_right_3,
                      color: AppColors.osOnPrimary,
                      size: 20,
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
}

// ============================================================================
// SECONDARY BUTTON COMPONENT
// ============================================================================
class _SecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const _SecondaryButton({required this.text, required this.onPressed});

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: _isPressed
                ? AppColors.osSurfaceContainerHigh
                : AppColors.osPrimaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(999),
              child: Center(
                child: Text(
                  widget.text,
                  style: GoogleFonts.manrope(
                    color: AppColors.osOnPrimaryContainer,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
