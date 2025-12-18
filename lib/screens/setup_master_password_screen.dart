import 'package:flutter/material.dart';
import 'vault_home_screen.dart';
import 'dart:typed_data';
import '../services/secure_storage_service.dart';
import '../services/vault_service.dart';
import '../widgets/password_strength_indicator.dart';

class SetupMasterPasswordScreen extends StatefulWidget {
  static const routeName = '/setup-master';

  const SetupMasterPasswordScreen({super.key});

  @override
  State<SetupMasterPasswordScreen> createState() =>
      _SetupMasterPasswordScreenState();
}

class _SetupMasterPasswordScreenState extends State<SetupMasterPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _useBiometrics = true;
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    try {
      final password = _passwordController.text;

      await SecureStorageService.saveMasterPassword(
        password,
        _useBiometrics,
      );

      final keyBytes = await SecureStorageService.getVaultKey();
      await VaultService.init(Uint8List.fromList(keyBytes));

      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(VaultHomeScreen.routeName, (_) => false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your vault'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Icon(Icons.shield_rounded, size: 64, color: colors.primary),
              const SizedBox(height: 16),
              Text(
                'Create a master password',
                style: Theme.of(context).textTheme. headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This password unlocks all your data. Choose a strong password and don\'t forget it!',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                onChanged: (_) => setState(() {}), // Trigger strength indicator update
                decoration: InputDecoration(
                  labelText: 'Master password',
                  helperText: 'Minimum 12 characters',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 12) {
                    return 'Password must be at least 12 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              
              // Password strength indicator
              PasswordStrengthIndicator(password: _passwordController.text),
              
              const SizedBox(height: 24),
              
              // Confirm password field
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Hints card
              Card(
                color: colors.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, 
                              size: 20, color: colors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Tips for a strong password:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildTip('Use uppercase and lowercase letters'),
                      _buildTip('Include numbers and symbols'),
                      _buildTip('Avoid common words or patterns'),
                      _buildTip('Make it at least 16 characters long'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Biometrics toggle
              SwitchListTile(
                value: _useBiometrics,
                onChanged: (v) => setState(() => _useBiometrics = v),
                title: const Text('Unlock with fingerprint/Face ID'),
                subtitle: const Text('Faster unlock on supported devices'),
              ),
              
              const SizedBox(height: 24),
              
              // Create button
              FilledButton(
                onPressed: _isLoading ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create vault'),
              ),
              
              const SizedBox(height: 16),
              Text(
                '🔒 Your data is encrypted locally on this device using military-grade AES-256 encryption.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.outline),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, 
              size: 16, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
