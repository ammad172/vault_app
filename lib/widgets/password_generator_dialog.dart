import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/password_generator_service.dart';
import '../widgets/password_strength_indicator.dart';

/// Dialog for generating secure passwords
class PasswordGeneratorDialog extends StatefulWidget {
  const PasswordGeneratorDialog({super.key});

  @override
  State<PasswordGeneratorDialog> createState() =>
      _PasswordGeneratorDialogState();
}

class _PasswordGeneratorDialogState extends State<PasswordGeneratorDialog> {
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
    _generate();
  }

  void _generate() {
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
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.psychology_rounded, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Password Generator',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Generated password display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outline.withOpacity(0.2)),
              ),
              child: SelectableText(
                _generatedPassword,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 12),

            // Strength indicator
            PasswordStrengthIndicator(
              password: _generatedPassword,
              showFeedback: true,
            ),
            const SizedBox(height: 24),

            // Password type toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('Random'),
                  icon: Icon(Icons.shuffle),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Passphrase'),
                  icon: Icon(Icons.article_outlined),
                ),
              ],
              selected: {_usePassphrase},
              onSelectionChanged: (Set<bool> selection) {
                setState(() {
                  _usePassphrase = selection.first;
                  _generate();
                });
              },
            ),
            const SizedBox(height: 24),

            if (!_usePassphrase) ...[
              // Length slider
              Row(
                children: [
                  Text('Length: $_length'),
                  Expanded(
                    child: Slider(
                      value: _length.toDouble(),
                      min: 8,
                      max: 64,
                      divisions: 56,
                      onChanged: (value) {
                        setState(() {
                          _length = value.toInt();
                          _generate();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Character type checkboxes
              CheckboxListTile(
                dense: true,
                title: const Text('Uppercase (A-Z)'),
                value: _uppercase,
                onChanged: _lowercase || _numbers || _symbols
                    ? (value) {
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
              CheckboxListTile(
                dense: true,
                title: const Text('Lowercase (a-z)'),
                value: _lowercase,
                onChanged: _uppercase || _numbers || _symbols
                    ? (value) {
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
              CheckboxListTile(
                dense: true,
                title: const Text('Numbers (0-9)'),
                value: _numbers,
                onChanged: _uppercase || _lowercase || _symbols
                    ? (value) {
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
              CheckboxListTile(
                dense: true,
                title: const Text('Symbols (!@#\$%^&*)'),
                value: _symbols,
                onChanged: _uppercase || _lowercase || _numbers
                    ? (value) {
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
              CheckboxListTile(
                dense: true,
                title: const Text('Exclude ambiguous (il1Lo0O)'),
                value: _excludeAmbiguous,
                onChanged: (value) {
                  setState(() {
                    _excludeAmbiguous = value ?? false;
                    _generate();
                  });
                },
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Passphrases are easier to remember and still very secure!',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerate'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      _copyToClipboard();
                      Navigator.pop(context, _generatedPassword);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Use Password'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
