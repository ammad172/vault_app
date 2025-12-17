import 'package:flutter/material.dart';
import '../main.dart';
import 'sign_in_screen.dart';
import '../services/backup_service.dart';
import '../services/vault_service.dart';
import '../models/vault_entry.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  Future<void> _backup(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      final backupService = BackupService();
      await backupService.backupToDrive();
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup successful!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  Future<void> _restore(BuildContext context) async {
    try {
        showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      final backupService = BackupService();
      // Logic for restore moved to service, we need to handle the data parsing there or here.
      // For simplicity, let's assume service handles fetching JSON string, 
      // but we need to parse it and save to DB.
      
      // Actually, let's update BackupService to return the list or do the saving.
      // Updating the service requires re-writing it. 
      // Instead, I'll invoke the service's restore method (which I will fix in a moment to handle the saving loop).
      await backupService.restoreFromDrive();

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restore successful!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, themeMode, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.phone_android_rounded),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_rounded),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_rounded),
                  ),
                ],
                selected: {themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (newSelection) {
                  if (newSelection.isNotEmpty) {
                    themeModeNotifier.value = newSelection.first;
                  }
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Account & Backup',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_upload_outlined),
                title: const Text('Backup to Google Drive'),
                subtitle: const Text('Save your encrypted vault to the cloud'),
                onTap: () => _backup(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_download_outlined),
                title: const Text('Restore from Google Drive'),
                subtitle: const Text('Merge cloud backup with local data'),
                onTap: () => _restore(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('Sign In / Switch Account'),
                onTap: () {
                   Navigator.pushNamed(context, SignInScreen.routeName);
                },
              ),

              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Unlock with biometric'),
                subtitle:
                    const Text('Use fingerprint / Face ID when available'),
                value: true,
                onChanged: (v) {
                  // TODO: persist preference and wire with real biometric auth
                },
              ),
              const Divider(height: 32),
              ListTile(
                title: const Text('About VaultLock'),
                subtitle:
                    const Text('Privacy-first offline password vault'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'VaultLock',
                    applicationVersion: '0.1.0',
                    applicationLegalese:
                        'Your passwords are stored locally and encrypted on this device.',
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
