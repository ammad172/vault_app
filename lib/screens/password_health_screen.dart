import 'package:flutter/material.dart';
import '../models/vault_entry.dart';
import '../services/vault_service.dart';
import '../services/password_generator_service.dart';
import '../services/session_manager.dart';
import '../services/premium_service.dart';
import 'add_edit_entry_screen.dart';
import 'premium_screen.dart';

/// Screen showing password health audit - identifies weak, duplicate, and compromised passwords
class PasswordHealthScreen extends StatefulWidget {
  static const routeName = '/password-health';

  const PasswordHealthScreen({super.key});

  @override
  State<PasswordHealthScreen> createState() => _PasswordHealthScreenState();
}

class _PasswordHealthScreenState extends State<PasswordHealthScreen> {
  List<VaultEntry> _allEntries = [];
  Map<String, List<VaultEntry>> _duplicatePasswords = {};
  List<VaultEntry> _weakPasswords = [];
  List<VaultEntry> _veryWeakPasswords = [];
  int _totalEntries = 0;
  int _strongPasswords = 0;
  double _averageStrength = 0.0;

  @override
  void initState() {
    super.initState();
    sessionManager.recordActivity();
    _analyzePasswords();
  }

  void _analyzePasswords() {
    _allEntries = VaultService.getEntriesSnapshot();
    _totalEntries = _allEntries.length;

    if (_totalEntries == 0) return;

    _duplicatePasswords = {};
    _weakPasswords = [];
    _veryWeakPasswords = [];
    _strongPasswords = 0;
    double totalStrength = 0.0;

    // Group passwords by value to find duplicates
    final passwordMap = <String, List<VaultEntry>>{};
    for (final entry in _allEntries) {
      passwordMap.putIfAbsent(entry.password, () => []).add(entry);
    }

    // Find duplicates
    passwordMap.forEach((password, entries) {
      if (entries.length > 1) {
        _duplicatePasswords[password] = entries;
      }
    });

    // Analyze strength
    for (final entry in _allEntries) {
      final strengthResult =
          PasswordGeneratorService.calculateStrength(entry.password);
      totalStrength += strengthResult.score;

      if (strengthResult.strength == PasswordStrength.veryStrong ||
          strengthResult.strength == PasswordStrength.strong) {
        _strongPasswords++;
      } else if (strengthResult.strength == PasswordStrength.veryWeak) {
        _veryWeakPasswords.add(entry);
      } else if (strengthResult.strength == PasswordStrength.weak ||
          strengthResult.strength == PasswordStrength.fair) {
        _weakPasswords.add(entry);
      }
    }

    _averageStrength = totalStrength / _totalEntries;

    setState(() {});
  }

  int get _duplicateCount {
    return _duplicatePasswords.values
        .fold(0, (sum, entries) => sum + entries.length);
  }

