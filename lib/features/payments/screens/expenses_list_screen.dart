import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../models/expense_model.dart';
import '../providers/payments_provider.dart';
import 'expense_form_screen.dart';

class ExpensesListScreen extends ConsumerWidget {
  const ExpensesListScreen({super.key});

  Future<void> _deleteExpense(BuildContext context, WidgetRef ref, ExpenseModel exp) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Delete Expense',
      message: 'Delete expense "${exp.title}" of ${CurrencyFormatter.formatPaise(exp.amount)}?',
      confirmText: 'Delete',
      confirmColor: AppColors.danger,
    );

    if (confirm == true) {
      await ref.read(paymentsProvider.notifier).deleteExpense(exp.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted successfully')),
        );
      }
    }
  }

  Future<void> _exportCsv(List<ExpenseModel> expenses) async {
    await PdfExportService().exportExpensesCsv(expenses);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payState = ref.watch(paymentsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final expenses = payState.monthlyExpenses;
    final totalExpense = payState.totalMonthlyExpensesPaise;
    final breakdown = payState.expenseBreakdownByCategory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: () => _exportCsv(payState.expenses),
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.danger),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
              );
            },
            tooltip: 'Add Expense',
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Monthly Expense & Breakdown Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expenses for ${payState.selectedMonthYear}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyFormatter.formatPaise(totalExpense),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${expenses.length} Records',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category Breakdown Progress Bars
                  _BreakdownBar(
                    label: 'Salary',
                    amountPaise: breakdown[AppConstants.expenseCategorySalary] ?? 0,
                    totalPaise: totalExpense,
                    color: AppColors.salaryCategory,
                  ),
                  const SizedBox(height: 8),
                  _BreakdownBar(
                    label: 'Personal',
                    amountPaise: breakdown[AppConstants.expenseCategoryPersonal] ?? 0,
                    totalPaise: totalExpense,
                    color: AppColors.personalCategory,
                  ),
                  const SizedBox(height: 8),
                  _BreakdownBar(
                    label: 'Other',
                    amountPaise: breakdown[AppConstants.expenseCategoryOther] ?? 0,
                    totalPaise: totalExpense,
                    color: AppColors.otherCategory,
                  ),
                ],
              ),
            ),
          ),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: Text(
                    'All Categories',
                    style: TextStyle(
                      color: payState.expenseCategoryFilter == null
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : const Color(0xFF1E293B)),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  selected: payState.expenseCategoryFilter == null,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  backgroundColor: isDark
                      ? AppColors.darkCard
                      : const Color(0xFFF1F5F9),
                  side: BorderSide(
                    color: payState.expenseCategoryFilter == null
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFCBD5E1)),
                    width: 1.5,
                  ),
                  onSelected: (_) => ref
                      .read(paymentsProvider.notifier)
                      .setExpenseCategoryFilter(null),
                ),
                const SizedBox(width: 8),
                ...AppConstants.expenseCategories.map((cat) {
                  final isSel = payState.expenseCategoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: isSel
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextPrimary
                                  : const Color(0xFF1E293B)),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      backgroundColor: isDark
                          ? AppColors.darkCard
                          : const Color(0xFFF1F5F9),
                      side: BorderSide(
                        color: isSel
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFCBD5E1)),
                        width: 1.5,
                      ),
                      onSelected: (_) => ref
                          .read(paymentsProvider.notifier)
                          .setExpenseCategoryFilter(isSel ? null : cat),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Expense list
          Expanded(
            child: expenses.isEmpty
                ? EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: 'No expenses recorded',
                    description: 'Keep track of business overhead, salaries, and bills.',
                    buttonText: 'Add Expense',
                    onButtonPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
                      );
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final exp = expenses[index];
                      Color catColor;
                      switch (exp.category) {
                        case AppConstants.expenseCategorySalary:
                          catColor = AppColors.salaryCategory;
                          break;
                        case AppConstants.expenseCategoryPersonal:
                          catColor = AppColors.personalCategory;
                          break;
                        default:
                          catColor = AppColors.otherCategory;
                      }

                      return CustomCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.receipt_rounded, color: catColor, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          exp.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.formatPaise(exp.amount),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            exp.category,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: catColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: exp.isBank
                                                  ? AppColors.primary.withOpacity(0.1)
                                                  : AppColors.success.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              exp.accountType,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: exp.isBank
                                                    ? AppColors.primary
                                                    : AppColors.successDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        DateFormatter.formatDate(exp.date),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (exp.remarks.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      exp.remarks,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.lightTextMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                              onPressed: () => _deleteExpense(context, ref, exp),
                              tooltip: 'Delete Expense',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
          );
        },
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BreakdownBar extends StatelessWidget {
  final String label;
  final int amountPaise;
  final int totalPaise;
  final Color color;

  const _BreakdownBar({
    required this.label,
    required this.amountPaise,
    required this.totalPaise,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = totalPaise > 0 ? (amountPaise / totalPaise).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            Text(
              '${CurrencyFormatter.formatPaise(amountPaise)} (${(ratio * 100).toStringAsFixed(0)}%)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
