import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;

class SignInScreen extends StatelessWidget {
  static const routeName = '/sign-in';

  const SignInScreen({super.key});

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'https://www.googleapis.com/auth/drive.file'],
      );

      final account = await googleSignIn.signIn();
      if (account == null) return; // user cancelled

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signed in as ${account.email}')));

      // Authentication successful - token available via account.authentication when needed
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google Sign-In failed: $e')));
    }
  }

  Future<void> _handleAppleSignIn(BuildContext context) async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (context.mounted) {
        // The credential variable is used here just to confirm success,
        // but in a real app, you would use credential.identityToken etc.
        debugPrint('Apple ID Credential obtained: $credential');

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Signed in with Apple')));
        // Navigate or store credential
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Apple Sign-In failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_person_rounded, size: 72, color: colors.primary),
            const SizedBox(height: 24),
            Text(
              'Sign in to keep your backups linked to your account.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleGoogleSignIn(context),
                icon: SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.login),
                  ),
                ),
                label: const Text('Continue with Google'),
              ),
            ),
            const SizedBox(height: 16),
            if (Platform.isIOS || Platform.isMacOS) ...[
              SizedBox(
                width: double.infinity,
                child: SignInWithAppleButton(
                  onPressed: () => _handleAppleSignIn(context),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
