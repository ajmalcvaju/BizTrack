import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../models/customer_model.dart';
import '../providers/customers_provider.dart';

class AddPaymentDialog extends ConsumerStatefulWidget {
  final CustomerModel customer;

  const AddPaymentDialog({super.key, required this.customer});

  static Future<void> show(BuildContext context, CustomerModel customer) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPaymentDialog(customer: customer),
    );
  }

  @override
  ConsumerState<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends ConsumerState<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  String _accountType = AppConstants.accountTypeBank;
  String _paymentMethod = AppConstants.paymentMethodUPI;
  DateTime _paymentDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final amountPaise =
        CurrencyFormatter.parseRupeesToPaise(_amountController.text);
    if (amountPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount greater than 0')),
      );
      return;
    }

    final currentBalance = widget.customer.balanceAmount;

    // Requirement: Prevent payments greater than the outstanding balance
    // unless the user explicitly confirms an advance or excess payment.
    if (amountPaise > currentBalance && currentBalance > 0) {
      final excessPaise = amountPaise - currentBalance;
      final confirm = await ConfirmDialog.show(
        context,
        title: 'Advance / Excess Payment Alert',
        message:
            'The entered amount of ${CurrencyFormatter.formatPaise(amountPaise)} exceeds the remaining balance of ${CurrencyFormatter.formatPaise(currentBalance)} by ${CurrencyFormatter.formatPaise(excessPaise)}.\n\nDo you want to proceed and record this as an advance payment?',
        confirmText: 'Accept Advance Payment',
        cancelText: 'Cancel & Modify',
        confirmColor: AppColors.primary,
        icon: Icons.info_outline_rounded,
      );

      if (confirm != true) return;
    }

    setState(() => _isSaving = true);

    await ref.read(customersProvider.notifier).addPayment(
          customer: widget.customer,
          amountReceivedPaise: amountPaise,
          paymentMethod: _paymentMethod,
          accountType: _accountType,
          remarks: _remarksController.text.trim(),
          paymentDate: _paymentDate,
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Payment of ${CurrencyFormatter.formatPaise(amountPaise)} recorded successfully!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Record Payment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.customer.customerName} • ${widget.customer.shopName}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Outstanding Balance Preview Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.customer.hasOutstanding
                      ? AppColors.dangerLight
                      : AppColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.customer.hasOutstanding
                          ? 'Current Outstanding Balance:'
                          : 'Account Status:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.customer.hasOutstanding
                            ? AppColors.dangerDark
                            : AppColors.successDark,
                      ),
                    ),
                    Text(
                      widget.customer.hasOutstanding
                          ? CurrencyFormatter.formatPaise(widget.customer.balanceAmount)
                          : 'Settled in Full',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.customer.hasOutstanding
                            ? AppColors.dangerDark
                            : AppColors.successDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Amount Received (₹) *',
                  prefixText: '₹ ',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter amount received';
                  final val = double.tryParse(v.trim());
                  if (val == null || val <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Account Type Selector: Bank vs Cash
              const Text(
                'Received In (Account Type) *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _accountType = AppConstants.accountTypeBank;
                          if (_paymentMethod == AppConstants.paymentMethodCash) {
                            _paymentMethod = AppConstants.paymentMethodUPI;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: _accountType == AppConstants.accountTypeBank
                              ? AppColors.primary
                              : (isDark ? AppColors.darkCard : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _accountType == AppConstants.accountTypeBank
                                ? AppColors.primary
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_rounded,
                              size: 16,
                              color: _accountType == AppConstants.accountTypeBank
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Bank',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _accountType == AppConstants.accountTypeBank
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _accountType = AppConstants.accountTypeCash;
                          _paymentMethod = AppConstants.paymentMethodCash;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: _accountType == AppConstants.accountTypeCash
                              ? AppColors.success
                              : (isDark ? AppColors.darkCard : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _accountType == AppConstants.accountTypeCash
                                ? AppColors.success
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payments_rounded,
                              size: 16,
                              color: _accountType == AppConstants.accountTypeCash
                                  ? Colors.white
                                  : AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Cash',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _accountType == AppConstants.accountTypeCash
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _accountType = AppConstants.accountTypeFatherBank;
                          if (_paymentMethod == AppConstants.paymentMethodCash) {
                            _paymentMethod = AppConstants.paymentMethodUPI;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: _accountType == AppConstants.accountTypeFatherBank
                              ? AppColors.indigo
                              : (isDark ? AppColors.darkCard : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _accountType == AppConstants.accountTypeFatherBank
                                ? AppColors.indigo
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.family_restroom_rounded,
                              size: 16,
                              color: _accountType == AppConstants.accountTypeFatherBank
                                  ? Colors.white
                                  : AppColors.indigo,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Father's",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _accountType == AppConstants.accountTypeFatherBank
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payment Method
              Text(
                _accountType == AppConstants.accountTypeBank
                    ? 'Bank Transfer Method'
                    : 'Payment Mode',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: (_accountType == AppConstants.accountTypeBank
                        ? [
                            AppConstants.paymentMethodUPI,
                            AppConstants.paymentMethodBankTransfer,
                            AppConstants.paymentMethodOther,
                          ]
                        : [
                            AppConstants.paymentMethodCash,
                            AppConstants.paymentMethodOther,
                          ])
                    .map((method) {
                  final isSelected = _paymentMethod == method;
                  return ChoiceChip(
                    label: Text(
                      method,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _paymentMethod = method);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Payment Date
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text('Date: ${DateFormatter.formatDate(_paymentDate)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Remarks
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Payment Remarks / Transaction ID',
                  hintText: 'e.g. Google Pay UTR #12345, Cash collected at shop...',
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _handleSubmit,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirm Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
