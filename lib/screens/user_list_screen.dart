import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../utils/responsive.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers();
    });
  }

  Future<void> _deleteUser(PosUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.red),
        title: const Text('Hapus User'),
        content: Text('Yakin ingin menghapus user "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<UserProvider>().deleteUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'User berhasil dihapus' : 'Gagal menghapus user'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTablet = context.isTablet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => userProv.loadUsers(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(userProv, auth, theme, colorScheme, isTablet),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_user',
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/user-form');
          if (result == true && mounted) {
            userProv.loadUsers();
          }
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildBody(UserProvider userProv, AuthProvider auth, ThemeData theme,
      ColorScheme colorScheme, bool isTablet) {
    if (userProv.isLoading) {
      return const ShimmerPage(itemCount: 6);
    }

    if (userProv.error != null) {
      return ErrorStateWidget(
        message: userProv.error!,
        title: 'Gagal memuat users',
        onRetry: () => userProv.loadUsers(),
      );
    }

    if (userProv.users.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.people_outline,
        title: 'Belum ada user',
        subtitle: 'Tambahkan user pertama untuk mulai',
      );
    }

    return RefreshIndicator(
      onRefresh: () => userProv.loadUsers(),
      child: isTablet
          ? _buildTabletGrid(userProv, auth, colorScheme)
          : _buildList(userProv, auth, colorScheme),
    );
  }

  Widget _buildList(
      UserProvider userProv, AuthProvider auth, ColorScheme colorScheme) {
    return ListView.builder(
      itemCount: userProv.users.length,
      itemBuilder: (context, index) {
        final user = userProv.users[index];
        return _buildUserTile(user, auth, colorScheme);
      },
    );
  }

  Widget _buildTabletGrid(
      UserProvider userProv, AuthProvider auth, ColorScheme colorScheme) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: userProv.users.length,
      itemBuilder: (context, index) {
        final user = userProv.users[index];
        return _buildUserCard(user, auth, colorScheme);
      },
    );
  }

  Widget _buildUserTile(PosUser user, AuthProvider auth, ColorScheme colorScheme) {
    final isOwner = user.role == 'owner';
    final isSelf = user.id == auth.userId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOwner
              ? colorScheme.tertiaryContainer
              : colorScheme.primaryContainer,
          child: Icon(
            isOwner ? Icons.admin_panel_settings : Icons.person,
            color: isOwner
                ? colorScheme.onTertiaryContainer
                : colorScheme.onPrimaryContainer,
          ),
        ),
        title: Row(
          children: [
            Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (isSelf) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Saya',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Text(user.email, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isOwner ? colorScheme.tertiaryContainer : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isOwner ? 'Owner' : 'Kasir',
                style: TextStyle(
                  fontSize: 10,
                  color: isOwner ? colorScheme.onTertiaryContainer : colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              final result = await Navigator.pushNamed(
                context,
                '/user-form',
                arguments: user,
              );
              if (result == true && mounted) {
                context.read<UserProvider>().loadUsers();
              }
            } else if (value == 'delete') {
              _deleteUser(user);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: ListTile(
              leading: Icon(Icons.edit, size: 20),
              title: Text('Edit'),
              dense: true,
            )),
            const PopupMenuItem(value: 'delete', child: ListTile(
              leading: Icon(Icons.delete, size: 20, color: Colors.red),
              title: Text('Hapus', style: TextStyle(color: Colors.red)),
              dense: true,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(PosUser user, AuthProvider auth, ColorScheme colorScheme) {
    final isOwner = user.role == 'owner';
    final isSelf = user.id == auth.userId;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            '/user-form',
            arguments: user,
          );
          if (result == true && mounted) {
            context.read<UserProvider>().loadUsers();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isOwner
                    ? colorScheme.tertiaryContainer
                    : colorScheme.primaryContainer,
                child: Icon(
                  isOwner ? Icons.admin_panel_settings : Icons.person,
                  size: 28,
                  color: isOwner
                      ? colorScheme.onTertiaryContainer
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(user.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Saya',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(user.email,
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isOwner
                            ? colorScheme.tertiaryContainer
                            : colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOwner ? 'Owner' : 'Kasir',
                        style: TextStyle(
                          fontSize: 11,
                          color: isOwner
                              ? colorScheme.onTertiaryContainer
                              : colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
