import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../leads/providers/leads_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../payments/providers/payments_provider.dart';
import '../../day_planner/providers/tasks_provider.dart';

class DashboardData {
  final int totalActiveLeads;
  final int leadsRequiringFollowUpToday;
  final int totalCustomers;
  final int totalOutstandingPaise;
  final int monthlyCollectionTargetPaise;
  final int amountCollectedThisMonthPaise;
  final double collectionProgressRatio;
  final int pendingExpensesPaise;
  final int todayPendingTasks;
  final int cashBalancePaise;
  final int bankBalancePaise;
  final int fatherBalancePaise;
  final int totalLiquidBalancePaise;
  final List<DashboardActivityItem> recentActivities;

  const DashboardData({
    required this.totalActiveLeads,
    required this.leadsRequiringFollowUpToday,
    required this.totalCustomers,
    required this.totalOutstandingPaise,
    required this.monthlyCollectionTargetPaise,
    required this.amountCollectedThisMonthPaise,
    required this.collectionProgressRatio,
    required this.pendingExpensesPaise,
    required this.todayPendingTasks,
    required this.cashBalancePaise,
    required this.bankBalancePaise,
    required this.fatherBalancePaise,
    required this.totalLiquidBalancePaise,
    required this.recentActivities,
  });
}

enum ActivityType { lead, payment, expense, task }

class DashboardActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final ActivityType type;
  final Color color;
  final IconData icon;

  const DashboardActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
    required this.color,
    required this.icon,
  });
}

final dashboardProvider = Provider<DashboardData>((ref) {
  final leads = ref.watch(leadsProvider);
  final customers = ref.watch(customersProvider);
  final payments = ref.watch(paymentsProvider);
  final tasks = ref.watch(tasksProvider);
  final summary = ref.watch(financialSummaryProvider);

  // Targets
  final currentTarget = payments.currentMonthTarget;
  final targetPaise = currentTarget?.targetAmount ?? 0;
  final collectedPaise = summary.thisMonthCollectedPaise;
  final progressRatio = targetPaise > 0
      ? (collectedPaise / targetPaise).clamp(0.0, 1.0)
      : 0.0;

  // Build Recent Activities
  final activities = <DashboardActivityItem>[];

  // From Leads
  for (final l in leads.allLeads.take(4)) {
    activities.add(DashboardActivityItem(
      id: l.id,
      title: 'Lead: ${l.customerName}',
      subtitle: '${l.shopName} • Status: ${l.responseStatus}',
      timestamp: l.createdAt,
      type: ActivityType.lead,
      color: AppColors.primary,
      icon: Icons.contact_phone_rounded,
    ));
  }

  // From Payments
  for (final p in customers.allPayments.take(4)) {
    final cust = customers.allCustomers.firstWhere(
      (c) => c.id == p.customerId,
      orElse: () => customers.allCustomers.first,
    );
    activities.add(DashboardActivityItem(
      id: p.id,
      title: 'Payment: ₹${(p.amountReceived / 100).toStringAsFixed(0)}',
      subtitle: '${cust.customerName} (${cust.shopName}) via ${p.paymentMethod}',
      timestamp: p.paymentDate,
      type: ActivityType.payment,
      color: AppColors.success,
      icon: Icons.payments_rounded,
    ));
  }

  // From Expenses
  for (final e in payments.expenses.take(4)) {
    activities.add(DashboardActivityItem(
      id: e.id,
      title: 'Expense: ${e.title}',
      subtitle: '₹${(e.amount / 100).toStringAsFixed(0)} • ${e.category}',
      timestamp: e.date,
      type: ActivityType.expense,
      color: AppColors.danger,
      icon: Icons.receipt_long_rounded,
    ));
  }

  // From Completed Tasks
  for (final t in tasks.allTasks.where((t) => t.isCompleted).take(3)) {
    activities.add(DashboardActivityItem(
      id: t.id,
      title: 'Task Done: ${t.title}',
      subtitle: t.remarks.isNotEmpty ? t.remarks : 'Priority: ${t.priority}',
      timestamp: t.completedAt ?? t.createdAt,
      type: ActivityType.task,
      color: AppColors.teal,
      icon: Icons.check_circle_rounded,
    ));
  }

  // Sort activities newest first
  activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

  return DashboardData(
    totalActiveLeads: leads.totalActiveCount,
    leadsRequiringFollowUpToday: leads.followUpsDueTodayCount,
    totalCustomers: customers.allCustomers.length,
    totalOutstandingPaise: summary.totalOutstandingPaise,
    monthlyCollectionTargetPaise: targetPaise,
    amountCollectedThisMonthPaise: collectedPaise,
    collectionProgressRatio: progressRatio,
    pendingExpensesPaise: payments.totalPendingFutureExpensesPaise,
    todayPendingTasks: tasks.todayPendingCount,
    cashBalancePaise: summary.cashBalancePaise,
    bankBalancePaise: summary.bankBalancePaise,
    fatherBalancePaise: summary.fatherBalancePaise,
    totalLiquidBalancePaise: summary.totalLiquidBalancePaise,
    recentActivities: activities.take(8).toList(),
  );
});
