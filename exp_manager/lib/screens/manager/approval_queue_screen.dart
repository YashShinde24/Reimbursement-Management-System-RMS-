import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/approval_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/approval_chain_widget.dart';

class ApprovalQueueScreen extends StatelessWidget {
  const ApprovalQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final approval = context.watch<ApprovalProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final users = context.watch<UserProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userId = auth.currentUser?.id ?? '';
    final pendingSteps = auth.isAdmin
        ? approval.stepRecords.where((s) => s.isPending).toList()
        : approval.getPendingForApprover(userId);

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
                    child: Text('Pending Approvals',
                        style: Theme.of(context).textTheme.headlineLarge),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${pendingSteps.length}',
                        style: const TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: pendingSteps.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_circle_outline, size: 64,
                            color: AppTheme.successColor.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text('All caught up!', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text('No pending approvals', style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: pendingSteps.length,
                      itemBuilder: (ctx, i) {
                        final step = pendingSteps[i];
                        final expense = expenses.getExpenseById(step.expenseId);
                        if (expense == null) return const SizedBox.shrink();
                        final submitter = users.getUserById(expense.submittedById);

                        return GlassCard(
                          onTap: () => _showExpenseDetail(context, step, expense),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row
                              Row(children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                                  child: Text(submitter?.name[0].toUpperCase() ?? '?',
                                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(submitter?.name ?? 'Unknown', style: Theme.of(context).textTheme.titleMedium),
                                    Text(expense.category, style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                )),
                                Text(
                                  '${expense.currencyCode} ${expense.amount.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              Text(expense.description,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(DateFormat('MMM dd, yyyy').format(expense.date),
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 12),

                              // Inline Approve / Reject buttons
                              Row(children: [
                                Expanded(child: SizedBox(height: 40,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.close, size: 18, color: AppTheme.errorColor),
                                    label: const Text('Reject', style: TextStyle(color: AppTheme.errorColor)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.errorColor),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _quickAction(context, step.id, expense.id, AppConstants.statusRejected),
                                  ),
                                )),
                                const SizedBox(width: 10),
                                Expanded(child: SizedBox(height: 40,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.successColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _quickAction(context, step.id, expense.id, AppConstants.statusApproved),
                                  ),
                                )),
                              ]),
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

  /// Quick approve/reject from card
  Future<void> _quickAction(BuildContext context, String stepId, String expenseId, String status) async {
    final approval = context.read<ApprovalProvider>();
    final expenses = context.read<ExpenseProvider>();

    final result = await approval.processApproval(stepId: stepId, status: status);

    if (result != null) {
      await expenses.updateExpenseStatus(expenseId, result);
    } else if (status == AppConstants.statusApproved) {
      await expenses.updateExpenseStatus(expenseId, AppConstants.statusInReview);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == AppConstants.statusApproved ? 'Expense approved!' : 'Expense rejected'),
        backgroundColor: status == AppConstants.statusApproved ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  /// Detail sheet with comments and approval chain
  void _showExpenseDetail(BuildContext context, dynamic step, dynamic expense) {
    final commentCtrl = TextEditingController();
    final users = context.read<UserProvider>();
    final approval = context.read<ApprovalProvider>();
    final allSteps = approval.getStepsForExpense(expense.id);

    final chainSteps = allSteps.map((s) {
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
        initialChildSize: 0.8, minChildSize: 0.5, maxChildSize: 0.95,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: Container(
                width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              )),
              Text(expense.category, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(expense.description, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              _detailRow(context, 'Amount', '${expense.currencyCode} ${expense.amount.toStringAsFixed(2)}'),
              if (expense.convertedAmount != null)
                _detailRow(context, 'Converted', '${expense.convertedCurrencyCode} ${expense.convertedAmount!.toStringAsFixed(2)}'),
              _detailRow(context, 'Date', DateFormat('MMMM dd, yyyy').format(expense.date)),
              if (expense.vendorName != null) _detailRow(context, 'Vendor', expense.vendorName!),

              // Show expense line items
              if (expense.expenseLines.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Line Items', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                ...expense.expenseLines.map<Widget>((l) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Expanded(child: Text(l.description)),
                    Text(l.amount.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                )),
              ],

              if (chainSteps.isNotEmpty) ...[
                const SizedBox(height: 20),
                ApprovalChainWidget(steps: chainSteps),
              ],
              const SizedBox(height: 20),
              TextField(controller: commentCtrl, maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Comments', hintText: 'Add your comments here...')),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: SizedBox(height: 48,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, color: AppTheme.errorColor),
                    label: const Text('Reject', style: TextStyle(color: AppTheme.errorColor)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.errorColor)),
                    onPressed: () => _processApproval(context, step.id, expense.id, AppConstants.statusRejected, commentCtrl.text.trim()),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: SizedBox(height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                    onPressed: () => _processApproval(context, step.id, expense.id, AppConstants.statusApproved, commentCtrl.text.trim()),
                  ),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 100, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
        Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
      ]),
    );
  }

  Future<void> _processApproval(BuildContext context, String stepId, String expenseId, String status, String comments) async {
    final approval = context.read<ApprovalProvider>();
    final expenses = context.read<ExpenseProvider>();

    final result = await approval.processApproval(stepId: stepId, status: status, comments: comments.isEmpty ? null : comments);

    if (result != null) {
      await expenses.updateExpenseStatus(expenseId, result);
    } else if (status == AppConstants.statusApproved) {
      await expenses.updateExpenseStatus(expenseId, AppConstants.statusInReview);
    }

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == AppConstants.statusApproved ? 'Expense approved!' : 'Expense rejected'),
        backgroundColor: status == AppConstants.statusApproved ? AppTheme.successColor : AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }
}
