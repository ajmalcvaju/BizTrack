import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/stat_badge.dart';
import '../models/lead_model.dart';
import '../providers/leads_provider.dart';
import 'lead_form_screen.dart';
import '../../customers/screens/customer_form_screen.dart';

class LeadDetailScreen extends ConsumerWidget {
  final LeadModel lead;

  const LeadDetailScreen({super.key, required this.lead});

  Future<void> _makeCall(BuildContext context, String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number saved for this lead.')),
      );
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _deleteLead(BuildContext context, WidgetRef ref) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Delete Lead',
      message:
          'Are you sure you want to delete the lead for "${lead.customerName}"? This action cannot be undone.',
      confirmText: 'Delete Lead',
      confirmColor: AppColors.danger,
    );

    if (confirm == true && context.mounted) {
      await ref.read(leadsProvider.notifier).deleteLead(lead.id);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead removed.')),
      );
    }
  }

  void _convertToCustomer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerFormScreen(
          prefilledLeadId: lead.id,
          initialShopName: lead.shopName,
          initialCustomerName: lead.customerName,
          initialPhone: lead.contactNumber,
          initialAddress: lead.address,
          initialRemarks: lead.customerRemarks,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(lead.shopName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LeadFormScreen(initialLead: lead),
                ),
              );
            },
            tooltip: 'Edit Lead',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _deleteLead(context, ref),
            tooltip: 'Delete Lead',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner Card
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      lead.customerName.isNotEmpty
                          ? lead.customerName[0].toUpperCase()
                          : 'L',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.customerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lead.shopName,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            StatBadge.forLeadStatus(lead.responseStatus),
                            if (lead.isConverted) ...[
                              const SizedBox(width: 8),
                              const StatBadge(
                                label: 'CONVERTED',
                                color: AppColors.success,
                                icon: Icons.check_circle_rounded,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Convert to Customer button if not yet converted
            if (!lead.isConverted) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _convertToCustomer(context),
                icon: const Icon(Icons.how_to_reg_rounded, size: 20),
                label: const Text('Convert Lead to Customer'),
              ),
              const SizedBox(height: 16),
            ],

            // Follow-up Schedule Info
            CustomCard(
              padding: const EdgeInsets.all(16),
              borderColor: lead.isDue
                  ? AppColors.warning
                  : (lead.isUpcoming ? AppColors.primary : null),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Follow-up Schedule',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (lead.isDue)
                        const StatBadge(
                          label: 'DUE NOW',
                          color: AppColors.warning,
                          icon: Icons.timer_outlined,
                        )
                      else if (lead.isUpcoming)
                        const StatBadge(
                          label: 'UPCOMING',
                          color: AppColors.primary,
                          icon: Icons.upcoming_rounded,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (lead.nextFollowUpDate != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          DateFormatter.formatDate(lead.nextFollowUpDate),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (lead.nextFollowUpTime != null) ...[
                          const SizedBox(width: 14),
                          const Icon(Icons.access_time_rounded,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            lead.nextFollowUpTime!,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'No specific follow-up date scheduled.',
                      style: TextStyle(color: AppColors.lightTextMuted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact & Location Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact & Location',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if (lead.contactNumber.isNotEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.successLight,
                        child: Icon(Icons.phone, color: AppColors.successDark),
                      ),
                      title: Text(lead.contactNumber),
                      subtitle: const Text('Tap to call directly'),
                      trailing: IconButton(
                        icon: const Icon(Icons.call, color: AppColors.success),
                        onPressed: () => _makeCall(context, lead.contactNumber),
                      ),
                      onTap: () => _makeCall(context, lead.contactNumber),
                    )
                  else
                    const Text('No contact number added.',
                        style: TextStyle(color: AppColors.lightTextMuted)),
                  if (lead.address.isNotEmpty) ...[
                    const Divider(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lead.address,
                            style: const TextStyle(height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Remarks Card
            CustomCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Remarks & Notes',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lead.customerRemarks.isNotEmpty
                        ? lead.customerRemarks
                        : 'No remarks recorded for this lead.',
                    style: TextStyle(
                      height: 1.4,
                      color: lead.customerRemarks.isNotEmpty
                          ? (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary)
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Generation Date
            Center(
              child: Text(
                'Lead generated on ${DateFormatter.formatDateTime(lead.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
