import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/payments_provider.dart';

class AccountTransferDialog extends ConsumerStatefulWidget {
  final String? initialFromAccount;
  final String? initialToAccount;

  const AccountTransferDialog({
    super.key,
    this.initialFromAccount,
    this.initialToAccount,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? initialFromAccount,
    String? initialToAccount,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AccountTransferDialog(
        initialFromAccount: initialFromAccount,
        initialToAccount: initialToAccount,
      ),
    );
  }

  @override
  ConsumerState<AccountTransferDialog> createState() =>
      _AccountTransferDialogState();
}

class _AccountTransferDialogState extends ConsumerState<AccountTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _fromAccount;
  late String _toAccount;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  DateTime _transferDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fromAccount = widget.initialFromAccount ?? AppConstants.accountTypeCash;
    _toAccount = widget.initialToAccount ?? AppConstants.accountTypeFatherBank;
    if (_fromAccount == _toAccount) {
      _toAccount = _fromAccount == AppConstants.accountTypeFatherBank
          ? AppConstants.accountTypeBank
          : AppConstants.accountTypeFatherBank;
    }
    _remarksController.text = _getDefaultRemarks();
  }

  String _getDefaultRemarks() {
    if (_fromAccount == AppConstants.accountTypeCash &&
        _toAccount == AppConstants.accountTypeFatherBank) {
      return "Cash saved in Father's Account";
    } else if (_fromAccount == AppConstants.accountTypeFatherBank) {
      return "Transferred from Father's Account to $_toAccount";
    }
    return 'Transferred from $_fromAccount to $_toAccount';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _onAccountsChanged() {
    setState(() {
      _remarksController.text = _getDefaultRemarks();
    });
  }

  void _addQuickAmount(int rupees) {
    final currentPaise =
        CurrencyFormatter.parseRupeesToPaise(_amountController.text);
    final newPaise = currentPaise + (rupees * 100);
    _amountController.text = (newPaise / 100).toStringAsFixed(0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromAccount == _toAccount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source and destination accounts must be different'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final amountPaise =
        CurrencyFormatter.parseRupeesToPaise(_amountController.text);
    if (amountPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than zero'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(paymentsProvider.notifier).addTransfer(
            fromAccount: _fromAccount,
            toAccount: _toAccount,
            amount: amountPaise,
            date: _transferDate,
            remarks: _remarksController.text.trim(),
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transferred ${CurrencyFormatter.formatPaise(amountPaise)} from $_fromAccount to $_toAccount',
            ),
            backgroundColor: AppColors.successDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transfer: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summary = ref.watch(financialSummaryProvider);

    int getBalance(String account) {
      switch (account) {
        case AppConstants.accountTypeCash:
          return summary.cashBalancePaise;
        case AppConstants.accountTypeBank:
          return summary.bankBalancePaise;
        case AppConstants.accountTypeFatherBank:
          return summary.fatherBalancePaise;
        default:
          return 0;
      }
    }

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Save Cash / Transfer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Deposit cash into Father's Account or transfer",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Account Selector Card (From -> To)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    // FROM ACCOUNT
                    Row(
                      children: [
                        const SizedBox(
                          width: 50,
                          child: Text(
                            'FROM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _fromAccount,
                              items: AppConstants.accountTypes.map((acc) {
                                return DropdownMenuItem(
                                  value: acc,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        acc,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '(${CurrencyFormatter.formatPaise(getBalance(acc))})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: getBalance(acc) >= 0
                                              ? AppColors.successDark
                                              : AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _fromAccount = val;
                                    if (_toAccount == val) {
                                      _toAccount = val ==
                                              AppConstants.accountTypeFatherBank
                                          ? AppConstants.accountTypeBank
                                          : AppConstants.accountTypeFatherBank;
                                    }
                                    _onAccountsChanged();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    // TO ACCOUNT
                    Row(
                      children: [
                        const SizedBox(
                          width: 50,
                          child: Text(
                            'TO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _toAccount,
                              items: AppConstants.accountTypes.map((acc) {
                                return DropdownMenuItem(
                                  value: acc,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        acc,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Text(
                                        '(${CurrencyFormatter.formatPaise(getBalance(acc))})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: getBalance(acc) >= 0
                                              ? AppColors.successDark
                                              : AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _toAccount = val;
                                    if (_fromAccount == val) {
                                      _fromAccount = val ==
                                              AppConstants.accountTypeCash
                                          ? AppConstants.accountTypeFatherBank
                                          : AppConstants.accountTypeCash;
                                    }
                                    _onAccountsChanged();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Amount Input
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Transfer Amount',
                  hintText: '0.00',
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter amount';
                  }
                  final paise = CurrencyFormatter.parseRupeesToPaise(val);
                  if (paise <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Quick Rupees Presets
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [500, 1000, 2000, 5000, 10000, 20000].map((rupees) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          '+₹$rupees',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1,
                        ),
                        onPressed: () => _addQuickAmount(rupees),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _transferDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() => _transferDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Date: ${DateFormatter.formatDate(_transferDate)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Remarks
              TextFormField(
                controller: _remarksController,
                decoration: InputDecoration(
                  labelText: 'Notes / Remarks (Optional)',
                  hintText: "e.g. Cash saved in Father's Account",
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white),
                  label: Text(
                    _isLoading ? 'Saving...' : 'Confirm & Save Transfer',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: _isLoading ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
