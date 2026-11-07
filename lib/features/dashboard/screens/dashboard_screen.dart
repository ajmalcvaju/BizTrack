import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/recent_activity_card.dart';
import '../../leads/screens/lead_form_screen.dart';
import '../../customers/screens/customer_form_screen.dart';
import '../../payments/screens/expense_form_screen.dart';
import '../../day_planner/screens/task_form_screen.dart';
import '../../payments/screens/monthly_target_screen.dart';
import '../../customers/screens/customers_list_screen.dart';
import '../../../core/constants/app_constants.dart';
import '../../payments/screens/account_transactions_screen.dart';
import '../../payments/screens/account_transfer_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showAddPaymentCustomerSelect(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CustomersListScreen(selectForPayment: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final data = ref.watch(dashboardProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userName = authState.userProfile?.displayName.split(' ').first ?? 'Partner';
    final businessName = authState.userProfile?.businessName ?? 'BizPilot';
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Providers auto-update with streams
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()}, $userName 👋',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          DateFormatter.formatHeaderDate(now),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Text(
                      businessName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Monthly Target Banner & Progress Bar
              CustomCard(
                padding: const EdgeInsets.all(18),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.indigo.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.track_changes_rounded,
                                  color: AppColors.indigo, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Monthly Collection Target',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  DateFormatter.formatMonthNameYear(now),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const MonthlyTargetScreen()),
                            );
                          },
                          child: const Text('Set / Edit', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Collected', style: TextStyle(fontSize: 11, color: AppColors.lightTextMuted)),
                            Text(
                              CurrencyFormatter.formatPaise(data.amountCollectedThisMonthPaise),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.successDark,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Target Goal', style: TextStyle(fontSize: 11, color: AppColors.lightTextMuted)),
                            Text(
                              data.monthlyCollectionTargetPaise > 0
                                  ? CurrencyFormatter.formatPaise(data.monthlyCollectionTargetPaise)
                                  : 'Not set',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: data.collectionProgressRatio,
                        minHeight: 8,
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          data.collectionProgressRatio >= 1.0 ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(data.collectionProgressRatio * 100).toStringAsFixed(1)}% Achieved',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: data.collectionProgressRatio >= 1.0 ? AppColors.success : AppColors.primary,
                          ),
                        ),
                        Text(
                          data.monthlyCollectionTargetPaise > data.amountCollectedThisMonthPaise
                              ? 'Remaining: ${CurrencyFormatter.formatPaise(data.monthlyCollectionTargetPaise - data.amountCollectedThisMonthPaise)}'
                              : 'Target Achieved! 🎉',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Liquid Balances Bar (Bank, Cash & Father's Account)
              CustomCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // 1. Bank Balance
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AccountTransactionsScreen(
                                    initialAccount: AppConstants.accountTypeBank,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_rounded,
                                          color: AppColors.primary,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Flexible(
                                        child: Text(
                                          'Bank',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.lightTextSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    CurrencyFormatter.formatPaise(data.bankBalancePaise),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 32,
                          width: 1,
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        // 2. Cash in Hand
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AccountTransactionsScreen(
                                    initialAccount: AppConstants.accountTypeCash,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.payments_rounded,
                                          color: AppColors.success,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Flexible(
                                        child: Text(
                                          'Cash',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.lightTextSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    CurrencyFormatter.formatPaise(data.cashBalancePaise),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.successDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 32,
                          width: 1,
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        // 3. Father's Account
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AccountTransactionsScreen(
                                    initialAccount: AppConstants.accountTypeFatherBank,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: AppColors.indigo.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.family_restroom_rounded,
                                          color: AppColors.indigo,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Flexible(
                                        child: Text(
                                          "Father's",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.lightTextSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    CurrencyFormatter.formatPaise(data.fatherBalancePaise),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.indigo,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    // Quick Save Cash / Transfer Action
                    InkWell(
                      onTap: () {
                        AccountTransferDialog.show(
                          context,
                          initialFromAccount: AppConstants.accountTypeCash,
                          initialToAccount: AppConstants.accountTypeFatherBank,
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.swap_horiz_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Save Cash in Father's Account / Transfer",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Actions
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    QuickActionButton(
                      label: 'Add Lead',
                      icon: Icons.person_add_alt_1_rounded,
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LeadFormScreen()),
                        );
                      },
                    ),
                    QuickActionButton(
                      label: 'Add Customer',
                      icon: Icons.group_add_rounded,
                      color: AppColors.indigo,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
                        );
                      },
                    ),
                    QuickActionButton(
                      label: 'Add Payment',
                      icon: Icons.payments_outlined,
                      color: AppColors.success,
                      onTap: () => _showAddPaymentCustomerSelect(context, ref),
                    ),
                    QuickActionButton(
                      label: 'Add Expense',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.danger,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
                        );
                      },
                    ),
                    QuickActionButton(
                      label: 'Add Task',
                      icon: Icons.add_task_rounded,
                      color: AppColors.teal,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TaskFormScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Summary Cards Grid
              Text(
                'Business Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  SummaryCard(
                    title: 'Active Leads',
                    value: data.totalActiveLeads.toString(),
                    subtitle: '${data.leadsRequiringFollowUpToday} follow-up today',
                    icon: Icons.contact_phone_rounded,
                    color: AppColors.primary,
                    onTap: () => onNavigateToTab?.call(1), // Go to Leads
                  ),
                  SummaryCard(
                    title: 'Follow-ups Today',
                    value: data.leadsRequiringFollowUpToday.toString(),
                    subtitle: data.leadsRequiringFollowUpToday > 0 ? 'Requires attention' : 'All clear',
                    icon: Icons.event_repeat_rounded,
                    color: AppColors.warning,
                    onTap: () => onNavigateToTab?.call(1),
                  ),
                  SummaryCard(
                    title: 'Total Customers',
                    value: data.totalCustomers.toString(),
                    subtitle: 'Active accounts',
                    icon: Icons.people_alt_rounded,
                    color: AppColors.indigo,
                    onTap: () => onNavigateToTab?.call(2), // Go to Customers
                  ),
                  SummaryCard(
                    title: 'Outstanding Dues',
                    value: CurrencyFormatter.formatCompactPaise(data.totalOutstandingPaise),
                    subtitle: 'To be collected',
                    icon: Icons.money_off_rounded,
                    color: AppColors.danger,
                    onTap: () => onNavigateToTab?.call(3), // Go to Payments
                  ),
                  SummaryCard(
                    title: 'Month Collected',
                    value: CurrencyFormatter.formatCompactPaise(data.amountCollectedThisMonthPaise),
                    subtitle: 'Received in cash/bank',
                    icon: Icons.savings_rounded,
                    color: AppColors.success,
                    onTap: () => onNavigateToTab?.call(3),
                  ),
                  SummaryCard(
                    title: 'Pending Expenses',
                    value: CurrencyFormatter.formatCompactPaise(data.pendingExpensesPaise),
                    subtitle: 'Scheduled ahead',
                    icon: Icons.event_repeat_rounded,
                    color: AppColors.purple,
                    onTap: () => onNavigateToTab?.call(3),
                  ),
                  SummaryCard(
                    title: 'Pending Tasks',
                    value: data.todayPendingTasks.toString(),
                    subtitle: "Today's agenda",
                    icon: Icons.task_alt_rounded,
                    color: AppColors.teal,
                    onTap: () => onNavigateToTab?.call(3),
                  ),
                  SummaryCard(
                    title: 'Collection Target',
                    value: CurrencyFormatter.formatCompactPaise(data.monthlyCollectionTargetPaise),
                    subtitle: '${(data.collectionProgressRatio * 100).toInt()}% achieved',
                    icon: Icons.emoji_events_rounded,
                    color: AppColors.primaryDark,
                    onTap: () => onNavigateToTab?.call(3),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Activities Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RecentActivityCard(activities: data.recentActivities),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
