import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vault_entry.dart';
import '../services/vault_service.dart';
import '../widgets/password_generator_dialog.dart';
import '../widgets/password_strength_indicator.dart';

class AddEditEntryScreen extends StatefulWidget {
  static const routeName = '/entry';

  const AddEditEntryScreen({super.key});

  @override
  State<AddEditEntryScreen> createState() => _AddEditEntryScreenState();
}

class _AddEditEntryScreenState extends State<AddEditEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  String _category = 'Other';
  bool _obscure = true;
  VaultEntry? _editing;
  bool _initializedFromArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromArgs) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is VaultEntry) {
      _editing = args;
      _titleController.text = args.title;
      _usernameController.text = args.username;
      _passwordController.text = args.password;
      _urlController.text = args.url;
      _notesController.text = args.notes;
      _category = args.category;
    }
    _initializedFromArgs = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState?.validate() != true) return;

    final now = DateTime.now();
    final id =
        _editing?.id ?? DateTime.now().microsecondsSinceEpoch.toString();

    final entry = VaultEntry(
      id: id,
      title: _titleController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      url: _urlController.text.trim(),
      notes: _notesController.text.trim(),
      category: _category,
      createdAt: _editing?.createdAt ?? now,
      updatedAt: now,
    );

    await VaultService.saveEntry(entry);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _generatePassword() async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const PasswordGeneratorDialog(),
    );

    if (password != null) {
      setState(() {
        _passwordController.text = password;
      });
    }
  }

  Future<void> _deleteEntry() async {
    if (_editing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('Are you sure you want to delete "${_editing!.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await VaultService.deleteEntry(_editing!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  void _copyPassword() {
    Clipboard.setData(ClipboardData(text: _passwordController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Email', 'Social', 'Banking', 'Work', 'Shopping', 'Entertainment', 'Other'];
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing == null ? 'Add entry' : 'Edit entry'),
        actions: [
          if (_editing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _deleteEntry,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  helperText: 'e.g., Gmail, Facebook, Amazon',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Username/Email
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username / Email',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password with generator
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                onChanged: (_) => setState(() {}), // Update strength indicator
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_passwordController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.copy_rounded),
                          tooltip: 'Copy',
                          onPressed: _copyPassword,
                        ),
                      IconButton(
                        icon: const Icon(Icons.auto_awesome_rounded),
                        tooltip: 'Generate',
                        onPressed: _generatePassword,
                      ),
                      IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        tooltip: _obscure ? 'Show' : 'Hide',
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Password strength indicator
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                PasswordStrengthIndicator(
                  password: _passwordController.text,
                  showFeedback: true,
                ),
              ],
              
              const SizedBox(height: 16),

              // URL
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Website / URL',
                  helperText: 'e.g., https://www.example.com',
                  prefixIcon: Icon(Icons.language),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownMenu<String>(
                initialSelection: _category,
                label: const Text('Category'),
                leadingIcon: const Icon(Icons.folder_outlined),
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: categories
                    .map(
                      (c) => DropdownMenuEntry<String>(
                        value: c,
                        label: c,
                        leadingIcon: Icon(_getCategoryIcon(c)),
                      ),
                    )
                    .toList(),
                onSelected: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  helperText: 'Additional information (optional)',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 5,
              ),
              const SizedBox(height: 32),

              // Save button
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(_editing == null ? 'Save' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Email':
        return Icons.email_outlined;
      case 'Social':
        return Icons.people_outline;
      case 'Banking':
        return Icons.account_balance_outlined;
      case 'Work':
        return Icons.work_outline;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      case 'Entertainment':
        return Icons.movie_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}
