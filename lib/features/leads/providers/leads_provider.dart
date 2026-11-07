import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/notification_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/lead_model.dart';

class LeadsState {
  final List<LeadModel> allLeads;
  final bool isLoading;
  final String searchQuery;
  final String? statusFilter; // All, Follow Up, Interested, DNP
  final String activeTab; // 'active', 'due', 'upcoming', 'converted'

  const LeadsState({
    this.allLeads = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.statusFilter,
    this.activeTab = 'active',
  });

  // Filtered Leads
  List<LeadModel> get filteredLeads {
    List<LeadModel> list;
    switch (activeTab) {
      case 'due':
        list = allLeads.where((l) => !l.isConverted && l.isDue).toList();
        break;
      case 'upcoming':
        list = allLeads.where((l) => !l.isConverted && l.isUpcoming).toList();
        break;
      case 'converted':
        list = allLeads.where((l) => l.isConverted).toList();
        break;
      case 'active':
      default:
        // Active leads are unconverted leads that either have no follow-up scheduled OR are due
        // Requirement: "When a lead has a future follow-up date and time, hide it from the active leads list until the scheduled time. When the scheduled follow-up time arrives, automatically make the lead visible again in the active follow-up list."
        list = allLeads.where((l) => !l.isConverted && !l.isUpcoming).toList();
        break;
    }

    if (statusFilter != null && statusFilter!.isNotEmpty) {
      list = list.where((l) => l.responseStatus == statusFilter).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((l) =>
          l.shopName.toLowerCase().contains(q) ||
          l.customerName.toLowerCase().contains(q) ||
          l.contactNumber.contains(q)).toList();
    }

    return list;
  }

  // Counts for dashboard & badges
  int get totalActiveCount => allLeads.where((l) => !l.isConverted).length;
  int get followUpsDueTodayCount =>
      allLeads.where((l) => !l.isConverted && l.isDue).length;
  int get upcomingFollowUpsCount =>
      allLeads.where((l) => !l.isConverted && l.isUpcoming).length;
  int get convertedCount => allLeads.where((l) => l.isConverted).length;

  LeadsState copyWith({
    List<LeadModel>? allLeads,
    bool? isLoading,
    String? searchQuery,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? activeTab,
  }) {
    return LeadsState(
      allLeads: allLeads ?? this.allLeads,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

class LeadsNotifier extends StateNotifier<LeadsState> {
  final FirebaseService _service = FirebaseService();
  final Ref _ref;
  StreamSubscription? _subscription;

  LeadsNotifier(this._ref) : super(const LeadsState(isLoading: true)) {
    _init();
  }

  void _init() {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        _subscribeToLeads(next.isDemoUser);
      } else {
        _subscription?.cancel();
        state = const LeadsState();
      }
    });

    final currentAuth = _ref.read(authProvider);
    if (currentAuth.isAuthenticated) {
      _subscribeToLeads(currentAuth.isDemoUser);
    }
  }

  void _subscribeToLeads(bool isDemo) {
    _subscription?.cancel();
    if (isDemo) {
      state = state.copyWith(
        allLeads: _sampleLeads,
        isLoading: false,
      );
      _checkNotifications(_sampleLeads);
      return;
    }

    state = state.copyWith(isLoading: true);
    _subscription = _service.streamLeads().listen(
      (leads) {
        state = state.copyWith(allLeads: leads, isLoading: false);
        _checkNotifications(leads);
      },
      onError: (_) {
        // Fallback to sample data if Firestore not yet initialized
        if (state.allLeads.isEmpty) {
          state = state.copyWith(allLeads: _sampleLeads, isLoading: false);
        }
      },
    );
  }

