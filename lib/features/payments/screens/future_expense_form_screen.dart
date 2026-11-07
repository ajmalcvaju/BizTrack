import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/future_expense_model.dart';
import '../providers/payments_provider.dart';

class FutureExpenseFormScreen extends ConsumerStatefulWidget {
  final FutureExpenseModel? initialExpense;

  const FutureExpenseFormScreen({super.key, this.initialExpense});

  @override
  ConsumerState<FutureExpenseFormScreen> createState() =>
      _FutureExpenseFormScreenState();
}

class _FutureExpenseFormScreenState
    extends ConsumerState<FutureExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _remarksController;
  String _category = AppConstants.expenseCategoryOther;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay? _dueTime = const TimeOfDay(hour: 17, minute: 0);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final fe = widget.initialExpense;
    _titleController = TextEditingController(text: fe?.title ?? '');
    _amountController = TextEditingController(
      text: fe != null ? (fe.amount / 100).toStringAsFixed(0) : '',
    );
    _remarksController = TextEditingController(text: fe?.remarks ?? '');
    if (fe != null) {
      _category = fe.category;
      _dueDate = fe.dueDate;
      _dueTime = DateFormatter.parseTimeOfDay(fe.dueTime);
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
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 17, minute: 0),
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final amountPaise =
        CurrencyFormatter.parseRupeesToPaise(_amountController.text);
    final timeStr =
        _dueTime != null ? DateFormatter.formatTimeOfDay(_dueTime) : null;

    if (widget.initialExpense == null) {
      final model = FutureExpenseModel(
        id: '',
        title: _titleController.text.trim(),
        amount: amountPaise,
        category: _category,
        dueDate: _dueDate,
        dueTime: timeStr,
        remarks: _remarksController.text.trim(),
        createdAt: DateTime.now(),
      );
      await ref.read(paymentsProvider.notifier).addFutureExpense(model);
    } else {
      final updated = widget.initialExpense!.copyWith(
        title: _titleController.text.trim(),
        amount: amountPaise,
        category: _category,
        dueDate: _dueDate,
        dueTime: timeStr,
        remarks: _remarksController.text.trim(),
      );
      await ref.read(paymentsProvider.notifier).updateFutureExpense(updated);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.initialExpense == null
              ? 'Future expense scheduled!'
              : 'Future expense updated!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialExpense != null;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(isEditing ? 'Edit Scheduled Expense' : 'Schedule Future Expense'),
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
                  hintText: 'e.g. Next month rent, Server renewal, Tax payment...',
                  prefixIcon: Icon(Icons.event_note_rounded),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Expected Amount (₹) *',
                  prefixText: '₹ ',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter amount';
                  final val = double.tryParse(v.trim());
                  if (val == null || val <= 0) return 'Enter valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text(
                'Category',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.expenseCategories.map((cat) {
                  final isSelected = _category == cat;
                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
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
                      if (selected) setState(() => _category = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              const Text(
                'Due Schedule',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text('Due: ${DateFormatter.formatDate(_dueDate)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectTime,
                      icon: const Icon(Icons.access_time_rounded, size: 18),
                      label: Text(
                        _dueTime != null
                            ? DateFormatter.formatTimeOfDay(_dueTime)
                            : 'Select Time',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Remarks / Notes',
                  hintText: 'Vendor contact or payment instructions...',
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
                    : Text(isEditing ? 'Save Changes' : 'Schedule Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
