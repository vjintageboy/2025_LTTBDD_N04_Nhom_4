import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import '../home/home_page.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/localization_service.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/modern_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/social_button.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _nameController.text,
    );

    if (!mounted) return;

    if (success) {
      debugPrint('🎉 Signup successful! Navigating to HomePage...');

      // For new signups, role is always 'user'
      // Navigate and clear entire stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? AppStrings.signUpFailed),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Google sign-in failed'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.osSurface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Back button
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.osSurfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(14),
                          child: const Icon(
                            IconsaxPlusLinear.arrow_left,
                            color: AppColors.osOnSurface,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Logo + brand row
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.osOnSurface.withValues(alpha: 0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppColors.osPrimary, AppColors.osPrimaryDim],
                          ).createShader(bounds),
                          child: Text(
                            'MOODIKI',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Title
                    Text(
                      context.l10n.createAccount,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.osOnSurface,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.joinUsToday,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: AppColors.osOnSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Name field
                    ModernTextField(
                      controller: _nameController,
                      label: context.l10n.fullName,
                      hint: context.l10n.fullName,
                      icon: IconsaxPlusLinear.user,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.fullName;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Email field
                    ModernTextField(
                      controller: _emailController,
                      label: context.l10n.emailAddress,
                      hint: context.l10n.email,
                      icon: IconsaxPlusLinear.sms,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.emailAddress;
                        }
                        if (!value.contains('@')) {
                          return context.l10n.emailAddress;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password field
                    ModernTextField(
                      controller: _passwordController,
                      label: context.l10n.password,
                      hint: context.l10n.password,
                      icon: IconsaxPlusLinear.lock_1,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? IconsaxPlusLinear.eye
                              : IconsaxPlusLinear.eye_slash,
                          color: AppColors.osOnSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.password;
                        }
                        if (value.length < 6) {
                          return context.l10n.password;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Confirm password field
                    ModernTextField(
                      controller: _confirmPasswordController,
                      label: context.l10n.confirmPassword,
                      hint: context.l10n.password,
                      icon: IconsaxPlusLinear.lock_1,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? IconsaxPlusLinear.eye
                              : IconsaxPlusLinear.eye_slash,
                          color: AppColors.osOnSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() =>
                              _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.confirmPassword;
                        }
                        if (value != _passwordController.text) {
                          return context.l10n.confirmPassword;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // Sign up button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return PrimaryButton(
                          text: context.l10n.createAccount,
                          icon: IconsaxPlusLinear.arrow_right_3,
                          isLoading: authProvider.isLoading,
                          onPressed: _signUp,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // "Or continue with" — no divider lines
                    Center(
                      child: Text(
                        context.l10n.orContinueWith,
                        style: GoogleFonts.manrope(
                          color: AppColors.osOnSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Google signup button
                    SocialButton(
                      icon: PhosphorIconsRegular.googleLogo,
                      label: 'Google',
                      onPressed: _handleGoogleSignIn,
                    ),

                    const SizedBox(height: 32),

                    // Login link
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.alreadyHaveAccount,
                            style: GoogleFonts.manrope(
                              color: AppColors.osOnSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              context.l10n.signIn,
                              style: GoogleFonts.manrope(
                                color: AppColors.osPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
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
