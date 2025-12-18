import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vault_entry.dart';
import '../services/vault_service.dart';
import 'add_edit_entry_screen.dart';
import 'settings_screen.dart';

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

  void _openAdd(BuildContext context) {
    Navigator.of(context).pushNamed(AddEditEntryScreen.routeName);
  }

  void _openEdit(BuildContext context, VaultEntry entry) {
    Navigator.of(context).pushNamed(
      AddEditEntryScreen.routeName,
      arguments: entry,
    );
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
      filtered = filtered.where((e) => e.category == _selectedCategory).toList();
    }

    return filtered;
  }

  void _copyPassword(VaultEntry entry) {
    Clipboard.setData(ClipboardData(text: entry.password));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password for "${entry.title}" copied'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final categories = ['All', 'Email', 'Social', 'Banking', 'Work', 'Shopping', 'Entertainment', 'Other'];

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
                  setState(() => _searchQuery = value);
                },
              )
            : const Text('Vault'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
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
              // Category filter chips
              if (allEntries.isNotEmpty)
                SizedBox(
                  height: 60,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    scrollDirection: Axis.horizontal,
                    children: categories.map((category) {
                      final isSelected = _selectedCategory == category ||
                          (_selectedCategory == null && category == 'All');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory =
                                  category == 'All' ? null : category;
                            });
                          },
                        ),
                      );
                    }).toList(),
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
                                _searchQuery.isNotEmpty || _selectedCategory != null
                                    ? Icons.search_off_rounded
                                    : Icons.lock_open_rounded,
                                size: 64,
                                color: colors.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty || _selectedCategory != null
                                    ? 'No matching entries found'
                                    : 'Your vault is empty',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty || _selectedCategory != null
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
                                style: const TextStyle(fontWeight: FontWeight.w600),
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
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.secondaryContainer,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          e.category,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colors.onSecondaryContainer,
                                          ),
                                        ),
                                      ),
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
                                  Icon(Icons.chevron_right_rounded,
                                      color: colors.outline),
                                ],
                              ),
                              onTap: () => _openEdit(context, e),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: filteredEntries.length,
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
    );
  }
}
