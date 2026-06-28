import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';

class UserFormScreen extends StatefulWidget {
  const UserFormScreen({super.key});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  PosUser? _existingUser;
  bool _isEditing = false;
  String _selectedRole = 'cashier';
  String? _selectedBranchId;
  bool _isSaving = false;
  List<Map<String, dynamic>> _branches = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is PosUser) {
        _existingUser = args;
        _isEditing = true;
        _nameController.text = args.name;
        _emailController.text = args.email;
        _selectedRole = args.role;
        _selectedBranchId = args.branchId;
        setState(() {});
      }
      _loadBranches();
    });
  }

  Future<void> _loadBranches() async {
    final branches = await context.read<UserProvider>().getBranches();
    if (mounted) {
      setState(() => _branches = branches);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final userProv = context.read<UserProvider>();
    bool success;

    if (_isEditing && _existingUser != null) {
      final updated = _existingUser!.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _selectedRole,
        branchId: _selectedRole == 'cashier' ? _selectedBranchId : null,
      );
      success = await userProv.updateUser(updated);
    } else {
      final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final newUser = PosUser(
        id: id,
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        role: _selectedRole,
        branchId: _selectedRole == 'cashier' ? _selectedBranchId : null,
      );
      success = await userProv.createUser(newUser);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditing ? 'User berhasil diperbarui' : 'User berhasil dibuat'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProv.error ?? 'Gagal menyimpan user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit User' : 'Tambah User'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar section
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    _selectedRole == 'owner'
                        ? Icons.admin_panel_settings
                        : Icons.person,
                    size: 40,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  hintText: 'Masukkan nama user',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nama harus diisi' : null,
              ),
              const SizedBox(height: 16),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'user@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email harus diisi';
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Role dropdown
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'cashier',
                    child: Text('Kasir'),
                  ),
                  DropdownMenuItem(
                    value: 'owner',
                    child: Text('Owner'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedRole = v);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Branch dropdown (only for cashier)
              if (_selectedRole == 'cashier') ...[
                DropdownButtonFormField<String>(
                  value: _selectedBranchId,
                  decoration: const InputDecoration(
                    labelText: 'Cabang',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                  hint: const Text('Pilih cabang'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua Cabang'),
                    ),
                    ..._branches.map((b) => DropdownMenuItem(
                          value: b['id'] as String,
                          child: Text(b['name'] as String),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedBranchId = v);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Info card for owner role
              if (_selectedRole == 'owner')
                Card(
                  color: colorScheme.tertiaryContainer.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: colorScheme.tertiary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Owner memiliki akses ke seluruh cabang dan pengaturan sistem.',
                            style: TextStyle(
                                color: colorScheme.onTertiaryContainer,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Save button
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(_isEditing ? Icons.save : Icons.person_add),
                label: Text(
                  _isSaving
                      ? 'Menyimpan...'
                      : (_isEditing ? 'Simpan Perubahan' : 'Tambah User'),
                  style: const TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
