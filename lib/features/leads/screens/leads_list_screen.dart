import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/stat_badge.dart';
import '../models/lead_model.dart';
import '../providers/leads_provider.dart';
import 'lead_detail_screen.dart';
import 'lead_form_screen.dart';
import '../../customers/screens/customer_form_screen.dart';

class LeadsListScreen extends ConsumerStatefulWidget {
  const LeadsListScreen({super.key});

  @override
  ConsumerState<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends ConsumerState<LeadsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _tabs = [
    {'key': 'active', 'label': 'Active Leads'},
    {'key': 'due', 'label': 'Follow-ups Due'},
    {'key': 'upcoming', 'label': 'Upcoming'},
    {'key': 'converted', 'label': 'Converted'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref
            .read(leadsProvider.notifier)
            .setActiveTab(_tabs[_tabController.index]['key']!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Future<void> _deleteLead(BuildContext context, LeadModel lead) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Delete Lead',
      message:
          'Are you sure you want to delete the lead for "${lead.customerName}" (${lead.shopName})? This action cannot be undone.',
      confirmText: 'Delete Lead',
      confirmColor: AppColors.danger,
    );

    if (confirm == true) {
      await ref.read(leadsProvider.notifier).deleteLead(lead.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead deleted successfully')),
        );
      }
    }
  }

