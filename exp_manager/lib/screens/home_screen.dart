import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../providers/approval_provider.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../widgets/glass_card.dart';
import 'admin/manage_users_screen.dart';
import 'admin/approval_config_screen.dart';
import 'employee/submit_expense_screen.dart';
import 'employee/expense_history_screen.dart';
import 'manager/approval_queue_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    }
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (auth.currentCompany != null) {
      final companyId = auth.currentCompany!.id;
      context.read<UserProvider>().loadUsers(companyId);
      context.read<ExpenseProvider>().loadExpenses(companyId);
      context.read<ApprovalProvider>().loadApprovalFlow(companyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pages = _getPages(auth);
    final navItems = _getNavItems(auth);

    // Clamp index to valid range
    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: navItems,
        ),
      ),
    );
  }

  List<Widget> _getPages(AuthProvider auth) {
    if (auth.isAdmin) {
      return [
        _AdminDashboard(),
        const ManageUsersScreen(),
        const ExpenseHistoryScreen(),
        const ApprovalQueueScreen(),
        const ApprovalConfigScreen(),
      ];
    } else if (auth.isManager) {
      return [
        _ManagerDashboard(),
        const ApprovalQueueScreen(),
        const ExpenseHistoryScreen(),
      ];
    } else {
      return [
        _EmployeeDashboard(),
        const SubmitExpenseScreen(),
        const ExpenseHistoryScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems(AuthProvider auth) {
    if (auth.isAdmin) {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Users'),
        BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.approval_outlined), activeIcon: Icon(Icons.approval), label: 'Approvals'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Config'),
      ];
    } else if (auth.isManager) {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.approval_outlined), activeIcon: Icon(Icons.approval), label: 'Approvals'),
        BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), activeIcon: Icon(Icons.add_circle), label: 'Submit'),
        BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
      ];
    }
  }
}

// -- Dashboard Widgets --

class _AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final users = context.watch<UserProvider>();

    return _DashboardScaffold(
      title: 'Admin Dashboard',
      subtitle: auth.currentCompany?.name ?? '',
      children: [
        _buildStatsRow(context, expenses, users),
        const SizedBox(height: 20),
        _buildRecentExpenses(context, expenses),
      ],
    );
  }

  Widget _buildStatsRow(
      BuildContext context, ExpenseProvider exp, UserProvider users) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.people,
            label: 'Users',
            value: '${users.users.length}',
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.pending_actions,
            label: 'Pending',
            value: '${exp.pendingCount}',
            color: AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle,
            label: 'Approved',
            value: '${exp.approvedCount}',
            color: AppTheme.successColor,
          ),
        ),
      ],
    );
  }



  Widget _buildRecentExpenses(BuildContext context, ExpenseProvider exp) {
    final recent = exp.expenses.take(5).toList();
    if (recent.isEmpty) {
      return GlassCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(Icons.receipt_long,
                    size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('No expenses yet',
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Expenses',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        ...recent.map((e) => GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt,
                        color: AppTheme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.category,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(e.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (e.approvedByName != null && e.status != AppConstants.statusPending)
                          Text('${e.status == AppConstants.statusApproved ? 'Approved' : 'Rejected'} by: ${e.approvedByName}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7)
                              )),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${e.currencyCode} ${e.amount.toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      _buildStatusDot(e.status),
                    ],
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildStatusDot(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = AppTheme.successColor;
        break;
      case 'rejected':
        color = AppTheme.errorColor;
        break;
      default:
        color = AppTheme.warningColor;
    }
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ManagerDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final users = context.watch<UserProvider>();
    final pendingExpenses = expenses.expenses
        .where((e) =>
            e.status == AppConstants.statusPending ||
            e.status == AppConstants.statusInReview)
        .toList();

    return _DashboardScaffold(
      title: 'Manager Dashboard',
      subtitle: auth.currentUser?.name ?? '',
      children: [
        // Stats row
        Row(children: [
          Expanded(child: _StatCard(
            icon: Icons.pending_actions,
            label: 'Pending',
            value: '${pendingExpenses.length}',
            color: AppTheme.warningColor,
          )),
        ]),
        const SizedBox(height: 20),
        // Pending expenses heading
        Text('Employee Expenses to Review',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (pendingExpenses.isEmpty)
          GlassCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Icon(Icons.check_circle_outline, size: 48,
                      color: AppTheme.successColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('All caught up!',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 4),
                  Text('No pending approvals',
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ),
          )
        else
          ...pendingExpenses.map((expense) {
            final submitter = users.getUserById(expense.submittedById);
            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                      child: Text(
                        submitter?.name[0].toUpperCase() ?? '?',
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(submitter?.name ?? 'Unknown',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(expense.category,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    )),
                    Text(
                      '${expense.currencyCode} ${expense.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(expense.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  // Approve / Reject buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.errorColor),
                          foregroundColor: AppTheme.errorColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _processApproval(
                            context, expense.id, AppConstants.statusRejected),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _processApproval(
                            context, expense.id, AppConstants.statusApproved),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Future<void> _processApproval(
      BuildContext context, String expenseId, String status) async {
    final expenses = context.read<ExpenseProvider>();
    final auth = context.read<AuthProvider>();

    final user = auth.currentUser;
    if (user == null) return;

    await expenses.updateExpenseStatus(
      expenseId,
      status,
      managerId: user.id,
      managerName: user.name,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == AppConstants.statusApproved
            ? 'Expense approved!' : 'Expense rejected'),
        backgroundColor: status == AppConstants.statusApproved
            ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }
}

class _EmployeeDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final userId = auth.currentUser?.id ?? '';
    final myExpenses = expenses.getExpensesByUser(userId);
    final pending =
        myExpenses.where((e) => e.status == 'pending' || e.status == 'in_review').length;
    final approved =
        myExpenses.where((e) => e.status == 'approved').length;
    final rejected =
        myExpenses.where((e) => e.status == 'rejected').length;

    return _DashboardScaffold(
      title: 'My Dashboard',
      subtitle: auth.currentUser?.name ?? '',
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.receipt_long,
                label: 'Total',
                value: '${myExpenses.length}',
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.pending,
                label: 'Pending',
                value: '$pending',
                color: AppTheme.warningColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle,
                label: 'Approved',
                value: '$approved',
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.cancel,
                label: 'Rejected',
                value: '$rejected',
                color: AppTheme.errorColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _DashboardScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style:
                                  Theme.of(context).textTheme.headlineLarge),
                          const SizedBox(height: 4),
                          Text(subtitle,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        context.read<AuthProvider>().logout();
                      },
                      icon: const Icon(Icons.logout_rounded),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate(children),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
