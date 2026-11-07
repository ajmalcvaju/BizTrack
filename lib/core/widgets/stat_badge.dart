import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class StatBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final bool isSmall;

  const StatBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.isSmall = false,
  });

  factory StatBadge.forLeadStatus(String status) {
    Color bg;
    IconData ic;
    switch (status) {
      case AppConstants.leadStatusInterested:
        bg = AppColors.teal;
        ic = Icons.star_rounded;
        break;
      case AppConstants.leadStatusDNP:
        bg = AppColors.warning;
        ic = Icons.phone_missed_rounded;
        break;
      case AppConstants.leadStatusFollowUp:
      default:
        bg = AppColors.primary;
        ic = Icons.event_repeat_rounded;
        break;
    }
    return StatBadge(label: status, color: bg, icon: ic);
  }

  factory StatBadge.forWorkStatus(String status) {
    Color bg;
    IconData ic;
    switch (status) {
      case AppConstants.workStatusCompleted:
        bg = AppColors.success;
        ic = Icons.check_circle_outline_rounded;
        break;
      case AppConstants.workStatusInProgress:
        bg = AppColors.primary;
        ic = Icons.timelapse_rounded;
        break;
      case AppConstants.workStatusInReview:
        bg = AppColors.purple;
        ic = Icons.rate_review_outlined;
        break;
      case AppConstants.workStatusOnHold:
        bg = AppColors.warning;
        ic = Icons.pause_circle_outline_rounded;
        break;
      case AppConstants.workStatusCancelled:
        bg = AppColors.danger;
        ic = Icons.cancel_outlined;
        break;
      case AppConstants.workStatusNotStarted:
      default:
        bg = Colors.grey;
        ic = Icons.fiber_new_rounded;
        break;
    }
    return StatBadge(label: status, color: bg, icon: ic);
  }

  factory StatBadge.forPriority(String priority) {
    Color bg;
    IconData ic;
    switch (priority) {
      case AppConstants.priorityHigh:
        bg = AppColors.danger;
        ic = Icons.priority_high_rounded;
        break;
      case AppConstants.priorityMedium:
        bg = AppColors.warning;
        ic = Icons.remove_rounded;
        break;
      case AppConstants.priorityLow:
      default:
        bg = AppColors.teal;
        ic = Icons.arrow_downward_rounded;
        break;
    }
    return StatBadge(label: priority, color: bg, icon: ic, isSmall: true);
  }

  factory StatBadge.overdue() {
    return const StatBadge(
      label: 'OVERDUE',
      color: AppColors.danger,
      icon: Icons.error_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: effectiveColor.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: isSmall ? 12 : 14,
              color: effectiveColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
