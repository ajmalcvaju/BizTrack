import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../customers/models/payment_model.dart';
import '../models/expense_model.dart';
import '../models/account_transfer_model.dart';
import '../providers/payments_provider.dart';
import 'account_transfer_dialog.dart';

enum AccountTransactionType {
  customerPayment,
  transferIn,
  transferOut,
  expense,
}

class AccountLedgerItem {
  final String id;
  final AccountTransactionType type;
  final String title;
  final String subtitle;
  final int amount; // in paise (positive for in, negative or positive depending on direction)
  final bool isInflow;
  final DateTime date;
  final String? originalRefId;

  AccountLedgerItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isInflow,
    required this.date,
    this.originalRefId,
  });
}

class AccountTransactionsScreen extends ConsumerStatefulWidget {
  final String initialAccount;

  const AccountTransactionsScreen({
    super.key,
    this.initialAccount = AppConstants.accountTypeFatherBank,
  });

  @override
  ConsumerState<AccountTransactionsScreen> createState() =>
      _AccountTransactionsScreenState();
}

class _AccountTransactionsScreenState
    extends ConsumerState<AccountTransactionsScreen> {
  late String _selectedAccount;
  String? _selectedMonthYear;
  String _flowFilter = 'ALL'; // ALL, IN, OUT
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.initialAccount;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getAccountColor(String account) {
    switch (account) {
      case AppConstants.accountTypeFatherBank:
        return AppColors.indigo;
      case AppConstants.accountTypeBank:
        return AppColors.primary;
      case AppConstants.accountTypeCash:
        return AppColors.successDark;
      default:
        return AppColors.primary;
    }
  }

  IconData _getAccountIcon(String account) {
    switch (account) {
      case AppConstants.accountTypeFatherBank:
        return Icons.family_restroom_rounded;
      case AppConstants.accountTypeBank:
        return Icons.account_balance_rounded;
      case AppConstants.accountTypeCash:
        return Icons.payments_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  List<AccountLedgerItem> _buildLedgerItems() {
    final custState = ref.watch(customersProvider);
    final payState = ref.watch(paymentsProvider);

    final customerMap = {for (var c in custState.allCustomers) c.id: c};
    final items = <AccountLedgerItem>[];

    // 1. Customer Payments
    for (final p in custState.allPayments) {
      if (p.accountType == _selectedAccount) {
        final c = customerMap[p.customerId];
        final custName = c?.customerName ?? 'Customer';
        final shopName = c?.shopName.isNotEmpty == true ? ' (${c!.shopName})' : '';
        items.add(AccountLedgerItem(
          id: 'pay-${p.id}',
          type: AccountTransactionType.customerPayment,
          title: '$custName$shopName',
          subtitle: 'Collection (${p.paymentMethod})${p.remarks.isNotEmpty ? ' • ${p.remarks}' : ''}',
          amount: p.amountReceived,
          isInflow: true,
          date: p.paymentDate,
          originalRefId: p.id,
        ));
      }
    }

    // 2. Transfers In & Out
    for (final tr in payState.transfers) {
      if (tr.toAccount == _selectedAccount) {
        // Inflow
        items.add(AccountLedgerItem(
          id: 'tr-in-${tr.id}',
          type: AccountTransactionType.transferIn,
          title: tr.fromAccount == AppConstants.accountTypeCash
              ? "Cash Saved in $_selectedAccount"
              : "Transfer from ${tr.fromAccount}",
          subtitle: tr.remarks.isNotEmpty
              ? tr.remarks
              : 'Deposited into $_selectedAccount',
          amount: tr.amount,
          isInflow: true,
          date: tr.date,
          originalRefId: tr.id,
        ));
      } else if (tr.fromAccount == _selectedAccount) {
        // Outflow
        items.add(AccountLedgerItem(
          id: 'tr-out-${tr.id}',
          type: AccountTransactionType.transferOut,
          title: "Transferred to ${tr.toAccount}",
          subtitle: tr.remarks.isNotEmpty
              ? tr.remarks
              : 'Withdrawal from $_selectedAccount',
          amount: tr.amount,
          isInflow: false,
          date: tr.date,
          originalRefId: tr.id,
        ));
      }
    }

    // 3. Expenses
    for (final exp in payState.expenses) {
      if (exp.accountType == _selectedAccount) {
        items.add(AccountLedgerItem(
          id: 'exp-${exp.id}',
          type: AccountTransactionType.expense,
          title: exp.title,
          subtitle: 'Expense: ${exp.category}${exp.remarks.isNotEmpty ? ' • ${exp.remarks}' : ''}',
          amount: exp.amount,
          isInflow: false,
          date: exp.date,
          originalRefId: exp.id,
        ));
      }
    }

    // Sort newest first
    items.sort((a, b) => b.date.compareTo(a.date));

    // Filter by MonthYear
    var filtered = items;
    if (_selectedMonthYear != null && _selectedMonthYear!.isNotEmpty) {
      filtered = filtered
          .where((item) => DateFormatter.formatMonthYear(item.date) == _selectedMonthYear)
          .toList();
    }

    // Filter by flow (ALL, IN, OUT)
    if (_flowFilter == 'IN') {
      filtered = filtered.where((item) => item.isInflow).toList();
    } else if (_flowFilter == 'OUT') {
      filtered = filtered.where((item) => !item.isInflow).toList();
    }

    // Search query
    if (_searchController.text.trim().isNotEmpty) {
      final q = _searchController.text.toLowerCase().trim();
      filtered = filtered.where((item) {
        return item.title.toLowerCase().contains(q) ||
            item.subtitle.toLowerCase().contains(q);
      }).toList();
    }

    return filtered;
  }

  void _confirmDeleteTransfer(String transferId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transfer?'),
        content: const Text(
          'Are you sure you want to delete this recorded transfer? This will reverse the account balance adjustment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(paymentsProvider.notifier).deleteTransfer(transferId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transfer deleted successfully'),
                    backgroundColor: AppColors.successDark,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summary = ref.watch(financialSummaryProvider);

    int currentBalance = 0;
    int totalIn = 0;
    int totalOut = 0;

    if (_selectedAccount == AppConstants.accountTypeFatherBank) {
      currentBalance = summary.fatherBalancePaise;
      totalIn = summary.fatherReceivedPaise +
          (summary.fatherTransfersNetPaise > 0 ? summary.fatherTransfersNetPaise : 0);
      totalOut = summary.fatherSpentPaise +
          (summary.fatherTransfersNetPaise < 0 ? -summary.fatherTransfersNetPaise : 0);
    } else if (_selectedAccount == AppConstants.accountTypeBank) {
      currentBalance = summary.bankBalancePaise;
      totalIn = summary.bankReceivedPaise +
          (summary.bankTransfersNetPaise > 0 ? summary.bankTransfersNetPaise : 0);
      totalOut = summary.bankSpentPaise +
          (summary.bankTransfersNetPaise < 0 ? -summary.bankTransfersNetPaise : 0);
    } else {
      currentBalance = summary.cashBalancePaise;
      totalIn = summary.cashReceivedPaise +
          (summary.cashTransfersNetPaise > 0 ? summary.cashTransfersNetPaise : 0);
      totalOut = summary.cashSpentPaise +
          (summary.cashTransfersNetPaise < 0 ? -summary.cashTransfersNetPaise : 0);
    }

    final ledgerItems = _buildLedgerItems();
    final accountColor = _getAccountColor(_selectedAccount);

    return Scaffold(
      appBar: AppBar(
        title: Text("$_selectedAccount Ledger"),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Transfer / Save Cash',
            onPressed: () {
              AccountTransferDialog.show(
                context,
                initialFromAccount: _selectedAccount == AppConstants.accountTypeFatherBank
                    ? AppConstants.accountTypeCash
                    : _selectedAccount,
                initialToAccount: _selectedAccount == AppConstants.accountTypeFatherBank
                    ? AppConstants.accountTypeFatherBank
                    : AppConstants.accountTypeFatherBank,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Account Switcher Segmented Control
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            child: Row(
              children: AppConstants.accountTypes.map((acc) {
                final isSelected = acc == _selectedAccount;
                final accColor = _getAccountColor(acc);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAccount = acc;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? accColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? accColor
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _getAccountIcon(acc),
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              acc == AppConstants.accountTypeFatherBank ? "Father's" : acc,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Hero Account Card
                CustomCard(
                  padding: const EdgeInsets.all(18),
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
                                  color: accountColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getAccountIcon(_selectedAccount),
                                  color: accountColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedAccount,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Live Account Balance',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accountColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Active Ledger',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accountColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        CurrencyFormatter.formatPaise(currentBalance),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: currentBalance >= 0 ? accountColor : AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_downward_rounded,
                                    color: AppColors.successDark, size: 16),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total In',
                                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text(
                                      CurrencyFormatter.formatPaise(totalIn),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.successDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(height: 24, width: 1, color: Colors.grey.withOpacity(0.2)),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_upward_rounded,
                                      color: AppColors.danger, size: 16),
                                  const SizedBox(width: 6),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total Out',
                                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text(
                                        CurrencyFormatter.formatPaise(totalOut),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Quick Action: Save Cash / Transfer
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: accountColor, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                          label: Text(
                            _selectedAccount == AppConstants.accountTypeFatherBank
                                ? "Save Cash into Father's Account"
                                : "Transfer To / From $_selectedAccount",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: accountColor,
                            ),
                          ),
                          onPressed: () {
                            AccountTransferDialog.show(
                              context,
                              initialFromAccount: _selectedAccount == AppConstants.accountTypeFatherBank
                                  ? AppConstants.accountTypeCash
                                  : _selectedAccount,
                              initialToAccount: _selectedAccount == AppConstants.accountTypeFatherBank
                                  ? AppConstants.accountTypeFatherBank
                                  : AppConstants.accountTypeFatherBank,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search & Filter Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search ledger entries...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Filter Flow Chips: All, Inflow (+), Outflow (-)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('All (${ledgerItems.length})'),
                          selected: _flowFilter == 'ALL',
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _flowFilter == 'ALL' ? Colors.white : null,
                          ),
                          onSelected: (_) => setState(() => _flowFilter = 'ALL'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: const Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.white),
                          label: const Text('Money In (+)'),
                          selected: _flowFilter == 'IN',
                          selectedColor: AppColors.successDark,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _flowFilter == 'IN' ? Colors.white : null,
                          ),
                          onSelected: (_) => setState(() => _flowFilter = 'IN'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: const Icon(Icons.arrow_upward_rounded, size: 14, color: Colors.white),
                          label: const Text('Money Out (-)'),
                          selected: _flowFilter == 'OUT',
                          selectedColor: AppColors.danger,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _flowFilter == 'OUT' ? Colors.white : null,
                          ),
                          onSelected: (_) => setState(() => _flowFilter = 'OUT'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Ledger Timeline Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaction History (${ledgerItems.length})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Transaction Items
                if (ledgerItems.isEmpty)
                  EmptyStateView(
                    icon: Icons.history_rounded,
                    title: 'No Transactions Found',
                    description: _searchController.text.isNotEmpty
                        ? 'No ledger entries matching your search'
                        : 'No transactions recorded for $_selectedAccount yet.',
                  )
                else
                  ...ledgerItems.map((item) {
                    final isPayment = item.type == AccountTransactionType.customerPayment;
                    final isTrIn = item.type == AccountTransactionType.transferIn;
                    final isTrOut = item.type == AccountTransactionType.transferOut;
                    final isExp = item.type == AccountTransactionType.expense;

                    Color itemColor;
                    IconData itemIcon;
                    if (isPayment) {
                      itemColor = AppColors.successDark;
                      itemIcon = Icons.arrow_downward_rounded;
                    } else if (isTrIn) {
                      itemColor = AppColors.indigo;
                      itemIcon = Icons.swap_horiz_rounded;
                    } else if (isTrOut) {
                      itemColor = AppColors.warning;
                      itemIcon = Icons.arrow_upward_rounded;
                    } else {
                      itemColor = AppColors.danger;
                      itemIcon = Icons.shopping_bag_outlined;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: itemColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(itemIcon, color: itemColor, size: 20),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${DateFormatter.formatDate(item.date)} • ${item.subtitle}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.isInflow ? '+' : '-'}${CurrencyFormatter.formatPaise(item.amount)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: item.isInflow ? AppColors.successDark : AppColors.danger,
                              ),
                            ),
                            if ((isTrIn || isTrOut) && item.originalRefId != null)
                              GestureDetector(
                                onTap: () => _confirmDeleteTransfer(item.originalRefId!),
                                child: const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
