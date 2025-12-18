import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/secure_storage_service.dart';
import 'onboarding_screen.dart';
import 'setup_master_password_screen.dart';
import 'unlock_screen.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 1200));

    // Check if this is first launch
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    final hasMaster = await SecureStorageService.hasMasterPassword();

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      // First time user - show onboarding
      await prefs.setBool('has_seen_onboarding', true);
      Navigator.of(context).pushReplacementNamed(OnboardingScreen.routeName);
    } else if (hasMaster) {
      // Existing user with vault - show unlock screen
      Navigator.of(context).pushReplacementNamed(UnlockScreen.routeName);
    } else {
      // Seen onboarding but no vault yet
      Navigator.of(context).pushReplacementNamed(SetupMasterPasswordScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primaryContainer,
              colors.primary,
              colors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_rounded,
                  size: 80, color: colors.onPrimary),
              const SizedBox(height: 24),
              Text(
                'VaultLock',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Secure Password Manager',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      color: colors.onPrimary.withOpacity(0.9),
                    ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: colors.onPrimary,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
