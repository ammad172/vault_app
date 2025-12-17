import 'package:flutter/material.dart';
import 'vault_home_screen.dart';
import 'dart:typed_data';
import '../services/secure_storage_service.dart';
import '../services/vault_service.dart';

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

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

void _save() async {
  if (_formKey.currentState?.validate() != true) return;

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
              Text(
                'Create a master password',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'This password unlocks all your data. Don’t forget it!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Master password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Use at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                value: _useBiometrics,
                onChanged: (v) => setState(() => _useBiometrics = v),
                title: const Text('Unlock with fingerprint/Face ID'),
                subtitle: const Text('Where supported by your device'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Create vault'),
              ),
              const SizedBox(height: 12),
              Text(
                'Your data stays encrypted locally on this device.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
