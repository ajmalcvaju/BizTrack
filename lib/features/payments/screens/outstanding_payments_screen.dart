import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/stat_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/models/customer_model.dart';
import '../../customers/providers/customers_provider.dart';
import '../../customers/screens/customer_detail_screen.dart';
import '../../customers/screens/add_payment_dialog.dart';

class OutstandingPaymentsScreen extends ConsumerStatefulWidget {
  const OutstandingPaymentsScreen({super.key});

  @override
  ConsumerState<OutstandingPaymentsScreen> createState() =>
      _OutstandingPaymentsScreenState();
}

class _OutstandingPaymentsScreenState
    extends ConsumerState<OutstandingPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportPdf(List<CustomerModel> customers) async {
    final businessName =
        ref.read(authProvider).userProfile?.businessName ?? 'BizPilot';
    await PdfExportService().exportOutstandingPdf(
      customers: customers,
      businessName: businessName,
    );
  }

  Future<void> _exportCsv(List<CustomerModel> customers) async {
    await PdfExportService().exportCustomersCsv(customers);
  }

  @override
  Widget build(BuildContext context) {
    final custState = ref.watch(customersProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final completedOutstandingCustomers = custState.allCustomers
        .where((c) => c.isCompleted && c.balanceAmount > 0)
        .toList();

    final incompleteOutstandingCustomers = custState.allCustomers
        .where((c) => c.isIncomplete && c.balanceAmount > 0)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outstanding Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: () => _exportCsv(custState.allCustomers),
            tooltip: 'Export CSV / Excel',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined,
                color: AppColors.primary),
            onPressed: () => _exportPdf(custState.allCustomers),
            tooltip: 'Export PDF Report',
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
                  const Text('Completed Work'),
                  const SizedBox(width: 6),
                  _CountBadge(
                      count: completedOutstandingCustomers.length,
                      color: AppColors.danger),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Incomplete Work'),
                  const SizedBox(width: 6),
                  _CountBadge(
                      count: incompleteOutstandingCustomers.length,
                      color: AppColors.warning),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Outstanding Summary Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF2F2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Dues to Collect',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dangerDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatPaise(
                          custState.totalOutstandingPaise),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _MiniDuesBox(
                      label: 'Completed',
                      amountPaise: custState.completedWorkOutstandingPaise,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 12),
                    _MiniDuesBox(
                      label: 'Incomplete',
                      amountPaise: custState.incompleteWorkOutstandingPaise,
                      color: AppColors.warningDark,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Completed Work List
                _OutstandingList(
                  customers: completedOutstandingCustomers,
                  emptyTitle: 'No completed work with outstanding dues',
                  emptyDesc: 'All payments for completed projects are fully settled!',
                ),

                // Incomplete Work List
                _OutstandingList(
                  customers: incompleteOutstandingCustomers,
                  emptyTitle: 'No incomplete work with outstanding dues',
                  emptyDesc: 'No active pending projects have outstanding balances.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDuesBox extends StatelessWidget {
  final String label;
  final int amountPaise;
  final Color color;

  const _MiniDuesBox({
    required this.label,
    required this.amountPaise,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.lightTextMuted)),
        Text(
          CurrencyFormatter.formatCompactPaise(amountPaise),
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

class _OutstandingList extends StatelessWidget {
  final List<CustomerModel> customers;
  final String emptyTitle;
  final String emptyDesc;

  const _OutstandingList({
    required this.customers,
    required this.emptyTitle,
    required this.emptyDesc,
  });

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) {
      return EmptyStateView(
        icon: Icons.check_circle_outline_rounded,
        title: emptyTitle,
        description: emptyDesc,
        iconColor: AppColors.success,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = customers[index];
        return CustomCard(
          onTap: () {
            // Requirement: Allow the user to open a customer profile directly
            // from the outstanding payments list.
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CustomerDetailScreen(customer: c),
              ),
            );
          },
          padding: const EdgeInsets.all(16),
          borderColor: AppColors.danger.withOpacity(0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.shopName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.customerName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatBadge.forWorkStatus(c.workStatus),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total / Received',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.lightTextMuted)),
                      Text(
                        '${CurrencyFormatter.formatPaise(c.totalWorkAmount)} / ${CurrencyFormatter.formatPaise(c.totalAmountReceived)}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Remaining Balance',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.dangerDark)),
                      Text(
                        CurrencyFormatter.formatPaise(c.balanceAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => AddPaymentDialog.show(context, c),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Record Payment'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.successDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CustomerDetailScreen(customer: c),
                        ),
                      );
                    },
                    child: const Text('View Profile'),
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
