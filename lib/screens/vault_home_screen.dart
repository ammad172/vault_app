import 'package:flutter/material.dart';
import '../models/vault_entry.dart';
import '../services/vault_service.dart';
import 'add_edit_entry_screen.dart';
import 'settings_screen.dart';

class VaultHomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const VaultHomeScreen({super.key});

  void _openAdd(BuildContext context) {
    Navigator.of(context).pushNamed(AddEditEntryScreen.routeName);
  }

  void _openEdit(BuildContext context, VaultEntry entry) {
    Navigator.of(context).pushNamed(
      AddEditEntryScreen.routeName,
      arguments: entry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        actions: [
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
          final entries = VaultService.getEntriesSnapshot();

          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Your vault is empty.\nTap “Add” to store your first password.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12.0),
            itemBuilder: (context, index) {
              final e = entries[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      e.title.isNotEmpty ? e.title[0].toUpperCase() : '?',
                      style: TextStyle(color: colors.onPrimaryContainer),
                    ),
                  ),
                  title: Text(e.title),
                  subtitle: Text(
                    '${e.username.isEmpty ? 'No username' : e.username} • ${e.category}',
                  ),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: colors.outline),
                  onTap: () => _openEdit(context, e),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: entries.length,
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
