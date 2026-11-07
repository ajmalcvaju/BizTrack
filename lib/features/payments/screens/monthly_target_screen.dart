import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/custom_card.dart';
import '../providers/payments_provider.dart';

class MonthlyTargetScreen extends ConsumerStatefulWidget {
  const MonthlyTargetScreen({super.key});

  @override
  ConsumerState<MonthlyTargetScreen> createState() =>
      _MonthlyTargetScreenState();
}

class _MonthlyTargetScreenState extends ConsumerState<MonthlyTargetScreen> {
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  late String _selectedMonthYear;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedMonthYear = DateFormatter.formatMonthYear(DateTime.now());
    _loadCurrentTarget();
  }

  void _loadCurrentTarget() {
    final payState = ref.read(paymentsProvider);
    final target = payState.currentMonthTarget;
    if (target != null) {
      _amountController.text =
          (target.targetAmount / 100).toStringAsFixed(0);
      _remarksController.text = target.remarks;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final amountPaise =
        CurrencyFormatter.parseRupeesToPaise(_amountController.text);
    if (amountPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target amount')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await ref.read(paymentsProvider.notifier).saveTarget(
          monthYear: _selectedMonthYear,
          targetAmountPaise: amountPaise,
          remarks: _remarksController.text.trim(),
        );

    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target saved successfully!')),
      );
    }
  }

  Future<void> _handleDelete(String monthYear) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Delete Target',
      message: 'Delete target for $monthYear?',
      confirmText: 'Delete',
      confirmColor: AppColors.danger,
    );

    if (confirm == true) {
      await ref.read(paymentsProvider.notifier).deleteTarget(monthYear);
      if (monthYear == _selectedMonthYear) {
        _amountController.clear();
        _remarksController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final payState = ref.watch(paymentsProvider);
    final summary = ref.watch(financialSummaryProvider);
    final target = payState.currentMonthTarget;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final targetAmount = target?.targetAmount ?? 0;
    final collected = summary.thisMonthCollectedPaise;
    final remaining = (targetAmount - collected).clamp(0, double.infinity).toInt();
    final progressRatio = targetAmount > 0
        ? (collected / targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Collection Target'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Indicator Card
            CustomCard(
              padding: const EdgeInsets.all(20),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Target for $_selectedMonthYear',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(progressRatio * 100).toStringAsFixed(1)}% Achieved',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: progressRatio >= 1.0
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressRatio,
                      minHeight: 12,
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressRatio >= 1.0
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatColumn(
                        label: 'Target Goal',
                        value: CurrencyFormatter.formatPaise(targetAmount),
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      _StatColumn(
                        label: 'Collected',
                        value: CurrencyFormatter.formatPaise(collected),
                        color: AppColors.successDark,
                      ),
                      _StatColumn(
                        label: 'Remaining',
                        value: CurrencyFormatter.formatPaise(remaining),
                        color: remaining > 0
                            ? AppColors.warningDark
                            : AppColors.successDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form to set/edit target
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Set / Update Goal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Target (₹)',
                      prefixText: '₹ ',
                      prefixIcon: Icon(Icons.track_changes_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Remarks / Strategy Notes',
                      hintText: 'e.g. Festival sales boost, new client acquisitions...',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                        : const Text('Save Monthly Target'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Target History
            const Text(
              'Target History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (payState.targets.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No targets set yet.'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: payState.targets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final t = payState.targets[index];
                  return CustomCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Month: ${t.monthYear}',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            if (t.remarks.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                t.remarks,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              CurrencyFormatter.formatPaise(t.targetAmount),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.danger),
                              onPressed: () => _handleDelete(t.monthYear),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.lightTextMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
