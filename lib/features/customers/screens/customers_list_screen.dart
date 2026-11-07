import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/stat_badge.dart';
import '../models/customer_model.dart';
import '../providers/customers_provider.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';
import 'add_payment_dialog.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  final bool selectForPayment;

  const CustomersListScreen({super.key, this.selectForPayment = false});

  @override
  ConsumerState<CustomersListScreen> createState() =>
      _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final currentSort = ref.watch(customersProvider).sortBy;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Sort Customers By',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.access_time_rounded),
                title: const Text('Recently Added'),
                trailing: currentSort == 'recent'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(customersProvider.notifier).setSortBy('recent');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha_rounded),
                title: const Text('Customer Name (A-Z)'),
                trailing: currentSort == 'name'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref.read(customersProvider.notifier).setSortBy('name');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward_rounded),
                title: const Text('Highest Outstanding Balance'),
                trailing: currentSort == 'balance_high'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref
                      .read(customersProvider.notifier)
                      .setSortBy('balance_high');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward_rounded),
                title: const Text('Lowest Outstanding Balance'),
                trailing: currentSort == 'balance_low'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  ref
                      .read(customersProvider.notifier)
                      .setSortBy('balance_low');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectForPayment
            ? 'Select Customer for Payment'
            : 'Customers Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: () => _showSortBottomSheet(context),
            tooltip: 'Sort List',
          ),
          if (!widget.selectForPayment)
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded,
                  color: AppColors.primary),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const CustomerFormScreen()),
                );
              },
              tooltip: 'Add Customer',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => ref
                      .read(customersProvider.notifier)
                      .setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search by customer, shop, work details...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(customersProvider.notifier)
                                  .setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(
                          'All Statuses',
                          style: TextStyle(
                            color: state.workStatusFilter == null
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : const Color(0xFF1E293B)),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        selected: state.workStatusFilter == null,
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.white,
                        backgroundColor: isDark
                            ? AppColors.darkCard
                            : const Color(0xFFF1F5F9),
                        side: BorderSide(
                          color: state.workStatusFilter == null
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFCBD5E1)),
                          width: 1.5,
                        ),
                        onSelected: (_) => ref
                            .read(customersProvider.notifier)
                            .setWorkStatusFilter(null),
                      ),
                      const SizedBox(width: 8),
                      ...AppConstants.workStatuses.map((status) {
                        final isSelected = state.workStatusFilter == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              status,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : const Color(0xFF1E293B)),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            checkmarkColor: Colors.white,
                            backgroundColor: isDark
                                ? AppColors.darkCard
                                : const Color(0xFFF1F5F9),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : const Color(0xFFCBD5E1)),
                              width: 1.5,
                            ),
                            onSelected: (_) => ref
                                .read(customersProvider.notifier)
                                .setWorkStatusFilter(
                                    isSelected ? null : status),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Customer list
          Expanded(
            child: state.filteredCustomers.isEmpty
                ? EmptyStateView(
                    icon: Icons.people_outline_rounded,
                    title: state.searchQuery.isNotEmpty
                        ? 'No matching customers'
                        : 'No customers yet',
                    description: state.searchQuery.isNotEmpty
                        ? 'Try modifying your search or filter options.'
                        : 'Add your first customer or convert an existing lead.',
                    buttonText: widget.selectForPayment ? null : 'Add Customer',
                    onButtonPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CustomerFormScreen()),
                      );
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.filteredCustomers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final customer = state.filteredCustomers[index];
                      return _CustomerCard(
                        customer: customer,
                        onTap: () {
                          if (widget.selectForPayment) {
                            AddPaymentDialog.show(context, customer);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CustomerDetailScreen(customer: customer),
                              ),
                            );
                          }
                        },
                        onAddPayment: () =>
                            AddPaymentDialog.show(context, customer),
                        onCall: () => _makeCall(customer.contactNumber),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.selectForPayment
          ? null
          : FloatingActionButton(
              heroTag: null,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const CustomerFormScreen()),
                );
              },
              tooltip: 'Add Customer',
              child: const Icon(Icons.add),
            ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onTap;
  final VoidCallback onAddPayment;
  final VoidCallback onCall;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
    required this.onAddPayment,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      borderColor: customer.hasOutstanding ? AppColors.danger.withOpacity(0.35) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Shop & Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.shopName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.customerName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatBadge.forWorkStatus(customer.workStatus),
            ],
          ),
          const SizedBox(height: 12),

          // Financial breakdown row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Work',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.lightTextMuted)),
                    Text(
                      CurrencyFormatter.formatPaise(customer.totalWorkAmount),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Received',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.lightTextMuted)),
                    Text(
                      CurrencyFormatter.formatPaise(
                          customer.totalAmountReceived),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.successDark,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Balance Due',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.lightTextMuted)),
                    Text(
                      CurrencyFormatter.formatPaise(customer.balanceAmount),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: customer.hasOutstanding
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (customer.contactNumber.isNotEmpty)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: onCall,
                  icon: const Icon(Icons.phone_outlined,
                      size: 16, color: AppColors.primary),
                  label: Text(customer.contactNumber,
                      style: const TextStyle(fontSize: 12)),
                )
              else
                const Text('No phone',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.lightTextMuted)),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.successDark,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onAddPayment,
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Add Payment',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
