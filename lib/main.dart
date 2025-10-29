import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'views/auth/welcome_page.dart';
import 'views/home/home_page.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/mood_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Moodiki',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

// ============================================================================
// AUTH WRAPPER - Check if user is logged in
// ============================================================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFFF5F6),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7B2BB0),
              ),
            ),
          );
        }
        
        // If user is logged in, go directly to HomePage
        if (snapshot.hasData) {
          return const HomePage();
        }
        
        // Otherwise, show onboarding
        return const OnboardingPage();
      },
    );
  }
}

// ============================================================================
// THEME CONFIGURATION
// ============================================================================
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}

// ============================================================================
// CONSTANTS & CONFIGURATION
// ============================================================================
class AppColors {
  static const splashBackground = Color(0xFFFFF5F6);
  static const primaryPurple = Color(0xFF7B2BB0);
  static const quoteBackground1 = Color(0xFFF2C6D8);
  static const quoteBackground2 = Color(0xFFBFD9FF);
  static const white = Colors.white;
  static const white70 = Colors.white70;
}

class AppConstants {
  static const animationDuration = Duration(milliseconds: 600);
  static const pageTransitionDuration = Duration(milliseconds: 400);
  static const splashLogoScale = 0.35;
  static const quoteLogoSize = 80.0;
  static const horizontalPadding = 28.0;
}

// ============================================================================
// ONBOARDING PAGE WITH ENHANCED UX
// ============================================================================
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppConstants.animationDuration,
    )..forward();

    _controller.addListener(() {
      final page = _controller.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
        HapticFeedback.lightImpact();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    if (_isNavigating) return;
    _isNavigating = true;

    HapticFeedback.mediumImpact();

    if (_currentPage < 2) {
      await _controller.nextPage(
        duration: AppConstants.pageTransitionDuration,
        curve: Curves.easeInOutCubic,
      );
    } else {
      await _fadeController.reverse();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const WelcomePage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: AppConstants.animationDuration,
          ),
        );
      }
    }

    _isNavigating = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTap: _navigateToNext,
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                SplashScreen(),
                QuoteScreen(
                  backgroundColor: AppColors.quoteBackground1,
                  quote:
                      '"Giữa mùa đông giá lạnh, tôi nhận ra bên trong mình vẫn có một mùa hè bất khuất."',
                  author: 'ALBERT CAMUS',
                ),
                QuoteScreen(
                  backgroundColor: AppColors.quoteBackground2,
                  quote:
                      '"Cảm xúc chỉ là những vị khách. Hãy để chúng đến rồi đi."',
                  author: 'MOOJI',
                ),
              ],
            ),
          ),
          // Page Indicators
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: _PageIndicators(currentPage: _currentPage),
          ),
          // Skip Button (only on quote screens)
          if (_currentPage > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 24,
              child: _SkipButton(onPressed: _navigateToNext),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// PAGE INDICATORS
// ============================================================================
class _PageIndicators extends StatelessWidget {
  final int currentPage;

  const _PageIndicators({required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.white : AppColors.white70,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ============================================================================
// SKIP BUTTON
// ============================================================================
class _SkipButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SkipButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.white70, width: 1),
          ),
          child: const Text(
            'Bỏ qua',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SPLASH SCREEN
// ============================================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      color: AppColors.splashBackground,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          width: size.width * AppConstants.splashLogoScale,
                          height: size.width * AppConstants.splashLogoScale,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryPurple.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            AppColors.primaryPurple,
                            AppColors.primaryPurple.withOpacity(0.8),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'MOODIKI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hành trình chăm sóc cảm xúc',
                        style: TextStyle(
                          color: AppColors.primaryPurple.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// QUOTE SCREEN
// ============================================================================
class QuoteScreen extends StatefulWidget {
  final Color backgroundColor;
  final String quote;
  final String author;

  const QuoteScreen({
    super.key,
    required this.backgroundColor,
    required this.quote,
    required this.author,
  });

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.backgroundColor,
            widget.backgroundColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.horizontalPadding,
            24,
            AppConstants.horizontalPadding,
            40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'app_logo',
                child: Container(
                  width: AppConstants.quoteLogoSize,
                  height: AppConstants.quoteLogoSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.white.withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.quote,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: size.width * 0.074,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '— ${widget.author}',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}