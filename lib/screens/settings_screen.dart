import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import 'sign_in_screen.dart';
import '../services/backup_service.dart';
import '../services/session_manager.dart';
import '../services/secure_storage_service.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricsEnabled = false;
  int _autoLockMinutes = 5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final biometrics = await SecureStorageService.isBiometricsEnabled();
    final timeout = sessionManager.timeoutMinutes;
    
    if (mounted) {
      setState(() {
        _biometricsEnabled = biometrics;
        _autoLockMinutes = timeout;
      });
    }
  }

  Future<void> _backup(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      final backupService = BackupService();
      await backupService.backupToDrive();
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Backup successful!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Backup failed: $e')),
        );
      }
    }
  }

  Future<void> _restore(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from backup?'),
        content: const Text(
          'This will merge your cloud backup with existing local data. Entries with the same ID will be updated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      final backupService = BackupService();
      await backupService.restoreFromDrive();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Restore successful!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Restore failed: $e')),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, themeMode, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Appearance Section
              _buildSectionHeader(context, 'Appearance'),
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

              const SizedBox(height: 32),

              // Security Section
              _buildSectionHeader(context, 'Security'),
              const SizedBox(height: 8),
              
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.fingerprint_rounded),
                title: const Text('Biometric Unlock'),
                subtitle: const Text('Use fingerprint / Face ID'),
                value: _biometricsEnabled,
                onChanged: (value) async {
                  await SecureStorageService.setBiometricsEnabled(value);
                  setState(() => _biometricsEnabled = value);
                },
              ),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Auto-Lock Timeout'),
                subtitle: Text('Lock after $_autoLockMinutes ${_autoLockMinutes == 1 ? "minute" : "minutes"} of inactivity'),
                trailing: DropdownButton<int>(
                  value: _autoLockMinutes,
                  underline: const SizedBox(),
                  items: [1, 2, 5, 10, 15, 30, 60]
                      .map((minutes) => DropdownMenuItem(
                            value: minutes,
                            child: Text('$minutes min'),
                          ))
                      .toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      await sessionManager.setTimeoutMinutes(value);
                      setState(() => _autoLockMinutes = value);
                    }
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Backup Section
              _buildSectionHeader(context, 'Backup & Sync'),
              const SizedBox(height: 8),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_upload_outlined),
                title: const Text('Backup to Google Drive'),
                subtitle: const Text('Save encrypted vault to cloud'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _backup(context),
              ),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cloud_download_outlined),
                title: const Text('Restore from Google Drive'),
                subtitle: const Text('Merge cloud backup with local data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _restore(context),
              ),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('Manage Account'),
                subtitle: const Text('Sign in or switch Google Account'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, SignInScreen.routeName);
                },
              ),

              const SizedBox(height: 32),

              // Legal Section
              _buildSectionHeader(context, 'Legal & About'),
              const SizedBox(height: 8),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  // In production, host this on your website
                  _launchURL('https://vaultlock.app/privacy');
                },
              ),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  _launchURL('https://vaultlock.app/terms');
                },
              ),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outlined),
                title: const Text('About VaultLock'),
                subtitle: const Text('Version 1.0.0'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'VaultLock',
                    applicationVersion: '1.0.0',
                    applicationIcon: Icon(Icons.shield, size: 48, color: colors.primary),
                    applicationLegalese:
                        '© 2025 VaultLock\n\nYour passwords are encrypted locally using military-grade AES-256 encryption. We never see your data.',
                    children: [
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => _launchURL('https://vaultlock.app'),
                        child: const Text('Visit Website'),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Subscription Section (placeholder)
              Card(
                color: colors.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: colors.onPrimaryContainer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'VaultLock Premium',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colors.onPrimaryContainer,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cloud sync + unlimited entries + priority support',
                        style: TextStyle(color: colors.onPrimaryContainer),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: () {
                          // TODO: Implement subscription flow
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Subscription coming soon! \$3/month or \$30/year'),
                            ),
                          );
                        },
                        child: const Text('Upgrade to Premium'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