  int get _issuesCount {
    return _veryWeakPasswords.length +
        _weakPasswords.length +
        _duplicateCount;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Show upgrade prompt for free tier
    if (!premiumService.canUseAdvancedHealth() && _totalEntries > 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Password Health')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 64, color: colors.primary),
                const SizedBox(height: 16),
                Text(
                  'Advanced Health Audit',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Get detailed password analysis, duplicate detection, and security recommendations with Premium.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(PremiumScreen.routeName);
                  },
                  child: const Text('Upgrade to Premium'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_totalEntries == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Password Health')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.health_and_safety_outlined,
                  size: 64, color: colors.outline),
              const SizedBox(height: 16),
              Text(
                'No passwords to analyze',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Add some passwords to your vault first',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final healthScore = ((_strongPasswords / _totalEntries) * 100).round();
    final healthColor = healthScore >= 80
        ? Colors.green
        : healthScore >= 60
            ? Colors.lightGreen
            : healthScore >= 40
                ? Colors.orange
                : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh analysis',
            onPressed: () {
              sessionManager.recordActivity();
              _analyzePasswords();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _analyzePasswords();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Overall Health Score Card
            Card(
              elevation: 0,
              color: healthColor.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.health_and_safety_rounded,
                          size: 48,
                          color: healthColor,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Health Score',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              '$healthScore%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: healthColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: healthScore / 100,
                      backgroundColor: colors.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getHealthMessage(healthScore),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Passwords',
                    '$_totalEntries',
                    Icons.lock_outline,
                    colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Strong',
                    '$_strongPasswords',
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Issues Found',
                    '$_issuesCount',
                    Icons.warning_outlined,
                    _issuesCount > 0 ? Colors.orange : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Avg Strength',
                    '${(_averageStrength * 100).toStringAsFixed(0)}%',
                    Icons.analytics_outlined,
                    colors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Issues Section
            if (_issuesCount > 0) ...[
              Text(
                'Security Issues',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              // Very Weak Passwords
              if (_veryWeakPasswords.isNotEmpty) ...[
                _buildIssueSection(
                  context,
                  'Very Weak Passwords',
                  _veryWeakPasswords.length,
                  Colors.red,
                  Icons.dangerous_rounded,
                  _veryWeakPasswords,
                ),
                const SizedBox(height: 12),
              ],

              // Weak Passwords
              if (_weakPasswords.isNotEmpty) ...[
                _buildIssueSection(
                  context,
                  'Weak Passwords',
                  _weakPasswords.length,
                  Colors.orange,
                  Icons.warning_rounded,
                  _weakPasswords,
                ),
                const SizedBox(height: 12),
              ],

              // Duplicate Passwords
              if (_duplicatePasswords.isNotEmpty) ...[
                _buildDuplicateSection(context),
                const SizedBox(height: 12),
              ],
            ] else ...[
              Card(
                elevation: 0,
                color: Colors.green.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Good!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All your passwords are strong and unique',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueSection(
    BuildContext context,
    String title,
    int count,
    Color color,
    IconData icon,
    List<VaultEntry> entries,
  ) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text('$count password${count > 1 ? 's' : ''} need attention'),
        children: entries.map((entry) {
          final strengthResult =
              PasswordGeneratorService.calculateStrength(entry.password);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              child: Text(
                entry.title.isNotEmpty ? entry.title[0].toUpperCase() : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(entry.title),
            subtitle: Text(
              'Strength: ${strengthResult.feedback}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                sessionManager.recordActivity();
                Navigator.of(context).pushNamed(
                  AddEditEntryScreen.routeName,
                  arguments: entry,
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDuplicateSection(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.orange.withValues(alpha: 0.1),
      child: ExpansionTile(
        leading: const Icon(Icons.copy_all_rounded, color: Colors.orange),
        title: const Text('Duplicate Passwords'),
        subtitle: Text(
          '${_duplicatePasswords.length} password${_duplicatePasswords.length > 1 ? 's' : ''} used multiple times',
        ),
        children: _duplicatePasswords.entries.map((entry) {
          final password = entry.key;
          final entries = entry.value;
          return ExpansionTile(
            leading: const Icon(Icons.lock, size: 20),
            title: Text(
              'Used ${entries.length} time${entries.length > 1 ? 's' : ''}',
            ),
            subtitle: Text(
              'Password: ${password.substring(0, password.length > 10 ? 10 : password.length)}${password.length > 10 ? '...' : ''}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            children: entries.map((e) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  child: Text(
                    e.title.isNotEmpty ? e.title[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(e.title),
                subtitle: Text(e.category),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    sessionManager.recordActivity();
                    Navigator.of(context).pushNamed(
                      AddEditEntryScreen.routeName,
                      arguments: e,
                    );
                  },
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  String _getHealthMessage(int score) {
    if (score >= 90) {
      return 'Excellent! Your passwords are very secure';
    } else if (score >= 80) {
      return 'Good! Most passwords are strong';
    } else if (score >= 60) {
      return 'Fair. Consider strengthening weak passwords';
    } else if (score >= 40) {
      return 'Needs improvement. Many weak passwords detected';
    } else {
      return 'Critical! Many passwords need immediate attention';
    }
  }
}

