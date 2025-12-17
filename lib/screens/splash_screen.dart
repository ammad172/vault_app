import 'dart:async';
import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
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
    await Future.delayed(const Duration(milliseconds: 800));

    final hasMaster = await SecureStorageService.hasMasterPassword();

    if (!mounted) return;

    if (hasMaster) {
      Navigator.of(context)
          .pushReplacementNamed(UnlockScreen.routeName);
    } else {
      Navigator.of(context)
          .pushReplacementNamed(SetupMasterPasswordScreen.routeName);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 72, color: colors.onPrimary),
              const SizedBox(height: 16),
              Text(
                'VaultLock',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: colors.onPrimary),
              ),
              const SizedBox(height: 8),
              Text(
              'Offline Password Vault',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.8),
                  ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
