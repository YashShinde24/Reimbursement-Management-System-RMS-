import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/glass_card.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1A1A3E), const Color(0xFF0F0F23)]
              : [const Color(0xFFEEEBFF), const Color(0xFFF5F7FA)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Manage Users',
                        style: Theme.of(context).textTheme.headlineLarge),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateUserDialog(context, auth),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Add User'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: users.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : users.users.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey.withValues(alpha: 0.4)),
                              const SizedBox(height: 16),
                              Text('No users yet',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge),
                              const SizedBox(height: 8),
                              Text('Add employees and managers',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: users.users.length,
                          itemBuilder: (ctx, i) {
                            final user = users.users[i];
                            final manager = user.managerId != null
                                ? users.getUserById(user.managerId!)
                                : null;

                            return GlassCard(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        _getRoleColor(user.role)
                                            .withValues(alpha: 0.15),
                                    child: Text(
                                      user.name[0].toUpperCase(),
                                      style: TextStyle(
                                        color: _getRoleColor(user.role),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(user.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium),
                                        Text(user.email,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall),
                                        if (manager != null)
                                          Text(
                                            'Manager: ${manager.name}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                    color:
                                                        AppTheme.primaryColor),
                                          ),
                                      ],
                                    ),
                                  ),
                                  _buildRoleChip(context, user.role),
                                  if (user.id != auth.currentUser?.id)
                                    PopupMenuButton(
                                      icon: const Icon(Icons.more_vert,
                                          size: 20),
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'role',
                                          child: Row(
                                            children: [
                                              Icon(Icons.swap_horiz, size: 18),
                                              SizedBox(width: 8),
                                              Text('Change Role'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'manager',
                                          child: Row(
                                            children: [
                                              Icon(Icons.supervisor_account,
                                                  size: 18),
                                              SizedBox(width: 8),
                                              Text('Assign Manager'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline,
                                                  size: 18,
                                                  color: AppTheme.errorColor),
                                              SizedBox(width: 8),
                                              Text('Delete',
                                                  style: TextStyle(
                                                      color: AppTheme
                                                          .errorColor)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (v) {
                                        switch (v) {
                                          case 'role':
                                            _showChangeRoleDialog(
                                                context, user.id, user.role);
                                            break;
                                          case 'manager':
                                            _showAssignManagerDialog(
                                                context, user.id, users);
                                            break;
                                          case 'delete':
                                            _confirmDelete(
                                                context, user.id, user.name);
                                            break;
                                        }
                                      },
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(BuildContext context, String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role[0].toUpperCase() + role.substring(1),
        style: TextStyle(
          color: _getRoleColor(role),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppTheme.primaryColor;
      case 'manager':
        return AppTheme.accentColor;
      default:
        return AppTheme.successColor;
    }
  }

  void _showCreateUserDialog(BuildContext context, AuthProvider auth) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = AppConstants.roleEmployee;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(
                        value: 'employee', child: Text('Employee')),
                    DropdownMenuItem(
                        value: 'manager', child: Text('Manager')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => role = v);
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!,
                      style: const TextStyle(color: AppTheme.errorColor)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty ||
                    emailCtrl.text.isEmpty ||
                    passCtrl.text.isEmpty) {
                  setDialogState(() => error = 'All fields required');
                  return;
                }
                final result =
                    await context.read<UserProvider>().createUser(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: passCtrl.text,
                          role: role,
                          companyId: auth.currentCompany!.id,
                        );
                if (result == null) {
                  setDialogState(() => error = 'Email already taken');
                } else {
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangeRoleDialog(
      BuildContext context, String userId, String currentRole) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Employee'),
              leading: Radio<String>(
                value: 'employee',
                groupValue: currentRole,
                onChanged: null,
              ),
              onTap: () async {
                await context
                    .read<UserProvider>()
                    .updateUserRole(userId, 'employee');
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Manager'),
              leading: Radio<String>(
                value: 'manager',
                groupValue: currentRole,
                onChanged: null,
              ),
              onTap: () async {
                await context
                    .read<UserProvider>()
                    .updateUserRole(userId, 'manager');
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignManagerDialog(
      BuildContext context, String userId, UserProvider users) {
    final managers = users.users
        .where((u) =>
            (u.role == 'manager' || u.role == 'admin') &&
            u.id != userId)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Manager'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('No Manager'),
              leading: const Icon(Icons.person_off),
              onTap: () async {
                await context
                    .read<UserProvider>()
                    .updateUserManager(userId, null);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ...managers.map((m) => ListTile(
                  title: Text(m.name),
                  subtitle: Text(m.role),
                  leading: const Icon(Icons.person),
                  onTap: () async {
                    await context
                        .read<UserProvider>()
                        .updateUserManager(userId, m.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              await context.read<UserProvider>().deleteUser(userId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
