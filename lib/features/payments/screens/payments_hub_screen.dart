import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_card.dart';
import '../providers/payments_provider.dart';
import 'monthly_target_screen.dart';
import 'collection_history_screen.dart';
import 'outstanding_payments_screen.dart';
import 'expenses_list_screen.dart';
import 'future_expenses_screen.dart';
import 'financial_summary_screen.dart';
import '../../../core/constants/app_constants.dart';
import 'account_transactions_screen.dart';
import 'account_transfer_dialog.dart';

class PaymentsHubScreen extends ConsumerWidget {
  const PaymentsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financialSummaryProvider);
    final payState = ref.watch(paymentsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment & Finance Hub'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cash Flow Banner
          CustomCard(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const FinancialSummaryScreen()),
              );
            },
            padding: const EdgeInsets.all(18),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            borderColor: AppColors.primary.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Net Cash Flow',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatPaise(summary.netCashFlowPaise),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: summary.netCashFlowPaise >= 0
                            ? AppColors.successDark
                            : AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text('Tap to view comprehensive analytics →',
                        style: TextStyle(fontSize: 11, color: AppColors.primary)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.analytics_rounded,
                      color: AppColors.primary, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Liquid Cash, Bank & Father's Account Balances Card
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Current Liquid Balances',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Total: ${CurrencyFormatter.formatPaise(summary.totalLiquidBalancePaise)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3 Accounts Row
                Row(
                  children: [
                    // Bank Account
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
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_rounded,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      'Bank',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                CurrencyFormatter.formatPaise(summary.bankBalancePaise),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: summary.bankBalancePaise >= 0
                                      ? AppColors.primary
                                      : AppColors.danger,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'In: ${CurrencyFormatter.formatCompactPaise(summary.bankReceivedPaise)}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Cash in Hand
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
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.payments_rounded,
                                      size: 14,
                                      color: AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      'Cash',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                CurrencyFormatter.formatPaise(summary.cashBalancePaise),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: summary.cashBalancePaise >= 0
                                      ? AppColors.successDark
                                      : AppColors.danger,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'In: ${CurrencyFormatter.formatCompactPaise(summary.cashReceivedPaise)}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Father's Bank Account
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
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.indigo.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.family_restroom_rounded,
                                      size: 14,
                                      color: AppColors.indigo,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      "Father's",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                CurrencyFormatter.formatPaise(summary.fatherBalancePaise),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: summary.fatherBalancePaise >= 0
                                      ? AppColors.indigo
                                      : AppColors.danger,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'In: ${CurrencyFormatter.formatCompactPaise(summary.fatherReceivedPaise)}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Quick Action: Save Cash / Transfer
                InkWell(
                  onTap: () {
                    AccountTransferDialog.show(
                      context,
                      initialFromAccount: AppConstants.accountTypeCash,
                      initialToAccount: AppConstants.accountTypeFatherBank,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Save Cash in Father's Account / Transfer",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Menu Tiles
          _HubNavTile(
            title: "Father's Account & Bank Ledgers",
            subtitle: "Complete transaction histories & cash deposits",
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.indigo,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AccountTransactionsScreen(
                    initialAccount: AppConstants.accountTypeFatherBank,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          _HubNavTile(
            title: 'Monthly Collection Target',
            subtitle: payState.currentMonthTarget != null
                ? 'Goal: ${CurrencyFormatter.formatPaise(payState.currentMonthTarget!.targetAmount)}'
                : 'Set monthly targets & track progress',
            icon: Icons.track_changes_rounded,
            color: AppColors.primary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MonthlyTargetScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _HubNavTile(
            title: 'Collection History',
            subtitle: 'Complete history of all customer payments & PDF receipt reports',
            icon: Icons.receipt_long_rounded,
            color: AppColors.success,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const CollectionHistoryScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _HubNavTile(
            title: 'Outstanding Payments',
            subtitle:
                'Completed: ${CurrencyFormatter.formatCompactPaise(summary.completedWorkOutstandingPaise)} • Incomplete: ${CurrencyFormatter.formatCompactPaise(summary.incompleteWorkOutstandingPaise)}',
            icon: Icons.money_off_rounded,
            color: AppColors.danger,
            badgeText: summary.totalOutstandingPaise > 0 ? 'Dues Pending' : null,
            badgeColor: AppColors.danger,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const OutstandingPaymentsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _HubNavTile(
            title: 'Expense Management',
            subtitle:
                'Track salary, personal, and operational expenses with visual breakdown',
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.warningDark,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExpensesListScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _HubNavTile(
            title: 'Future Expenses (Scheduled)',
            subtitle:
                '${payState.overdueFutureExpenses.length} overdue • ${payState.pendingFutureExpenses.length} upcoming scheduled',
            icon: Icons.event_repeat_rounded,
            color: AppColors.purple,
            badgeText: payState.overdueFutureExpenses.isNotEmpty
                ? '${payState.overdueFutureExpenses.length} OVERDUE'
                : null,
            badgeColor: AppColors.danger,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const FutureExpensesScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          _HubNavTile(
            title: 'Financial Summary & Charts',
            subtitle:
                'Income vs Expenses comparison, cash flow breakdown & audits',
            icon: Icons.pie_chart_outline_rounded,
            color: AppColors.teal,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const FinancialSummaryScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HubNavTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badgeText;
  final Color? badgeColor;

  const _HubNavTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeText,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (badgeColor ?? AppColors.primary)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor ?? AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.lightTextMuted),
        ],
      ),
    );
  }
}
