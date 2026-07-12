import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';

/// Real Google Sign-In screen, ported from the Kotlin AuthActivity.
///
/// DEBUG BUILD: contains extra debugPrint() calls at every stage so the
/// flow is visible directly in the `flutter run` terminal — remove these
/// once sign-in is confirmed working end-to-end.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final existingUser = FirebaseAuth.instance.currentUser;
    debugPrint('[KilatSpeak] initState: existingUser = ${existingUser?.email}');
    if (existingUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.launch);
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    debugPrint('[KilatSpeak] Sign-in button tapped — starting flow');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[KilatSpeak] Calling GoogleSignIn.instance.authenticate()...');
      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();
      debugPrint('[KilatSpeak] authenticate() returned. Account email: ${account.email}');

      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;
      debugPrint('[KilatSpeak] idToken is null? ${idToken == null}');

      if (idToken == null) {
        debugPrint('[KilatSpeak] STOPPING: idToken was null.');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Google sign-in failed — no ID token returned.';
        });
        return;
      }

      debugPrint('[KilatSpeak] Building Firebase credential...');
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      debugPrint('[KilatSpeak] Calling FirebaseAuth.signInWithCredential()...');
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('[KilatSpeak] Firebase sign-in SUCCESS. uid: ${userCredential.user?.uid}, email: ${userCredential.user?.email}');

      if (!mounted) {
        debugPrint('[KilatSpeak] Widget unmounted before navigation — aborting.');
        return;
      }
      setState(() => _isLoading = false);
      debugPrint('[KilatSpeak] Navigating to ${AppRoutes.launch}...');
      context.go(AppRoutes.launch);
      debugPrint('[KilatSpeak] Navigation call completed.');
    } on GoogleSignInException catch (e) {
      debugPrint('[KilatSpeak] GoogleSignInException: code=${e.code}, description=${e.description}');
      setState(() {
        _isLoading = false;
        _errorMessage = e.code == GoogleSignInExceptionCode.canceled
            ? null
            : 'Google sign-in error: ${e.description ?? e.code}';
      });
    } on FirebaseAuthException catch (e) {
      debugPrint('[KilatSpeak] FirebaseAuthException: code=${e.code}, message=${e.message}');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Firebase auth error: ${e.message ?? e.code}';
      });
    } catch (e, stack) {
      debugPrint('[KilatSpeak] UNEXPECTED ERROR: $e');
      debugPrint('[KilatSpeak] Stack trace: $stack');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sign-in failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt, size: 72, color: AppColors.navyDeep),
              const SizedBox(height: 20),
              Text(
                'KilatSpeak',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _isLoading ? 'Signing in…' : 'Welcome',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const CircularProgressIndicator(color: AppColors.goldPrimary)
              else
                ElevatedButton.icon(
                  onPressed: _handleGoogleSignIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldPrimary,
                    foregroundColor: AppColors.navyDeep,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.recordingRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.recordingRed),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.recordingRed,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
