import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../../services/supabase_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    // Check initial session
    final session = _supabase.auth.currentSession;
    if (session != null) {
      debugPrint('🔐 Initial session found');
      _status = AuthStatus.authenticated;
    } else {
      debugPrint('🔐 No initial session');
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();

    // Listen to auth changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final user = data.session?.user;
      debugPrint('🔐 Auth event: $event');
      if (event == AuthChangeEvent.signedIn) {
        debugPrint('🔐 → Authenticated');
        if (user != null) {
          await _ensureProfile(user);
        }
        _status = AuthStatus.authenticated;
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('🔐 → Unauthenticated');
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    List<String>? goals,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      // Sign up with Supabase
      final AuthResponse res = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'goals': goals ?? AppConstants.defaultUserGoals,
        }, // User metadata
      );

      if (res.user != null) {
        // Tạo row trong bảng `users`
        try {
          await _supabaseService.createUserProfile(
            id: res.user!.id,
            email: email.trim(),
            fullName: fullName.trim(),
          );
        } catch (e) {
          debugPrint('Optional profile creation failed: $e');
        }

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      _status = AuthStatus.error;
      _errorMessage = "Failed to create user";
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      // Status will be updated by onAuthStateChange listener
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      // Status will be updated by onAuthStateChange listener
    } catch (e) {
      _errorMessage = 'Failed to sign out: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _supabase.auth.resetPasswordForEmail(email.trim());

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to send reset email: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  static const _kRedirectUrl = 'vn.phenikaa.pha.moodiki://login-callback';

  /// Google sign-in via Supabase browser-based OAuth.
  /// Opens Safari, user authenticates, redirect back to the app.
  /// Waits for the signedIn event before returning.
  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('🔵 Google sign-in starting...');
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final launched = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _kRedirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      debugPrint('🔵 OAuth launched: $launched');

      // Wait for the redirect to complete and user to be signed in
      final event = await _supabase.auth.onAuthStateChange
          .firstWhere(
            (e) => e.event == AuthChangeEvent.signedIn,
          )
          .timeout(const Duration(seconds: 30));

      if (event.event == AuthChangeEvent.signedIn) {
        debugPrint('🔵 Signed in successfully!');
        return true;
      }

      return false;
    } on TimeoutException {
      debugPrint('🔵 Timeout waiting for sign-in');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('🔵 Error: $e');
      _status = AuthStatus.error;
      _errorMessage = 'Google sign-in failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Create user profile in `users` table if it doesn't exist yet.
  Future<void> _ensureProfile(User user, {String? overrideName}) async {
    try {
      final existing = await _supabaseService.getUserById(user.id);
      if (existing == null) {
        final name = (overrideName != null && overrideName.isNotEmpty)
            ? overrideName
            : (user.userMetadata?['full_name'] ?? '');
        await _supabaseService.createUserProfile(
          id: user.id,
          email: user.email ?? '',
          fullName: name,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Profile creation after social sign-in failed: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = currentUser != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
