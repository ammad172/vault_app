import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vault_entry.dart';
import '../services/vault_service.dart';
import '../services/session_manager.dart';
import '../services/password_generator_service.dart';
import '../services/premium_service.dart';
import '../widgets/ad_banner_widget.dart';
import 'add_edit_entry_screen.dart';
import 'settings_screen.dart';
import 'unlock_screen.dart';
import 'password_generator_screen.dart';
import 'password_health_screen.dart';
import 'premium_screen.dart';

class VaultHomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const VaultHomeScreen({super.key});

  @override
  State<VaultHomeScreen> createState() => _VaultHomeScreenState();
}

class _VaultHomeScreenState extends State<VaultHomeScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Listen to session state changes
    sessionManager.addListener(_onSessionStateChanged);
    // Record activity when screen is shown
    sessionManager.recordActivity();
  }

  @override
  void dispose() {
    sessionManager.removeListener(_onSessionStateChanged);
    super.dispose();
  }

  void _onSessionStateChanged() {
    // If session is locked, navigate to unlock screen
    if (sessionManager.state == SessionState.locked && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        UnlockScreen.routeName,
        (_) => false,
      );
    }
  }

  void _openAdd(BuildContext context) {
    sessionManager.recordActivity();
    Navigator.of(context).pushNamed(AddEditEntryScreen.routeName);
  }

  void _openEdit(BuildContext context, VaultEntry entry) {
    sessionManager.recordActivity();
    Navigator.of(
      context,
    ).pushNamed(AddEditEntryScreen.routeName, arguments: entry);
  }

  List<VaultEntry> _filterEntries(List<VaultEntry> entries) {
    var filtered = entries;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((e) {
        return e.title.toLowerCase().contains(query) ||
            e.username.toLowerCase().contains(query) ||
            e.url.toLowerCase().contains(query) ||
            e.notes.toLowerCase().contains(query);
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filtered = filtered
          .where((e) => e.category == _selectedCategory)
          .toList();
    }

    return filtered;
  }

  void _copyPassword(VaultEntry entry) {
    sessionManager.recordActivity();
    Clipboard.setData(ClipboardData(text: entry.password));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password for "${entry.title}" copied'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final categories = [
      'All',
      'Email',
      'Social',
      'Banking',
      'Work',
      'Shopping',
      'Entertainment',
      'Other',
    ];

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search vault...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  sessionManager.recordActivity();
                  setState(() => _searchQuery = value);
                },
              )
            : const Text('Vault'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            onPressed: () {
              sessionManager.recordActivity();
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.health_and_safety_outlined),
            tooltip: 'Password Health',
            onPressed: () {
              sessionManager.recordActivity();
              Navigator.of(context).pushNamed(PasswordHealthScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              sessionManager.recordActivity();
              Navigator.of(context).pushNamed(SettingsScreen.routeName);
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: VaultService.listenable(),
        builder: (context, box, _) {
          final allEntries = VaultService.getEntriesSnapshot();
          final filteredEntries = _filterEntries(allEntries);

          return Column(
            children: [
              // Quick access to Password Generator
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: InkWell(
                  onTap: () {
                    sessionManager.recordActivity();
                    Navigator.of(context)
                        .pushNamed(PasswordGeneratorScreen.routeName);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.primaryContainer,
                          colors.secondaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password Generator',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create strong passwords for social media',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Category filter chips
              if (allEntries.isNotEmpty)
                SizedBox(
                  height: 60,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    scrollDirection: Axis.horizontal,
                    children: categories.map((category) {
                      final isSelected =
                          _selectedCategory == category ||
                          (_selectedCategory == null && category == 'All');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            sessionManager.recordActivity();
                            setState(() {
                              _selectedCategory = category == 'All'
                                  ? null
                                  : category;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Entry limit info for free tier
              if (!premiumService.isPremium && allEntries.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Card(
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
                              premiumService.getEntryLimitMessage(),
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSecondaryContainer,
                              ),
                            ),
                          ),
                          if (premiumService.currentEntryCount >= PremiumService.freeTierMaxEntries)
                            TextButton(
                              onPressed: () {
                                sessionManager.recordActivity();
                                Navigator.of(context).pushNamed(PremiumScreen.routeName);
                              },
                              child: const Text('Upgrade'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Entries list
              Expanded(
                child: filteredEntries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _searchQuery.isNotEmpty ||
                                        _selectedCategory != null
                                    ? Icons.search_off_rounded
                                    : Icons.lock_open_rounded,
                                size: 64,
                                color: colors.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty ||
                                        _selectedCategory != null
                                    ? 'No matching entries found'
                                    : 'Your vault is empty',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty ||
                                        _selectedCategory != null
                                    ? 'Try adjusting your search or filter'
                                    : 'Tap "Add" to store your first password',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12.0),
                        itemBuilder: (context, index) {
                          final e = filteredEntries[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: colors.primaryContainer,
                                child: Text(
                                  e.title.isNotEmpty
                                      ? e.title[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: colors.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                e.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    e.username.isEmpty
                                        ? 'No username'
                                        : e.username,
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.secondaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          e.category,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colors.onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildPasswordStrengthBadge(e.password),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded),
                                    tooltip: 'Copy password',
                                    onPressed: () => _copyPassword(e),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: colors.outline,
                                  ),
                                ],
                              ),
                              onTap: () {
                                sessionManager.recordActivity();
                                _openEdit(context, e);
                              },
                            ),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemCount: filteredEntries.length,
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ad banner at bottom for free tier
          if (!premiumService.isPremium)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: AdBannerWidget(),
            ),
          FloatingActionButton.extended(
            onPressed: () {
              sessionManager.recordActivity();
              if (!premiumService.canAddEntry()) {
                _showUpgradeDialog(context);
                return;
              }
              _openAdd(context);
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entry Limit Reached'),
        content: Text(
          premiumService.getEntryLimitMessage(),
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

  Widget _buildPasswordStrengthBadge(String password) {
    final strengthResult =
        PasswordGeneratorService.calculateStrength(password);
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (strengthResult.strength) {
      case PasswordStrength.veryStrong:
        badgeColor = Colors.green;
        badgeIcon = Icons.verified_rounded;
        badgeText = 'Very Strong';
        break;
      case PasswordStrength.strong:
        badgeColor = Colors.lightGreen;
        badgeIcon = Icons.check_circle_outline;
        badgeText = 'Strong';
        break;
      case PasswordStrength.fair:
        badgeColor = Colors.orange;
        badgeIcon = Icons.warning_amber_rounded;
        badgeText = 'Fair';
        break;
      case PasswordStrength.weak:
        badgeColor = Colors.orange.shade700;
        badgeIcon = Icons.warning_rounded;
        badgeText = 'Weak';
        break;
      case PasswordStrength.veryWeak:
        badgeColor = Colors.red;
        badgeIcon = Icons.dangerous_rounded;
        badgeText = 'Very Weak';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 10,
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
