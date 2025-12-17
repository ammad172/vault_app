import 'package:flutter/material.dart';
import '../models/vault_entry.dart';
import '../services/vault_service.dart';

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

  void _generatePassword() {
    // Simple placeholder generator – later we can improve
    setState(() {
      _passwordController.text = 'P@ssw0rd!123';
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Email', 'Social', 'Banking', 'Work', 'Other'];

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing == null ? 'Add entry' : 'Edit entry'),
        actions: [
          if (_editing != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () async {
                  // Capture navigator before the async gap
                  final navigator = Navigator.of(context);

                  await VaultService.deleteEntry(_editing!.id);
                  if (!mounted) return;

                  navigator.pop();
                },
              ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                decoration:
                    const InputDecoration(labelText: 'Username / Email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlController,
                decoration:
                    const InputDecoration(labelText: 'Website / URL'),
              ),
              const SizedBox(height: 12),
              DropdownMenu<String>(
                initialSelection: _category,
                label: const Text('Category'),
                dropdownMenuEntries: categories
                    .map(
                      (c) => DropdownMenuEntry<String>(
                        value: c,
                        label: c,
                      ),
                    )
                    .toList(),
                onSelected: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
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
}
