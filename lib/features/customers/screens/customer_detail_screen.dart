import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/stat_badge.dart';
import '../models/customer_model.dart';
import '../models/payment_model.dart';
import '../providers/customers_provider.dart';
import 'customer_form_screen.dart';
import 'add_payment_dialog.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  Future<void> _makeCall(BuildContext context, String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number for this customer.')),
      );
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _deleteCustomer(BuildContext context, WidgetRef ref) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Delete Customer',
      message:
          'Are you sure you want to delete "${customer.customerName}" (${customer.shopName}) and all associated payment records? This cannot be undone.',
      confirmText: 'Delete Record',
      confirmColor: AppColors.danger,
    );

    if (confirm == true) {
      await ref.read(customersProvider.notifier).deleteCustomer(customer.id);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer record deleted.')),
        );
      }
    }
  }

  Future<void> _deletePayment(
    BuildContext context,
    WidgetRef ref,
    PaymentModel payment,
  ) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Delete Payment',
      message:
          'Delete payment of ${CurrencyFormatter.formatPaise(payment.amountReceived)}? The customer\'s balance will automatically adjust.',
      confirmText: 'Delete Payment',
      confirmColor: AppColors.danger,
    );

    if (confirm == true) {
      await ref.read(customersProvider.notifier).deletePayment(
            customer: customer,
            payment: payment,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment deleted & balance restored.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customersProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Retrieve fresh customer data from provider to reflect realtime balance updates
    final currentCustomer = state.allCustomers.firstWhere(
      (c) => c.id == customer.id,
      orElse: () => customer,
    );

    final payments = state.paymentsByCustomer[currentCustomer.id] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentCustomer.shopName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CustomerFormScreen(initialCustomer: currentCustomer),
                ),
              );
            },
            tooltip: 'Edit Customer',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _deleteCustomer(context, ref),
            tooltip: 'Delete Customer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Customer Profile Card
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.indigo.withOpacity(0.12),
                    child: Text(
                      currentCustomer.customerName.isNotEmpty
                          ? currentCustomer.customerName[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.indigo,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentCustomer.customerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentCustomer.shopName,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        StatBadge.forWorkStatus(currentCustomer.workStatus),
                      ],
                    ),
                  ),
                  if (currentCustomer.contactNumber.isNotEmpty)
                    IconButton.filledTonal(
                      icon: const Icon(Icons.phone),
                      onPressed: () =>
                          _makeCall(context, currentCustomer.contactNumber),
                      tooltip: 'Call Customer',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Prominent Financial Balance Card
            CustomCard(
              padding: const EdgeInsets.all(20),
              color: currentCustomer.hasOutstanding
                  ? (isDark ? const Color(0xFF2C1919) : const Color(0xFFFEF2F2))
                  : (isDark ? const Color(0xFF14271F) : const Color(0xFFF0FDF4)),
              borderColor: currentCustomer.hasOutstanding
                  ? AppColors.danger.withOpacity(0.4)
                  : AppColors.success.withOpacity(0.4),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Outstanding Balance',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightTextMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatPaise(
                                currentCustomer.balanceAmount),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: currentCustomer.hasOutstanding
                                  ? AppColors.danger
                                  : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onPressed: () =>
                            AddPaymentDialog.show(context, currentCustomer),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Record Payment'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Work Amount',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.lightTextMuted),
                          ),
                          Text(
                            CurrencyFormatter.formatPaise(
                                currentCustomer.totalWorkAmount),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Amount Received',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.lightTextMuted),
                          ),
                          Text(
                            CurrencyFormatter.formatPaise(
                                currentCustomer.totalAmountReceived),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.successDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Work Details & Remarks Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Work & Project Details',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentCustomer.workDetails.isNotEmpty
                        ? currentCustomer.workDetails
                        : 'No work details recorded.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  if (currentCustomer.address.isNotEmpty) ...[
                    const Divider(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentCustomer.address,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (currentCustomer.customerRemarks.isNotEmpty) ...[
                    const Divider(height: 20),
                    Text(
                      'Remarks: ${currentCustomer.customerRemarks}',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${payments.length} Payments',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.lightTextMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (payments.isEmpty)
              CustomCard(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 40, color: AppColors.lightTextMuted),
                      const SizedBox(height: 8),
                      const Text(
                        'No payments recorded yet',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap "Record Payment" to log cash, UPI, or bank transfer payments.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final p = payments[index];
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
                          child: const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                CurrencyFormatter.formatPaise(p.amountReceived),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.successDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${p.paymentMethod} • ${DateFormatter.formatDate(p.paymentDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              if (p.remarks.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  p.remarks,
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
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: AppColors.danger),
                          onPressed: () => _deletePayment(context, ref, p),
                          tooltip: 'Delete Payment',
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
