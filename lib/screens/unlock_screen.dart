import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/secure_storage_service.dart';
import '../services/vault_service.dart';
import '../services/session_manager.dart';
import 'vault_home_screen.dart';

class UnlockScreen extends StatefulWidget {
  static const routeName = '/unlock';

  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  final _auth = LocalAuthentication();
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      final enabled = await SecureStorageService.isBiometricsEnabled();
      if (!mounted) return;
      setState(() {
        _biometricAvailable = canCheck && isDeviceSupported && enabled;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _biometricAvailable = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initVaultAndGoHome() async {
    final keyBytes = await SecureStorageService.getVaultKey();
    await VaultService.init(Uint8List.fromList(keyBytes));

    // Mark session as unlocked
    sessionManager.unlock();

    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(VaultHomeScreen.routeName, (_) => false);
  }

  void _unlock() async {
    final password = _passwordController.text;
    
    try {
      final ok = await SecureStorageService.verifyMasterPassword(password);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect master password')),
        );
        return;
      }

      await _initVaultAndGoHome();
    } catch (e) {
      // Handle lockout exception
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _unlockWithBiometric() async {
    try {
      final didAuth = await _auth.authenticate(
        localizedReason: 'Unlock your vault',
        biometricOnly: true, // supported in your version
      );

      if (!didAuth) return;

      await _initVaultAndGoHome();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Biometric auth failed: $e')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded,
                    size: 72, color: colors.primary),
                const SizedBox(height: 16),
                Text(
                  'Unlock Vault',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Master password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onSubmitted: (_) => _unlock(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _unlock,
                    child: const Text('Unlock'),
                  ),
                ),
                const SizedBox(height: 16),
                if (_biometricAvailable)
                  TextButton(
                    onPressed: _unlockWithBiometric,
                    child: const Text('Use biometric instead'),
                  )
                else
                  Text(
                    'Biometric unlock not available or disabled.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.outline),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
