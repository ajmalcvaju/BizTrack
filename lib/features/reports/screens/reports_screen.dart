import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../leads/providers/leads_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../payments/providers/payments_provider.dart';
import '../../day_planner/providers/tasks_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedReportIndex = 0; // 0: Collection, 1: Expenses, 2: Outstanding, 3: Leads, 4: Tasks

  final List<String> _reportTypes = [
    'Collections',
    'Expenses',
    'Outstanding',
    'Lead Conversion',
    'Task Completion',
  ];

  @override
  Widget build(BuildContext context) {
    final custState = ref.watch(customersProvider);
    final payState = ref.watch(paymentsProvider);
    final leadsState = ref.watch(leadsProvider);
    final tasksState = ref.watch(tasksProvider);
    final summary = ref.watch(financialSummaryProvider);
    final authState = ref.watch(authProvider);

    final businessName = authState.userProfile?.businessName ?? 'BizPilot';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            onPressed: () async {
              if (_selectedReportIndex == 0) {
                await PdfExportService().exportCollectionPdf(
                  payments: custState.allPayments,
                  customers: custState.allCustomers,
                  businessName: businessName,
                  period: 'All Time',
                );
              } else {
                await PdfExportService().exportOutstandingPdf(
                  customers: custState.allCustomers,
                  businessName: businessName,
                );
              }
            },
            tooltip: 'Export PDF',
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: () async {
              if (_selectedReportIndex == 1) {
                await PdfExportService().exportExpensesCsv(payState.expenses);
              } else {
                await PdfExportService().exportCustomersCsv(custState.allCustomers);
              }
            },
            tooltip: 'Export CSV / Excel',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Report Category Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_reportTypes.length, (index) {
                  final isSel = _selectedReportIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        _reportTypes[index],
                        style: TextStyle(
                          color: isSel ? Colors.white : const Color(0xFF1E293B),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      backgroundColor: const Color(0xFFF1F5F9),
                      side: BorderSide(
                        color: isSel ? AppColors.primary : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedReportIndex = index);
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic Report View
            if (_selectedReportIndex == 0) ...[
              // 1. Monthly Collection Report
              _CollectionReportView(custState: custState, summary: summary),
            ] else if (_selectedReportIndex == 1) ...[
              // 2. Monthly Expense Report
              _ExpenseReportView(payState: payState),
            ] else if (_selectedReportIndex == 2) ...[
              // 3. Customer Outstanding Report
              _OutstandingReportView(custState: custState),
            ] else if (_selectedReportIndex == 3) ...[
              // 4. Lead Conversion Report
              _LeadConversionReportView(leadsState: leadsState),
            ] else ...[
              // 5. Daily Task Completion Report
              _TaskCompletionReportView(tasksState: tasksState),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _CollectionReportView extends StatelessWidget {
  final CustomersState custState;
  final FinancialSummary summary;

  const _CollectionReportView({required this.custState, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Collections Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Collected (Lifetime)', style: TextStyle(fontSize: 11, color: AppColors.lightTextMuted)),
                      Text(
                        CurrencyFormatter.formatPaise(summary.totalCollectedPaise),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.successDark),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('This Month', style: TextStyle(fontSize: 11, color: AppColors.lightTextMuted)),
                      Text(
                        CurrencyFormatter.formatPaise(summary.thisMonthCollectedPaise),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Bank: ${CurrencyFormatter.formatPaise(summary.bankReceivedPaise)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.payments_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Cash: ${CurrencyFormatter.formatPaise(summary.cashReceivedPaise)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.successDark),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Recent Payments Breakdown
        const Text('Payment History Log', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: custState.allPayments.take(6).length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final p = custState.allPayments[index];
            final c = custState.allCustomers.firstWhere((x) => x.id == p.customerId, orElse: () => custState.allCustomers.first);
            return CustomCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('${p.accountType} (${p.paymentMethod}) • ${DateFormatter.formatDate(p.paymentDate)}', style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.formatPaise(p.amountReceived),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successDark),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ExpenseReportView extends StatelessWidget {
  final PaymentsState payState;

  const _ExpenseReportView({required this.payState});

  @override
  Widget build(BuildContext context) {
    final total = payState.totalMonthlyExpensesPaise;
    final breakdown = payState.expenseBreakdownByCategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Expenses (${payState.selectedMonthYear})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                CurrencyFormatter.formatPaise(total),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.danger),
              ),
              const SizedBox(height: 16),
              const Text('Category Breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...breakdown.entries.map((entry) {
                final ratio = total > 0 ? entry.value / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 12)),
                      Text(
                        '${CurrencyFormatter.formatPaise(entry.value)} (${(ratio * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _OutstandingReportView extends StatelessWidget {
  final CustomersState custState;

  const _OutstandingReportView({required this.custState});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomCard(
          padding: const EdgeInsets.all(18),
          color: const Color(0xFFFEF2F2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Outstanding Receivables Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.dangerDark)),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.formatPaise(custState.totalOutstandingPaise),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.danger),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Completed Work: ${CurrencyFormatter.formatPaise(custState.completedWorkOutstandingPaise)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.dangerDark)),
                  Text('Incomplete Work: ${CurrencyFormatter.formatPaise(custState.incompleteWorkOutstandingPaise)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warningDark)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeadConversionReportView extends StatelessWidget {
  final LeadsState leadsState;

  const _LeadConversionReportView({required this.leadsState});

  @override
  Widget build(BuildContext context) {
    final total = leadsState.allLeads.length;
    final converted = leadsState.convertedCount;
    final rate = total > 0 ? (converted / total * 100).toStringAsFixed(1) : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lead Conversion Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Leads', style: TextStyle(fontSize: 12, color: AppColors.lightTextMuted)),
                      Text('$total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Converted', style: TextStyle(fontSize: 12, color: AppColors.lightTextMuted)),
                      Text('$converted', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.successDark)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Conversion Rate', style: TextStyle(fontSize: 12, color: AppColors.lightTextMuted)),
                      Text('$rate%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskCompletionReportView extends StatelessWidget {
  final TasksState tasksState;

  const _TaskCompletionReportView({required this.tasksState});

  @override
  Widget build(BuildContext context) {
    final total = tasksState.allTasks.length;
    final completed = tasksState.allTasks.where((t) => t.isCompleted).length;
    final overdue = tasksState.overdueTasks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daily Task Execution Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      const Text('Total Tasks', style: TextStyle(fontSize: 11, color: AppColors.lightTextMuted)),
                      const SizedBox(height: 4),
                      Text('$total', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Completed', style: TextStyle(fontSize: 11, color: AppColors.lightTextMuted)),
                      const SizedBox(height: 4),
                      Text('$completed', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.successDark)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Overdue', style: TextStyle(fontSize: 11, color: AppColors.lightTextMuted)),
                      const SizedBox(height: 4),
                      Text('$overdue', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.danger)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
