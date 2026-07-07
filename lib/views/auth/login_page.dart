import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_page.dart';
import '../home/home_page.dart';
import '../admin/admin_main_page.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/localization_service.dart';
import '../../services/supabase_service.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/modern_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/social_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotPasswordController = TextEditingController();
  final _supabaseService = SupabaseService();
  bool _obscurePassword = true;
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
    _emailController.dispose();
    _passwordController.dispose();
    _forgotPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await _supabaseService.getUserById(user.id);
        final role = profile?.role.value ?? 'user';

        if (!mounted) return;

        // Navigate based on role - clear entire stack
        Widget destinationPage;
        if (role == 'admin') {
          destinationPage = const AdminMainPage();
        } else {
          destinationPage = const HomePage();
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => destinationPage),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? AppStrings.signInFailed),
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
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await _supabaseService.getUserById(user.id);
        final role = profile?.role.value ?? 'user';

        if (!mounted) return;

        Widget destinationPage;
        if (role == 'admin') {
          destinationPage = const AdminMainPage();
        } else {
          destinationPage = const HomePage();
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => destinationPage),
          (route) => false,
        );
      }
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

  void _showForgotPasswordDialog() {
    final parentContext = context;
    _forgotPasswordController.text = _emailController.text.trim();
    final dialogFormKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submitRequest() async {
              if (isSubmitting) return;
              if (!dialogFormKey.currentState!.validate()) return;

              if (!context.mounted) return;
              setState(() => isSubmitting = true);

              final authProvider = parentContext.read<AuthProvider>();
              final success = await authProvider.resetPassword(
                _forgotPasswordController.text.trim(),
              );

              if (!mounted || !parentContext.mounted || !dialogContext.mounted) return;

              if (success) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Nếu email này đã được đăng ký, chúng tôi đã gửi hướng dẫn đặt lại mật khẩu vào hộp thư của bạn.',
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              } else {
                if (!context.mounted) return;
                setState(() => isSubmitting = false);
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      authProvider.errorMessage ?? AppStrings.signInFailed,
                    ),
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

            final bottomInset = MediaQuery.of(parentContext).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: bottomInset > 0 ? bottomInset : 24,
                top: 24,
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: AlertDialog(
                    backgroundColor: AppColors.osSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    title: Text(
                      'Đặt lại mật khẩu',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: AppColors.osOnSurface,
                      ),
                    ),
                    content: Form(
                      key: dialogFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nhập email để nhận liên kết đặt lại mật khẩu.',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: AppColors.osOnSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ModernTextField(
                            controller: _forgotPasswordController,
                            label: context.l10n.emailAddress,
                            hint: context.l10n.email,
                            icon: IconsaxPlusLinear.sms,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return context.l10n.emailAddress;
                              }
                              final emailRegex = RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              );
                              if (!emailRegex.hasMatch(value.trim())) {
                                return context.l10n.emailAddress;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    actionsPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.osOnSurfaceVariant,
                        ),
                        child: Text(
                          'Hủy',
                          style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: isSubmitting ? null : submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.osPrimary,
                          foregroundColor: AppColors.osOnPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.osOnPrimary,
                                ),
                              )
                            : Text(
                                'Gửi yêu cầu',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.osOnPrimary,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
                      context.l10n.signInToModiki,
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
                      context.l10n.signInToContinue,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: AppColors.osOnSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 32),

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

                    const SizedBox(height: 8),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                        ),
                        child: Text(
                          context.l10n.forgotPassword,
                          style: GoogleFonts.manrope(
                            color: AppColors.osPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Login button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return PrimaryButton(
                          text: context.l10n.signIn,
                          icon: IconsaxPlusLinear.arrow_right_3,
                          isLoading: authProvider.isLoading,
                          onPressed: _login,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // "Or continue with" — no divider lines, just spaced text
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

                    // Google login button
                    SocialButton(
                      icon: PhosphorIconsRegular.googleLogo,
                      label: 'Google',
                      onPressed: _handleGoogleSignIn,
                    ),

                    const SizedBox(height: 32),

                    // Sign up link
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.dontHaveAccount,
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
                                  builder: (context) => const SignUpPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              context.l10n.signUp,
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
