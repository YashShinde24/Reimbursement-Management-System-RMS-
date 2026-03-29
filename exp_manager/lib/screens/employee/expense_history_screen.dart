import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/approval_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/approval_chain_widget.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<dynamic> filtered;
    if (auth.isAdmin) {
      filtered = _filterExpenses(expenses.expenses);
    } else if (auth.isManager) {
      filtered = _filterExpenses(expenses.expenses.where((e) =>
          e.submittedById == auth.currentUser!.id ||
          e.approvedById == auth.currentUser!.id).toList());
    } else {
      filtered = _filterExpenses(
          expenses.getExpensesByUser(auth.currentUser!.id));
    }

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
              child: Text('Expense History',
                  style: Theme.of(context).textTheme.headlineLarge),
            ),
            const SizedBox(height: 12),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['all', 'pending', 'approved', 'rejected']
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f[0].toUpperCase() + f.substring(1)),
                            selected: _filter == f,
                            onSelected: (_) =>
                                setState(() => _filter = f),
                            selectedColor:
                                AppTheme.primaryColor.withValues(alpha: 0.2),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final exp = filtered[i];
                        return _buildExpenseCard(context, exp);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> _filterExpenses(List<dynamic> exps) {
    if (_filter == 'all') return exps;
    return exps.where((e) => e.status == _filter).toList();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long, size: 64,
              color: Colors.grey.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No expenses found',
              style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, dynamic exp) {
    final auth = context.read<AuthProvider>();
    final companyCurrency = auth.currentCompany?.currencySymbol ?? '';

    return GlassCard(
      onTap: () => _showExpenseDetail(context, exp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getCategoryIcon(exp.category),
                    color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exp.category, style: Theme.of(context).textTheme.titleMedium),
                    Text(DateFormat('MMM dd, yyyy').format(exp.date),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${exp.currencyCode} ${exp.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  if (exp.convertedAmount != null)
                    Text('$companyCurrency${exp.convertedAmount!.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppTheme.accentColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exp.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (exp.approvedByName != null && exp.status != AppConstants.statusPending)
                    Text('${exp.status == AppConstants.statusApproved ? 'Approved' : 'Rejected'} by: ${exp.approvedByName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                ],
              )),
              StatusBadge(status: exp.status),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Travel': return Icons.flight;
      case 'Food & Dining': return Icons.restaurant;
      case 'Accommodation': return Icons.hotel;
      case 'Transportation': return Icons.directions_car;
      case 'Office Supplies': return Icons.print;
      case 'Software & Tools': return Icons.computer;
      case 'Medical': return Icons.medical_services;
      default: return Icons.receipt;
    }
  }

  void _showExpenseDetail(BuildContext context, dynamic exp) {
    final users = context.read<UserProvider>();
    final approval = context.read<ApprovalProvider>();
    final steps = approval.getStepsForExpense(exp.id);

    final chainSteps = steps.map((s) {
      final approver = users.getUserById(s.approverId);
      return ApprovalChainStep(
        label: 'Step ${s.sequence}',
        approverName: approver?.name ?? 'Unknown',
        status: s.status,
        comments: s.comments,
      );
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(exp.category, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              StatusBadge(status: exp.status, fontSize: 14),
              const SizedBox(height: 16),
              _detailRow(context, 'Amount', '${exp.currencyCode} ${exp.amount.toStringAsFixed(2)}'),
              if (exp.convertedAmount != null)
                _detailRow(context, 'Converted', '${exp.convertedCurrencyCode} ${exp.convertedAmount!.toStringAsFixed(2)}'),
              _detailRow(context, 'Date', DateFormat('MMMM dd, yyyy').format(exp.date)),
              _detailRow(context, 'Description', exp.description),
              if (exp.vendorName != null) _detailRow(context, 'Vendor', exp.vendorName!),
              if (exp.approvedByName != null && exp.status != AppConstants.statusPending)
                _detailRow(context, exp.status == AppConstants.statusApproved ? 'Approved By' : 'Rejected By', exp.approvedByName!),
              if (exp.expenseLines.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Line Items', style: Theme.of(context).textTheme.titleLarge),
                ...exp.expenseLines.map<Widget>((l) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l.description),
                      Text(l.amount.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )),
              ],
              if (chainSteps.isNotEmpty) ...[
                const SizedBox(height: 20),
                ApprovalChainWidget(steps: chainSteps),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
