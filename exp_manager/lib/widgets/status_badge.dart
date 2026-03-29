import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double? fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        bgColor = AppTheme.successColor.withValues(alpha: 0.15);
        textColor = AppTheme.successColor;
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        bgColor = AppTheme.errorColor.withValues(alpha: 0.15);
        textColor = AppTheme.errorColor;
        icon = Icons.cancel_outlined;
        break;
      case 'in_review':
        bgColor = Colors.blue.withValues(alpha: 0.15);
        textColor = Colors.blue;
        icon = Icons.hourglass_top;
        break;
      case 'waiting':
        bgColor = Colors.grey.withValues(alpha: 0.15);
        textColor = Colors.grey;
        icon = Icons.schedule;
        break;
      case 'pending':
      default:
        bgColor = AppTheme.warningColor.withValues(alpha: 0.15);
        textColor = AppTheme.warningColor;
        icon = Icons.pending_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: (fontSize ?? 12) + 2, color: textColor),
          const SizedBox(width: 4),
          Text(
            _formatStatus(status),
            style: TextStyle(
              color: textColor,
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'in_review':
        return 'In Review';
      case 'waiting':
        return 'Waiting';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }
}
