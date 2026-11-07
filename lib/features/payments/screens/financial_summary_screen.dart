import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_card.dart';
import '../providers/payments_provider.dart';
import '../../../core/constants/app_constants.dart';
import 'account_transactions_screen.dart';
import 'account_transfer_dialog.dart';

class FinancialSummaryScreen extends ConsumerWidget {
  const FinancialSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(financialSummaryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isPositiveCashFlow = summary.netCashFlowPaise >= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Summary & Cash Flow'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Net Cash Flow Hero Card
            CustomCard(
              padding: const EdgeInsets.all(22),
              color: isPositiveCashFlow
                  ? (isDark ? const Color(0xFF14271F) : const Color(0xFFF0FDF4))
                  : (isDark ? const Color(0xFF2C1919) : const Color(0xFFFEF2F2)),
              borderColor: isPositiveCashFlow
                  ? AppColors.success.withOpacity(0.4)
                  : AppColors.danger.withOpacity(0.4),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPositiveCashFlow
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: isPositiveCashFlow
                            ? AppColors.successDark
                            : AppColors.danger,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Net Cash Flow',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isPositiveCashFlow
                              ? AppColors.successDark
                              : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.formatPaise(summary.netCashFlowPaise),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isPositiveCashFlow
                          ? AppColors.successDark
                          : AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Net Cash Flow = Total Collected - Total Expenses',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Revenue & Expense Grid
            Row(
              children: [
                Expanded(
                  child: CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.arrow_downward_rounded,
                                color: AppColors.success, size: 18),
                            SizedBox(width: 6),
                            Text('Total Collected',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.lightTextSecondary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          CurrencyFormatter.formatPaise(
                              summary.totalCollectedPaise),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.successDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.arrow_upward_rounded,
                                color: AppColors.danger, size: 18),
                            SizedBox(width: 6),
                            Text('Total Expenses',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.lightTextSecondary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          CurrencyFormatter.formatPaise(
                              summary.totalExpensesPaise),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bank & Cash Account Breakdown
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bank & Cash Accounts',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Total Liquid: ${CurrencyFormatter.formatPaise(summary.totalLiquidBalancePaise)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Exact breakdown of money received and spent through Bank vs. Cash',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bank Account Row
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Bank Account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              CurrencyFormatter.formatPaise(summary.bankBalancePaise),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: summary.bankBalancePaise >= 0
                                    ? AppColors.primary
                                    : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Received: ${CurrencyFormatter.formatPaise(summary.bankReceivedPaise)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.successDark),
                            ),
                            Text(
                              'Total Spent: ${CurrencyFormatter.formatPaise(summary.bankSpentPaise)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.danger),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cash in Hand Row
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.payments_rounded,
                                    size: 18,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Cash in Hand',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              CurrencyFormatter.formatPaise(summary.cashBalancePaise),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: summary.cashBalancePaise >= 0
                                    ? AppColors.successDark
                                    : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Received: ${CurrencyFormatter.formatPaise(summary.cashReceivedPaise)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.successDark),
                            ),
                            Text(
                              'Total Spent: ${CurrencyFormatter.formatPaise(summary.cashSpentPaise)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.danger),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Father's Bank Account Row
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
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
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.family_restroom_rounded,
                                    size: 18,
                                    color: AppColors.indigo,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "Father's Bank Account",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              CurrencyFormatter.formatPaise(summary.fatherBalancePaise),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: summary.fatherBalancePaise >= 0
                                    ? AppColors.indigo
                                    : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total In: ${CurrencyFormatter.formatPaise(summary.fatherReceivedPaise + (summary.fatherTransfersNetPaise > 0 ? summary.fatherTransfersNetPaise : 0))}',
                              style: const TextStyle(fontSize: 12, color: AppColors.successDark),
                            ),
                            Text(
                              'Total Out: ${CurrencyFormatter.formatPaise(summary.fatherSpentPaise + (summary.fatherTransfersNetPaise < 0 ? -summary.fatherTransfersNetPaise : 0))}',
                              style: const TextStyle(fontSize: 12, color: AppColors.danger),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.indigo, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.history_rounded, size: 18, color: AppColors.indigo),
                          label: const Text(
                            "Father's Ledger",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.indigo),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AccountTransactionsScreen(
                                  initialAccount: AppConstants.accountTypeFatherBank,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18, color: Colors.white),
                          label: const Text(
                            "Save Cash / Transfer",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          onPressed: () {
                            AccountTransferDialog.show(
                              context,
                              initialFromAccount: AppConstants.accountTypeCash,
                              initialToAccount: AppConstants.accountTypeFatherBank,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Visual Comparison Bar Chart
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenue vs. Expenses Breakdown',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Realized revenue received in bank/cash against incurred expenses',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.lightTextMuted),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: ((summary.totalCollectedPaise >
                                        summary.totalExpensesPaise
                                    ? summary.totalCollectedPaise
                                    : summary.totalExpensesPaise) /
                                100) *
                            1.2,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                switch (val.toInt()) {
                                  case 0:
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text('Collections',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    );
                                  case 1:
                                    return const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text('Expenses',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    );
                                  default:
                                    return const SizedBox();
                                }
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: summary.totalCollectedPaise / 100.0,
                                color: AppColors.success,
                                width: 34,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8)),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: summary.totalExpensesPaise / 100.0,
                                color: AppColors.danger,
                                width: 34,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Outstanding Payments Detailed Breakdown
            const Text(
              'Outstanding Customer Balances',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Uncollected dues (Not included in cash revenue until received)',
              style: TextStyle(fontSize: 12, color: AppColors.lightTextMuted),
            ),
            const SizedBox(height: 12),

            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: AppColors.danger, size: 20),
                          SizedBox(width: 10),
                          Text('Completed Work Dues'),
                        ],
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(
                            summary.completedWorkOutstandingPaise),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.timelapse_rounded,
                              color: AppColors.warning, size: 20),
                          SizedBox(width: 10),
                          Text('Incomplete Work Dues'),
                        ],
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(
                            summary.incompleteWorkOutstandingPaise),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warningDark,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Outstanding Pipeline',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(
                            summary.totalOutstandingPaise),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dangerDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