  void _checkNotifications(List<LeadModel> leads) {
    for (final lead in leads) {
      if (!lead.isConverted && lead.isDue) {
        NotificationService().notifyLeadFollowup(
          leadId: lead.id,
          shopName: lead.shopName,
          customerName: lead.customerName,
          isDue: true,
        );
      }
    }
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status, clearStatusFilter: status == null);
  }

  void setActiveTab(String tab) {
    state = state.copyWith(activeTab: tab);
  }

  Future<void> addLead(LeadModel lead) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    final leadWithId = lead.id.isEmpty
        ? lead.copyWith(shopName: lead.shopName) // ensures instance
        : lead;
    final id = lead.id.isEmpty ? const Uuid().v4() : lead.id;
    final finalLead = LeadModel(
      id: id,
      shopName: lead.shopName,
      customerName: lead.customerName,
      createdAt: DateTime.now(),
      responseStatus: lead.responseStatus,
      nextFollowUpDate: lead.nextFollowUpDate,
      nextFollowUpTime: lead.nextFollowUpTime,
      customerRemarks: lead.customerRemarks,
      contactNumber: lead.contactNumber,
      address: lead.address,
      isConverted: lead.isConverted,
      convertedCustomerId: lead.convertedCustomerId,
    );

    if (isDemo) {
      state = state.copyWith(allLeads: [finalLead, ...state.allLeads]);
    } else {
      await _service.addLead(finalLead);
    }
  }

  Future<void> updateLead(LeadModel lead) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    if (isDemo) {
      final updated = state.allLeads.map((l) => l.id == lead.id ? lead : l).toList();
      state = state.copyWith(allLeads: updated);
    } else {
      await _service.updateLead(lead);
    }
  }

  Future<void> markLeadConverted(String leadId, String customerId) async {
    final lead = state.allLeads.firstWhere((l) => l.id == leadId);
    final updated = lead.copyWith(
      isConverted: true,
      convertedCustomerId: customerId,
    );
    await updateLead(updated);
  }

  Future<void> deleteLead(String leadId) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    if (isDemo) {
      state = state.copyWith(
        allLeads: state.allLeads.where((l) => l.id != leadId).toList(),
      );
    } else {
      await _service.deleteLead(leadId);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  static final List<LeadModel> _sampleLeads = [
    LeadModel(
      id: 'lead-1',
      shopName: 'Sharma Electronics',
      customerName: 'Amit Sharma',
      contactNumber: '+91 98111 22334',
      address: 'Shop 12, Main Market, Sector 18, Noida',
      responseStatus: AppConstants.leadStatusInterested,
      nextFollowUpDate: DateTime.now(),
      nextFollowUpTime: '02:30 PM',
      customerRemarks: 'Looking for POS billing software and 2 barcode scanners. Interested in premium tier.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    LeadModel(
      id: 'lead-2',
      shopName: 'Gupta Cloth Store',
      customerName: 'Ramesh Gupta',
      contactNumber: '+91 98222 33445',
      address: 'Plot 45, Chandni Chowk, Delhi',
      responseStatus: AppConstants.leadStatusFollowUp,
      nextFollowUpDate: DateTime.now().add(const Duration(days: 2)),
      nextFollowUpTime: '11:00 AM',
      customerRemarks: 'Needs GST billing setup. Asked to call on weekend morning.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    LeadModel(
      id: 'lead-3',
      shopName: 'Royal Auto Spares',
      customerName: 'Vikram Singh',
      contactNumber: '+91 98333 44556',
      address: 'Industrial Area Phase 2, Gurgaon',
      responseStatus: AppConstants.leadStatusDNP,
      nextFollowUpDate: DateTime.now().subtract(const Duration(hours: 4)),
      nextFollowUpTime: '10:00 AM',
      customerRemarks: 'Called twice, did not pick up. Will try in evening.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    LeadModel(
      id: 'lead-4',
      shopName: 'Krishna Bakery & Cafe',
      customerName: 'Manish Verma',
      contactNumber: '+91 98444 55667',
      address: 'Civil Lines, Jaipur',
      responseStatus: AppConstants.leadStatusInterested,
      nextFollowUpDate: null,
      customerRemarks: 'Met in person. Confirmed demo for next week.',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];
}

final leadsProvider = StateNotifierProvider<LeadsNotifier, LeadsState>((ref) {
  return LeadsNotifier(ref);
});
