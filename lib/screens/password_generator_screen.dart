import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/password_generator_service.dart';
import '../services/session_manager.dart';
import '../services/premium_service.dart';
import '../widgets/password_strength_indicator.dart';
import '../widgets/ad_banner_widget.dart';
import 'premium_screen.dart';

/// Standalone screen for password generation - perfect for quick password creation
class PasswordGeneratorScreen extends StatefulWidget {
  static const routeName = '/password-generator';

  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() =>
      _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  String _generatedPassword = '';
  int _length = 16;
  bool _uppercase = true;
  bool _lowercase = true;
  bool _numbers = true;
  bool _symbols = true;
  bool _excludeAmbiguous = false;
  bool _usePassphrase = false;

  @override
  void initState() {
    super.initState();
    sessionManager.recordActivity();
    _generate();
  }

  Future<void> _generate() async {
    // Check generation limit for free tier
    final canGenerate = await premiumService.canGeneratePassword();
    if (!canGenerate) {
      if (!mounted) return;
      _showUpgradeDialog();
      return;
    }

    setState(() {
      if (_usePassphrase) {
        _generatedPassword = PasswordGeneratorService.generatePassphrase(
          wordCount: (_length / 4).ceil().clamp(3, 8),
        );
      } else {
        _generatedPassword = PasswordGeneratorService.generatePassword(
          PasswordConfig(
            length: _length,
            uppercase: _uppercase,
            lowercase: _lowercase,
            numbers: _numbers,
            symbols: _symbols,
            excludeAmbiguous: _excludeAmbiguous,
          ),
        );
      }
    });

    // Record generation for free tier
    await premiumService.recordPasswordGeneration();
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Limit Reached'),
        content: FutureBuilder<String>(
          future: premiumService.getPasswordGenerationLimitMessage(),
          builder: (context, snapshot) {
            return Text(snapshot.data ?? 'Upgrade to Premium for unlimited password generation.');
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(PremiumScreen.routeName);
            },
            child: const Text('Upgrade to Premium'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    sessionManager.recordActivity();
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Password copied! Ready to paste on ${_getSuggestedPlatform()}',
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  String _getSuggestedPlatform() {
    // This could be enhanced to detect which app user is switching to
    return 'your social media';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strengthResult =
        PasswordGeneratorService.calculateStrength(_generatedPassword);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology_rounded),
            SizedBox(width: 8),
            Text('Password Generator'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Generate new password',
            onPressed: () {
              sessionManager.recordActivity();
              _generate();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Card(
              elevation: 0,
              color: colors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 48,
                      color: colors.onPrimaryContainer,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Generate Strong Passwords',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create secure passwords for your social media, email, and more',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Generated password display - Large and prominent
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: strengthResult.strength == PasswordStrength.veryStrong
                      ? Colors.green
                      : strengthResult.strength == PasswordStrength.strong
                          ? Colors.lightGreen
                          : colors.outline.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _generatedPassword,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded),
                        tooltip: 'Copy password',
                        onPressed: _copyToClipboard,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PasswordStrengthIndicator(
                    password: _generatedPassword,
                    showFeedback: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick copy button for social media
            FilledButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy_all_rounded),
              label: const Text('Copy Password'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Password generation limit info for free tier
            if (!premiumService.isPremium)
              FutureBuilder<String>(
                future: premiumService.getPasswordGenerationLimitMessage(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Card(
                      elevation: 0,
                      color: colors.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: colors.onSecondaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                snapshot.data!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            const SizedBox(height: 16),

            // Ad banner for free tier
            const AdBannerWidget(),
            const SizedBox(height: 16),

            // Password type toggle
            Text(
              'Password Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Random'),
                  icon: Icon(Icons.shuffle_rounded),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Passphrase'),
                  icon: Icon(Icons.article_outlined),
                ),
              ],
              selected: {_usePassphrase},
              onSelectionChanged: (Set<bool> selection) {
                sessionManager.recordActivity();
                setState(() {
                  _usePassphrase = selection.first;
                  _generate();
                });
              },
            ),
            const SizedBox(height: 32),

            if (!_usePassphrase) ...[
              // Length slider
              Text(
                'Password Length: $_length characters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Slider(
                value: _length.toDouble(),
                min: 8,
                max: 64,
                divisions: 56,
                label: '$_length',
                onChanged: (value) {
                  sessionManager.recordActivity();
                  setState(() {
                    _length = value.toInt();
                    _generate();
                  });
                },
              ),
              const SizedBox(height: 24),

              // Character type options
              Text(
                'Include Characters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                child: Column(
                  children: [
                    CheckboxListTile(
                      dense: true,
                      title: const Text('Uppercase Letters (A-Z)'),
                      subtitle: const Text('Include capital letters'),
                      value: _uppercase,
                      onChanged: _lowercase || _numbers || _symbols
                          ? (value) {
                              sessionManager.recordActivity();
                              setState(() {
                                _uppercase = value ?? false;
                                if (_uppercase ||
                                    _lowercase ||
                                    _numbers ||
                                    _symbols) {
                                  _generate();
                                }
                              });
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    CheckboxListTile(
                      dense: true,
                      title: const Text('Lowercase Letters (a-z)'),
                      subtitle: const Text('Include small letters'),
                      value: _lowercase,
                      onChanged: _uppercase || _numbers || _symbols
                          ? (value) {
                              sessionManager.recordActivity();
                              setState(() {
                                _lowercase = value ?? false;
                                if (_uppercase ||
                                    _lowercase ||
                                    _numbers ||
                                    _symbols) {
                                  _generate();
                                }
                              });
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    CheckboxListTile(
                      dense: true,
                      title: const Text('Numbers (0-9)'),
                      subtitle: const Text('Include digits'),
                      value: _numbers,
                      onChanged: _uppercase || _lowercase || _symbols
                          ? (value) {
                              sessionManager.recordActivity();
                              setState(() {
                                _numbers = value ?? false;
                                if (_uppercase ||
                                    _lowercase ||
                                    _numbers ||
                                    _symbols) {
                                  _generate();
                                }
                              });
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    CheckboxListTile(
                      dense: true,
                      title: const Text('Symbols (!@#\$%^&*)'),
                      subtitle: const Text('Include special characters'),
                      value: _symbols,
                      onChanged: _uppercase || _lowercase || _numbers
                          ? (value) {
                              sessionManager.recordActivity();
                              setState(() {
                                _symbols = value ?? false;
                                if (_uppercase ||
                                    _lowercase ||
                                    _numbers ||
                                    _symbols) {
                                  _generate();
                                }
                              });
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    CheckboxListTile(
                      dense: true,
                      title: const Text('Exclude Ambiguous Characters'),
                      subtitle: const Text('Remove il1Lo0O for clarity'),
                      value: _excludeAmbiguous,
                      onChanged: (value) {
                        sessionManager.recordActivity();
                        setState(() {
                          _excludeAmbiguous = value ?? false;
                          _generate();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: colors.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colors.onSecondaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Passphrases are easier to remember and still very secure! Perfect for social media accounts.',
                          style: TextStyle(
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Tips card
            Card(
              elevation: 0,
              color: colors.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: colors.onTertiaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pro Tips',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: colors.onTertiaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      'Use different passwords for each account',
                      colors.onTertiaryContainer,
                    ),
                    _buildTip(
                      'Copy and paste directly into your social media sign-up',
                      colors.onTertiaryContainer,
                    ),
                    _buildTip(
                      'Save generated passwords to your vault for easy access',
                      colors.onTertiaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: color.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

