import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/stat_badge.dart';
import '../models/future_expense_model.dart';
import '../providers/payments_provider.dart';
import 'future_expense_form_screen.dart';

class FutureExpensesScreen extends ConsumerStatefulWidget {
  const FutureExpensesScreen({super.key});

  @override
  ConsumerState<FutureExpensesScreen> createState() =>
      _FutureExpensesScreenState();
}

class _FutureExpensesScreenState extends ConsumerState<FutureExpensesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markPaid(BuildContext context, FutureExpenseModel fe) async {
    String selectedAccount = AppConstants.accountTypeBank;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('Mark as Paid'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mark "${fe.title}" (${CurrencyFormatter.formatPaise(fe.amount)}) as paid?',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Paid From (Account Type):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          avatar: Icon(
                            Icons.account_balance_rounded,
                            size: 16,
                            color: selectedAccount == AppConstants.accountTypeBank
                                ? Colors.white
                                : AppColors.primary,
                          ),
                          label: Text(
                            'Bank',
                            style: TextStyle(
                              color: selectedAccount == AppConstants.accountTypeBank
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          selected: selectedAccount == AppConstants.accountTypeBank,
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide(
                            color: selectedAccount == AppConstants.accountTypeBank
                                ? AppColors.primary
                                : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedAccount = AppConstants.accountTypeBank);
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: Icon(
                            Icons.payments_rounded,
                            size: 16,
                            color: selectedAccount == AppConstants.accountTypeCash
                                ? Colors.white
                                : AppColors.teal,
                          ),
                          label: Text(
                            'Cash',
                            style: TextStyle(
                              color: selectedAccount == AppConstants.accountTypeCash
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          selected: selectedAccount == AppConstants.accountTypeCash,
                          selectedColor: AppColors.teal,
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide(
                            color: selectedAccount == AppConstants.accountTypeCash
                                ? AppColors.teal
                                : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedAccount = AppConstants.accountTypeCash);
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: Icon(
                            Icons.family_restroom_rounded,
                            size: 16,
                            color: selectedAccount == AppConstants.accountTypeFatherBank
                                ? Colors.white
                                : AppColors.indigo,
                          ),
                          label: Text(
                            "Father's",
                            style: TextStyle(
                              color: selectedAccount == AppConstants.accountTypeFatherBank
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          selected: selectedAccount == AppConstants.accountTypeFatherBank,
                          selectedColor: AppColors.indigo,
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide(
                            color: selectedAccount == AppConstants.accountTypeFatherBank
                                ? AppColors.indigo
                                : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                          onSelected: (val) {
                            if (val) setDialogState(() => selectedAccount = AppConstants.accountTypeFatherBank);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Confirm Paid'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm == true) {
      await ref.read(paymentsProvider.notifier).markFutureExpensePaid(
            fe,
            accountType: selectedAccount,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense marked as paid via $selectedAccount!')),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context, FutureExpenseModel fe) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Delete Scheduled Expense',
      message: 'Delete "${fe.title}"?',
      confirmText: 'Delete',
      confirmColor: AppColors.danger,
    );

    if (confirm == true) {
      await ref.read(paymentsProvider.notifier).deleteFutureExpense(fe.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scheduled expense deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payState = ref.watch(paymentsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final overdue = payState.overdueFutureExpenses;
    final upcoming = payState.pendingFutureExpenses;
    final paid = payState.paidFutureExpenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Future Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const FutureExpenseFormScreen()),
              );
            },
            tooltip: 'Schedule Expense',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Overdue'),
                  const SizedBox(width: 6),
                  _CountBadge(count: overdue.length, color: AppColors.danger),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Upcoming'),
                  const SizedBox(width: 6),
                  _CountBadge(count: upcoming.length, color: AppColors.primary),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Paid'),
                  const SizedBox(width: 6),
                  _CountBadge(count: paid.length, color: AppColors.success),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Overdue Tab
          _FutureExpenseListView(
            items: overdue,
            isOverdueSection: true,
            emptyTitle: 'No overdue expenses',
            emptyDesc: 'All scheduled expenses are on track or settled!',
            onMarkPaid: (fe) => _markPaid(context, fe),
            onDelete: (fe) => _delete(context, fe),
          ),

          // Upcoming Tab
          _FutureExpenseListView(
            items: upcoming,
            emptyTitle: 'No upcoming expenses scheduled',
            emptyDesc: 'Tap the + button to schedule upcoming bills or rent.',
            onMarkPaid: (fe) => _markPaid(context, fe),
            onDelete: (fe) => _delete(context, fe),
          ),

          // Paid Tab
          _FutureExpenseListView(
            items: paid,
            emptyTitle: 'No paid future expenses',
            emptyDesc: 'Paid scheduled expenses will appear here.',
            onMarkPaid: (fe) {},
            onDelete: (fe) => _delete(context, fe),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const FutureExpenseFormScreen()),
          );
        },
        tooltip: 'Schedule Expense',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _CountBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _FutureExpenseListView extends StatelessWidget {
  final List<FutureExpenseModel> items;
  final bool isOverdueSection;
  final String emptyTitle;
  final String emptyDesc;
  final Function(FutureExpenseModel) onMarkPaid;
  final Function(FutureExpenseModel) onDelete;

  const _FutureExpenseListView({
    required this.items,
    this.isOverdueSection = false,
    required this.emptyTitle,
    required this.emptyDesc,
    required this.onMarkPaid,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyStateView(
        icon: isOverdueSection
            ? Icons.check_circle_outline_rounded
            : Icons.event_available_rounded,
        title: emptyTitle,
        description: emptyDesc,
        iconColor: isOverdueSection ? AppColors.success : AppColors.primary,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final fe = items[index];
        final isOverdue = fe.isOverdue;

        return CustomCard(
          padding: const EdgeInsets.all(16),
          // Overdue logic: automatically highlight in red as overdue from next day until marked as paid
          borderColor: isOverdue ? AppColors.danger : null,
          color: isOverdue
              ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2E1919)
                  : const Color(0xFFFEF2F2))
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      fe.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isOverdue ? AppColors.dangerDark : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isOverdue)
                    StatBadge.overdue()
                  else if (fe.isPaid)
                    const StatBadge(
                      label: 'PAID',
                      color: AppColors.success,
                      icon: Icons.check_circle,
                    )
                  else
                    StatBadge(
                      label: fe.category,
                      color: AppColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: isOverdue
                                ? AppColors.danger
                                : AppColors.lightTextMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Due: ${DateFormatter.formatDate(fe.dueDate)}${fe.dueTime != null ? " at ${fe.dueTime}" : ""}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isOverdue
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isOverdue ? AppColors.danger : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.formatPaise(fe.amount),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isOverdue
                          ? AppColors.danger
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),

              if (fe.remarks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  fe.remarks,
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.lightTextMuted,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!fe.isPaid) ...[
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                FutureExpenseFormScreen(initialExpense: fe),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      onPressed: () => onMarkPaid(fe),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Mark as Paid'),
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.danger),
                    onPressed: () => onDelete(fe),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
