import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../../customers/models/payment_model.dart';

class CollectionHistoryScreen extends ConsumerStatefulWidget {
  const CollectionHistoryScreen({super.key});

  @override
  ConsumerState<CollectionHistoryScreen> createState() =>
      _CollectionHistoryScreenState();
}

class _CollectionHistoryScreenState
    extends ConsumerState<CollectionHistoryScreen> {
  String? _selectedMethod;
  String? _selectedMonthYear;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportPdf(List<PaymentModel> payments) async {
    final customers = ref.read(customersProvider).allCustomers;
    final businessName =
        ref.read(authProvider).userProfile?.businessName ?? 'BizPilot';
    await PdfExportService().exportCollectionPdf(
      payments: payments,
      customers: customers,
      businessName: businessName,
      period: _selectedMonthYear ?? 'All Time',
    );
  }

  @override
  Widget build(BuildContext context) {
    final custState = ref.watch(customersProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final customerMap = {for (var c in custState.allCustomers) c.id: c};
    var payments = custState.allPayments;

    // Filter by payment method
    if (_selectedMethod != null && _selectedMethod!.isNotEmpty) {
      payments = payments
          .where((p) => p.paymentMethod == _selectedMethod)
          .toList();
    }

    // Filter by MonthYear
    if (_selectedMonthYear != null && _selectedMonthYear!.isNotEmpty) {
      payments = payments
          .where((p) =>
              DateFormatter.formatMonthYear(p.paymentDate) ==
              _selectedMonthYear)
          .toList();
    }

    // Filter by search query
    if (_searchController.text.trim().isNotEmpty) {
      final q = _searchController.text.toLowerCase().trim();
      payments = payments.where((p) {
        final c = customerMap[p.customerId];
        final custName = c?.customerName.toLowerCase() ?? '';
        final shopName = c?.shopName.toLowerCase() ?? '';
        final remarks = p.remarks.toLowerCase();
        return custName.contains(q) ||
            shopName.contains(q) ||
            remarks.contains(q);
      }).toList();
    }

    final totalCollected =
        payments.fold(0, (sum, p) => sum + p.amountReceived);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined,
                color: AppColors.primary),
            onPressed: () => _exportPdf(payments),
            tooltip: 'Export PDF Report',
          ),
        ],
      ),
      body: Column(
        children: [
          // Total Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFECFDF5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Filtered Collections',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatPaise(totalCollected),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.successDark,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${payments.length} Payments',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search customer, shop, remarks...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(
                          'All Methods',
                          style: TextStyle(
                            color: _selectedMethod == null
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : const Color(0xFF1E293B)),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        selected: _selectedMethod == null,
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.white,
                        backgroundColor: isDark
                            ? AppColors.darkCard
                            : const Color(0xFFF1F5F9),
                        side: BorderSide(
                          color: _selectedMethod == null
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFCBD5E1)),
                          width: 1.5,
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedMethod = null),
                      ),
                      const SizedBox(width: 8),
                      ...AppConstants.paymentMethods.map((m) {
                        final isSel = _selectedMethod == m;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              m,
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
                            onSelected: (_) => setState(
                                () => _selectedMethod = isSel ? null : m),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Payment List
          Expanded(
            child: payments.isEmpty
                ? const EmptyStateView(
                    icon: Icons.payments_outlined,
                    title: 'No collections found',
                    description: 'No payments match the selected criteria.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = payments[index];
                      final c = customerMap[p.customerId];

                      return CustomCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.receipt_rounded,
                                  color: AppColors.success, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          c?.customerName ?? 'Customer',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.formatPaise(
                                            p.amountReceived),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.successDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    c?.shopName ?? '-',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: p.isBank
                                              ? AppColors.primary.withOpacity(0.1)
                                              : AppColors.success.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${p.accountType} • ${p.paymentMethod}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: p.isBank
                                                ? AppColors.primary
                                                : AppColors.successDark,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        DateFormatter.formatDateTime(
                                            p.paymentDate),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.lightTextMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (p.remarks.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Remarks: ${p.remarks}',
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
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
