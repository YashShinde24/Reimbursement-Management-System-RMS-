import 'package:flutter/material.dart';
import '../utils/theme.dart';

class ApprovalChainWidget extends StatelessWidget {
  final List<ApprovalChainStep> steps;

  const ApprovalChainWidget({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Approval Chain',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...List.generate(steps.length, (i) {
          final step = steps[i];
          final isLast = i == steps.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    _buildStepIndicator(step.status),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: _getLineColor(step.status),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              step.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            _buildStatusChip(step.status),
                          ],
                        ),
                        Text(
                          step.approverName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (step.comments != null &&
                            step.comments!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '"${step.comments}"',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStepIndicator(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'approved':
        color = AppTheme.successColor;
        icon = Icons.check;
        break;
      case 'rejected':
        color = AppTheme.errorColor;
        icon = Icons.close;
        break;
      case 'pending':
        color = AppTheme.warningColor;
        icon = Icons.hourglass_bottom;
        break;
      default:
        color = Colors.grey;
        icon = Icons.circle_outlined;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Color _getLineColor(String status) {
    switch (status) {
      case 'approved':
        return AppTheme.successColor.withValues(alpha: 0.3);
      case 'rejected':
        return AppTheme.errorColor.withValues(alpha: 0.3);
      default:
        return Colors.grey.withValues(alpha: 0.3);
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'approved':
        color = AppTheme.successColor;
        label = 'Approved';
        break;
      case 'rejected':
        color = AppTheme.errorColor;
        label = 'Rejected';
        break;
      case 'pending':
        color = AppTheme.warningColor;
        label = 'Pending';
        break;
      default:
        color = Colors.grey;
        label = 'Waiting';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ApprovalChainStep {
  final String label;
  final String approverName;
  final String status;
  final String? comments;

  ApprovalChainStep({
    required this.label,
    required this.approverName,
    required this.status,
    this.comments,
  });
}
