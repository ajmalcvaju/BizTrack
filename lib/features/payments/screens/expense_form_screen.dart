import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/expense_model.dart';
import '../providers/payments_provider.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final ExpenseModel? initialExpense;

  const ExpenseFormScreen({super.key, this.initialExpense});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _remarksController;
  String _category = AppConstants.expenseCategoryOther;
  String _accountType = AppConstants.accountTypeBank;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.initialExpense;
    _titleController = TextEditingController(text: e?.title ?? '');
    _amountController = TextEditingController(
      text: e != null ? (e.amount / 100).toStringAsFixed(0) : '',
    );
    _remarksController = TextEditingController(text: e?.remarks ?? '');
    if (e != null) {
      _category = e.category;
      _accountType = e.accountType;
      _date = e.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final amountPaise =
        CurrencyFormatter.parseRupeesToPaise(_amountController.text);

    if (widget.initialExpense == null) {
      final exp = ExpenseModel(
        id: '',
        title: _titleController.text.trim(),
        amount: amountPaise,
        category: _category,
        accountType: _accountType,
        date: _date,
        remarks: _remarksController.text.trim(),
        createdAt: DateTime.now(),
      );
      await ref.read(paymentsProvider.notifier).addExpense(exp);
    } else {
      final updated = widget.initialExpense!.copyWith(
        title: _titleController.text.trim(),
        amount: amountPaise,
        category: _category,
        accountType: _accountType,
        date: _date,
        remarks: _remarksController.text.trim(),
      );
      await ref.read(paymentsProvider.notifier).updateExpense(updated);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.initialExpense == null
              ? 'Expense recorded successfully!'
              : 'Expense updated successfully!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialExpense != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Expense Title *',
                  hintText: 'e.g. Office rent, Tea/Snacks, Staff salary...',
                  prefixIcon: Icon(Icons.receipt_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter expense title' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
                  prefixText: '₹ ',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter amount';
                  final val = double.tryParse(v.trim());
                  if (val == null || val <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Paid From (Bank vs Cash vs Father's Account)
              const Text(
                'Paid From (Account Type) *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _accountType = AppConstants.accountTypeBank),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: _accountType == AppConstants.accountTypeBank
                              ? AppColors.primary
                              : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _accountType == AppConstants.accountTypeBank
                                ? AppColors.primary
                                : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder),
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
                                    : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
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
                      onTap: () => setState(() => _accountType = AppConstants.accountTypeCash),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: _accountType == AppConstants.accountTypeCash
                              ? AppColors.success
                              : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _accountType == AppConstants.accountTypeCash
                                ? AppColors.success
                                : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder),
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
                                    : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
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
                      onTap: () => setState(() => _accountType = AppConstants.accountTypeFatherBank),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: _accountType == AppConstants.accountTypeFatherBank
                              ? AppColors.indigo
                              : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _accountType == AppConstants.accountTypeFatherBank
                                ? AppColors.indigo
                                : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder),
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
                                    : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'Expense Category',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.expenseCategories.map((cat) {
                  final isSelected = _category == cat;
                  Color catColor;
                  switch (cat) {
                    case AppConstants.expenseCategorySalary:
                      catColor = AppColors.salaryCategory;
                      break;
                    case AppConstants.expenseCategoryPersonal:
                      catColor = AppColors.personalCategory;
                      break;
                    default:
                      catColor = AppColors.otherCategory;
                  }
                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: catColor,
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide(
                      color: isSelected ? catColor : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _category = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                label: Text('Expense Date: ${DateFormatter.formatDate(_date)}'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Notes',
                  hintText: 'e.g. Paid via UPI, bill copy received...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Record Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