  void _convertToCustomer(BuildContext context, LeadModel lead) {
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
  Widget build(BuildContext context) {
    final state = ref.watch(leadsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LeadFormScreen()),
              );
            },
            tooltip: 'Add Lead',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(
                child: Row(
                  children: [
                    const Text('Active'),
                    const SizedBox(width: 6),
                    _CountBadge(count: state.totalActiveCount),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    const Text('Due Follow-up'),
                    const SizedBox(width: 6),
                    _CountBadge(
                      count: state.followUpsDueTodayCount,
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    const Text('Upcoming'),
                    const SizedBox(width: 6),
                    _CountBadge(count: state.upcomingFollowUpsCount),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    const Text('Converted'),
                    const SizedBox(width: 6),
                    _CountBadge(
                      count: state.convertedCount,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) =>
                      ref.read(leadsProvider.notifier).setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search by shop name, customer, phone...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(leadsProvider.notifier)
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

                // Response Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(
                          'All Statuses',
                          style: TextStyle(
                            color: state.statusFilter == null
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : const Color(0xFF1E293B)),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        selected: state.statusFilter == null,
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.white,
                        backgroundColor: isDark
                            ? AppColors.darkCard
                            : const Color(0xFFF1F5F9),
                        side: BorderSide(
                          color: state.statusFilter == null
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFCBD5E1)),
                          width: 1.5,
                        ),
                        onSelected: (_) => ref
                            .read(leadsProvider.notifier)
                            .setStatusFilter(null),
                      ),
                      const SizedBox(width: 8),
                      ...AppConstants.leadStatuses.map((status) {
                        final isSelected = state.statusFilter == status;
                        Color statusColor;
                        Color statusBg;
                        Color statusBorder;
                        Color unselectedTextColor;

                        switch (status) {
                          case AppConstants.leadStatusInterested:
                            statusColor = AppColors.successDark;
                            statusBg = isDark
                                ? const Color(0xFF064E3B)
                                : const Color(0xFFD1FAE5);
                            statusBorder = isDark
                                ? AppColors.success
                                : const Color(0xFF10B981);
                            unselectedTextColor = isDark
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFF065F46);
                            break;
                          case AppConstants.leadStatusFollowUp:
                            statusColor = const Color(0xFFD97706);
                            statusBg = isDark
                                ? const Color(0xFF451A03)
                                : const Color(0xFFFEF3C7);
                            statusBorder = isDark
                                ? AppColors.warning
                                : const Color(0xFFF59E0B);
                            unselectedTextColor = isDark
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFF92400E);
                            break;
                          case AppConstants.leadStatusDNP:
                            statusColor = AppColors.dangerDark;
                            statusBg = isDark
                                ? const Color(0xFF450A0A)
                                : const Color(0xFFFEE2E2);
                            statusBorder = isDark
                                ? AppColors.danger
                                : const Color(0xFFEF4444);
                            unselectedTextColor = isDark
                                ? const Color(0xFFFECDD3)
                                : const Color(0xFF9F1239);
                            break;
                          default:
                            statusColor = AppColors.primary;
                            statusBg = isDark
                                ? AppColors.darkCard
                                : const Color(0xFFF1F5F9);
                            statusBorder = isDark
                                ? AppColors.darkBorder
                                : const Color(0xFFCBD5E1);
                            unselectedTextColor = isDark
                                ? AppColors.darkTextPrimary
                                : const Color(0xFF1E293B);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              status,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : unselectedTextColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: statusColor,
                            checkmarkColor: Colors.white,
                            backgroundColor: statusBg,
                            side: BorderSide(
                              color: isSelected ? statusColor : statusBorder,
                              width: 1.5,
                            ),
                            onSelected: (_) => ref
                                .read(leadsProvider.notifier)
                                .setStatusFilter(isSelected ? null : status),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Leads List
          Expanded(
            child: state.filteredLeads.isEmpty
                ? EmptyStateView(
                    icon: Icons.contact_phone_outlined,
                    title: state.searchQuery.isNotEmpty
                        ? 'No matching leads'
                        : 'No leads in this section',
                    description: state.searchQuery.isNotEmpty
                        ? 'Try modifying your search or filter criteria.'
                        : 'Generate a new lead to start tracking business prospects.',
                    buttonText: 'Add New Lead',
                    onButtonPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const LeadFormScreen()),
                      );
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.filteredLeads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final lead = state.filteredLeads[index];
                      return _LeadCard(
                        lead: lead,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LeadDetailScreen(lead: lead),
                            ),
                          );
                        },
                        onCall: () => _makeCall(lead.contactNumber),
                        onConvert: () => _convertToCustomer(context, lead),
                        onDelete: () => _deleteLead(context, lead),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LeadFormScreen()),
          );
        },
        tooltip: 'Add Lead',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color? color;

  const _CountBadge({required this.count, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final LeadModel lead;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onConvert;
  final VoidCallback onDelete;

  const _LeadCard({
    required this.lead,
    required this.onTap,
    required this.onCall,
    required this.onConvert,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Distinct border highlighting for Interested, Due, or DNP
    Color? highlightBorder;
    if (lead.isDue) {
      highlightBorder = AppColors.warning;
    } else if (lead.isInterested) {
      highlightBorder = AppColors.teal;
    }

    return CustomCard(
      onTap: onTap,
      borderColor: highlightBorder,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Shop Name & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.shopName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lead.customerName,
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
              StatBadge.forLeadStatus(lead.responseStatus),
            ],
          ),
          const SizedBox(height: 10),

          // Follow-up Info
          if (lead.nextFollowUpDate != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (lead.isDue
                        ? AppColors.warningLight
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9)))
                    .withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    lead.isDue
                        ? Icons.warning_amber_rounded
                        : Icons.event_repeat_rounded,
                    size: 14,
                    color: lead.isDue ? AppColors.warningDark : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Follow-up: ${DateFormatter.formatDate(lead.nextFollowUpDate)}${lead.nextFollowUpTime != null ? " at ${lead.nextFollowUpTime}" : ""}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          lead.isDue ? AppColors.warningDark : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Remarks snippet if present
          if (lead.customerRemarks.isNotEmpty) ...[
            Text(
              lead.customerRemarks,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Added ${DateFormatter.formatDate(lead.createdAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
              Row(
                children: [
                  if (lead.contactNumber.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone_outlined,
                          size: 20, color: AppColors.success),
                      onPressed: onCall,
                      tooltip: 'Call Lead',
                    ),
                  if (!lead.isConverted)
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1_outlined,
                          size: 20, color: AppColors.indigo),
                      onPressed: onConvert,
                      tooltip: 'Convert to Customer',
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: AppColors.danger),
                    onPressed: onDelete,
                    tooltip: 'Delete Lead',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
