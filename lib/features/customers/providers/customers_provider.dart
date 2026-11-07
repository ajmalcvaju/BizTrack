import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/customer_model.dart';
import '../models/payment_model.dart';

class CustomersState {
  final List<CustomerModel> allCustomers;
  final Map<String, List<PaymentModel>> paymentsByCustomer;
  final bool isLoading;
  final String searchQuery;
  final String? workStatusFilter;
  final String sortBy; // 'name', 'recent', 'balance_high', 'balance_low'

  const CustomersState({
    this.allCustomers = const [],
    this.paymentsByCustomer = const {},
    this.isLoading = false,
    this.searchQuery = '',
    this.workStatusFilter,
    this.sortBy = 'recent',
  });

  List<CustomerModel> get filteredCustomers {
    var list = [...allCustomers];

    if (workStatusFilter != null && workStatusFilter!.isNotEmpty) {
      list = list.where((c) => c.workStatus == workStatusFilter).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((c) =>
          c.shopName.toLowerCase().contains(q) ||
          c.customerName.toLowerCase().contains(q) ||
          c.contactNumber.contains(q) ||
          c.workDetails.toLowerCase().contains(q)).toList();
    }

    switch (sortBy) {
      case 'name':
        list.sort((a, b) => a.customerName.compareTo(b.customerName));
        break;
      case 'balance_high':
        list.sort((a, b) => b.balanceAmount.compareTo(a.balanceAmount));
        break;
      case 'balance_low':
        list.sort((a, b) => a.balanceAmount.compareTo(b.balanceAmount));
        break;
      case 'recent':
      default:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return list;
  }

  // Outstanding splits
  // 1. Balance amount to be collected from completed work
  int get completedWorkOutstandingPaise {
    return allCustomers
        .where((c) => c.isCompleted && c.balanceAmount > 0)
        .fold(0, (sum, c) => sum + c.balanceAmount);
  }

  // 2. Balance amount to be collected from incomplete work
  int get incompleteWorkOutstandingPaise {
    return allCustomers
        .where((c) => c.isIncomplete && c.balanceAmount > 0)
        .fold(0, (sum, c) => sum + c.balanceAmount);
  }

  int get totalOutstandingPaise =>
      completedWorkOutstandingPaise + incompleteWorkOutstandingPaise;

  int get totalReceivedPaise =>
      allCustomers.fold(0, (sum, c) => sum + c.totalAmountReceived);

  int get totalWorkAmountPaise =>
      allCustomers.fold(0, (sum, c) => sum + c.totalWorkAmount);

  // All payments flattened for collection history
  List<PaymentModel> get allPayments {
    final list = <PaymentModel>[];
    paymentsByCustomer.forEach((_, payments) {
      list.addAll(payments);
    });
    list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return list;
  }

  CustomersState copyWith({
    List<CustomerModel>? allCustomers,
    Map<String, List<PaymentModel>>? paymentsByCustomer,
    bool? isLoading,
    String? searchQuery,
    String? workStatusFilter,
    bool clearWorkStatusFilter = false,
    String? sortBy,
  }) {
    return CustomersState(
      allCustomers: allCustomers ?? this.allCustomers,
      paymentsByCustomer: paymentsByCustomer ?? this.paymentsByCustomer,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      workStatusFilter: clearWorkStatusFilter
          ? null
          : (workStatusFilter ?? this.workStatusFilter),
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class CustomersNotifier extends StateNotifier<CustomersState> {
  final FirebaseService _service = FirebaseService();
  final Ref _ref;
  StreamSubscription? _subscription;
  final Map<String, StreamSubscription> _paymentSubs = {};

  CustomersNotifier(this._ref) : super(const CustomersState(isLoading: true)) {
    _init();
  }

  void _init() {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        _subscribeToCustomers(next.isDemoUser);
      } else {
        _clear();
      }
    });

    final currentAuth = _ref.read(authProvider);
    if (currentAuth.isAuthenticated) {
      _subscribeToCustomers(currentAuth.isDemoUser);
    }
  }

  void _clear() {
    _subscription?.cancel();
    for (final s in _paymentSubs.values) {
      s.cancel();
    }
    _paymentSubs.clear();
    state = const CustomersState();
  }

  void _subscribeToCustomers(bool isDemo) {
    _clear();
    if (isDemo) {
      state = state.copyWith(
        allCustomers: _sampleCustomers,
        paymentsByCustomer: _samplePayments,
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(isLoading: true);
    _subscription = _service.streamCustomers().listen(
      (customers) {
        state = state.copyWith(allCustomers: customers, isLoading: false);
        _listenToAllCustomerPayments(customers);
      },
      onError: (_) {
        if (state.allCustomers.isEmpty) {
          state = state.copyWith(
            allCustomers: _sampleCustomers,
            paymentsByCustomer: _samplePayments,
            isLoading: false,
          );
        }
      },
    );
  }

  void _listenToAllCustomerPayments(List<CustomerModel> customers) {
    for (final customer in customers) {
      if (!_paymentSubs.containsKey(customer.id)) {
        _paymentSubs[customer.id] =
            _service.streamCustomerPayments(customer.id).listen((payments) {
          final updated = Map<String, List<PaymentModel>>.from(state.paymentsByCustomer);
          updated[customer.id] = payments;
          state = state.copyWith(paymentsByCustomer: updated);
        });
      }
    }
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setWorkStatusFilter(String? status) {
    state = state.copyWith(
      workStatusFilter: status,
      clearWorkStatusFilter: status == null,
    );
  }

  void setSortBy(String sort) {
    state = state.copyWith(sortBy: sort);
  }

  Future<String> addCustomer(CustomerModel customer) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    final id = customer.id.isEmpty ? const Uuid().v4() : customer.id;
    final finalCust = customer.copyWith(
      totalWorkAmount: customer.totalWorkAmount,
      totalAmountReceived: customer.totalAmountReceived,
    );
    final withId = CustomerModel(
      id: id,
      shopName: finalCust.shopName,
      customerName: finalCust.customerName,
      contactNumber: finalCust.contactNumber,
      address: finalCust.address,
      workDetails: finalCust.workDetails,
      workStatus: finalCust.workStatus,
      customerRemarks: finalCust.customerRemarks,
      totalWorkAmount: finalCust.totalWorkAmount,
      totalAmountReceived: finalCust.totalAmountReceived,
      createdAt: DateTime.now(),
    );

    if (isDemo) {
      state = state.copyWith(
        allCustomers: [withId, ...state.allCustomers],
      );
      return id;
    } else {
      return await _service.addCustomer(withId);
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    if (isDemo) {
      final updated =
          state.allCustomers.map((c) => c.id == customer.id ? customer : c).toList();
      state = state.copyWith(allCustomers: updated);
    } else {
      await _service.updateCustomer(customer);
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    if (isDemo) {
      final updatedCusts =
          state.allCustomers.where((c) => c.id != customerId).toList();
      final updatedPayments =
          Map<String, List<PaymentModel>>.from(state.paymentsByCustomer)
            ..remove(customerId);
      state = state.copyWith(
        allCustomers: updatedCusts,
        paymentsByCustomer: updatedPayments,
      );
    } else {
      await _service.deleteCustomer(customerId);
    }
  }

  Future<void> addPayment({
    required CustomerModel customer,
    required int amountReceivedPaise,
    required String paymentMethod,
    required String remarks,
    required DateTime paymentDate,
    String? accountType,
  }) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    final resolvedAccountType = accountType ??
        (paymentMethod == AppConstants.paymentMethodCash
            ? AppConstants.accountTypeCash
            : AppConstants.accountTypeBank);

    final newPayment = PaymentModel(
      id: const Uuid().v4(),
      customerId: customer.id,
      amountReceived: amountReceivedPaise,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod,
      accountType: resolvedAccountType,
      remarks: remarks,
      createdAt: DateTime.now(),
    );

    if (isDemo) {
      final existingPayments =
          state.paymentsByCustomer[customer.id] ?? <PaymentModel>[];
      final updatedPaymentsMap =
          Map<String, List<PaymentModel>>.from(state.paymentsByCustomer);
      updatedPaymentsMap[customer.id] = [newPayment, ...existingPayments];

      final newTotalReceived =
          customer.totalAmountReceived + amountReceivedPaise;
      final newBalance = customer.totalWorkAmount - newTotalReceived;
      final updatedCustomer = customer.copyWith(
        totalAmountReceived: newTotalReceived,
        balanceAmount: newBalance,
      );

      final updatedCustomers = state.allCustomers
          .map((c) => c.id == customer.id ? updatedCustomer : c)
          .toList();

      state = state.copyWith(
        allCustomers: updatedCustomers,
        paymentsByCustomer: updatedPaymentsMap,
      );
    } else {
      await _service.recordPayment(
        customer: customer,
        amountReceived: amountReceivedPaise,
        paymentMethod: paymentMethod,
        accountType: resolvedAccountType,
        remarks: remarks,
        paymentDate: paymentDate,
      );
    }
  }

  Future<void> deletePayment({
    required CustomerModel customer,
    required PaymentModel payment,
  }) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    if (isDemo) {
      final existingPayments =
          state.paymentsByCustomer[customer.id] ?? <PaymentModel>[];
      final filteredPayments =
          existingPayments.where((p) => p.id != payment.id).toList();
      final updatedPaymentsMap =
          Map<String, List<PaymentModel>>.from(state.paymentsByCustomer);
      updatedPaymentsMap[customer.id] = filteredPayments;

      final newTotalReceived =
          (customer.totalAmountReceived - payment.amountReceived)
              .clamp(0, double.infinity)
              .toInt();
      final newBalance = customer.totalWorkAmount - newTotalReceived;
      final updatedCustomer = customer.copyWith(
        totalAmountReceived: newTotalReceived,
        balanceAmount: newBalance,
      );

      final updatedCustomers = state.allCustomers
          .map((c) => c.id == customer.id ? updatedCustomer : c)
          .toList();

      state = state.copyWith(
        allCustomers: updatedCustomers,
        paymentsByCustomer: updatedPaymentsMap,
      );
    } else {
      await _service.deletePayment(
        customer: customer,
        payment: payment,
      );
    }
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  static final List<CustomerModel> _sampleCustomers = [
    CustomerModel(
      id: 'cust-1',
      shopName: 'Apex Fashion Studio',
      customerName: 'Priya Mehta',
      contactNumber: '+91 98765 11223',
      address: '22, Fashion Street, Bandra West, Mumbai',
      workDetails: 'E-commerce website & catalog mobile app with online payment integration',
      workStatus: AppConstants.workStatusCompleted,
      customerRemarks: 'Work delivered. Final payment milestone remaining.',
      totalWorkAmount: 8500000, // ₹85,000.00
      totalAmountReceived: 6500000, // ₹65,000.00
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    CustomerModel(
      id: 'cust-2',
      shopName: 'Metro Hardware Mart',
      customerName: 'Sunil Kulkarni',
      contactNumber: '+91 98765 22334',
      address: 'Shop 4, Market Yard, Pune',
      workDetails: 'Inventory tracking and barcode billing system',
      workStatus: AppConstants.workStatusInProgress,
      customerRemarks: 'Hardware integrated. User training scheduled for next week.',
      totalWorkAmount: 5000000, // ₹50,000.00
      totalAmountReceived: 2000000, // ₹20,000.00
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    CustomerModel(
      id: 'cust-3',
      shopName: 'Delight Sweets & Restaurant',
      customerName: 'Harish Aggarwal',
      contactNumber: '+91 98765 33445',
      address: 'Near Clock Tower, Ludhiana',
      workDetails: 'Kitchen Order Ticketing (KOT) system and loyalty program',
      workStatus: AppConstants.workStatusInReview,
      customerRemarks: 'Reviewing pilot trial in 1 branch.',
      totalWorkAmount: 12000000, // ₹1,20,000.00
      totalAmountReceived: 6000000, // ₹60,000.00
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    CustomerModel(
      id: 'cust-4',
      shopName: 'City Dental Clinic',
      customerName: 'Dr. Neha Kapoor',
      contactNumber: '+91 98765 44556',
      address: 'Suite 204, MedPlus Center, Bengaluru',
      workDetails: 'Patient appointment scheduler and SMS reminder service',
      workStatus: AppConstants.workStatusCompleted,
      customerRemarks: 'All payments settled in full.',
      totalWorkAmount: 4000000, // ₹40,000.00
      totalAmountReceived: 4000000, // ₹40,000.00
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
  ];

  static final Map<String, List<PaymentModel>> _samplePayments = {
    'cust-1': [
      PaymentModel(
        id: 'p-1',
        customerId: 'cust-1',
        amountReceived: 5000000, // ₹50,000
        paymentDate: DateTime.now().subtract(const Duration(days: 28)),
        paymentMethod: AppConstants.paymentMethodBankTransfer,
        accountType: AppConstants.accountTypeBank,
        remarks: 'Advance initial deposit (50%)',
        createdAt: DateTime.now().subtract(const Duration(days: 28)),
      ),
      PaymentModel(
        id: 'p-2',
        customerId: 'cust-1',
        amountReceived: 1500000, // ₹15,000
        paymentDate: DateTime.now().subtract(const Duration(days: 5)),
        paymentMethod: AppConstants.paymentMethodUPI,
        accountType: AppConstants.accountTypeBank,
        remarks: 'Milestone 2 completion payment',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ],
    'cust-2': [
      PaymentModel(
        id: 'p-3',
        customerId: 'cust-2',
        amountReceived: 2000000, // ₹20,000
        paymentDate: DateTime.now().subtract(const Duration(days: 14)),
        paymentMethod: AppConstants.paymentMethodUPI,
        accountType: AppConstants.accountTypeBank,
        remarks: 'Project kickoff advance',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
    ],
    'cust-3': [
      PaymentModel(
        id: 'p-4',
        customerId: 'cust-3',
        amountReceived: 6000000, // ₹60,000
        paymentDate: DateTime.now().subtract(const Duration(days: 9)),
        paymentMethod: AppConstants.paymentMethodBankTransfer,
        accountType: AppConstants.accountTypeBank,
        remarks: 'Phase 1 development payment',
        createdAt: DateTime.now().subtract(const Duration(days: 9)),
      ),
    ],
    'cust-4': [
      PaymentModel(
        id: 'p-5',
        customerId: 'cust-4',
        amountReceived: 2000000,
        paymentDate: DateTime.now().subtract(const Duration(days: 44)),
        paymentMethod: AppConstants.paymentMethodCash,
        accountType: AppConstants.accountTypeCash,
        remarks: 'Advance token',
        createdAt: DateTime.now().subtract(const Duration(days: 44)),
      ),
      PaymentModel(
        id: 'p-6',
        customerId: 'cust-4',
        amountReceived: 2000000,
        paymentDate: DateTime.now().subtract(const Duration(days: 20)),
        paymentMethod: AppConstants.paymentMethodUPI,
        accountType: AppConstants.accountTypeBank,
        remarks: 'Final settlement payment',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ],
  };
}

final customersProvider =
    StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
  return CustomersNotifier(ref);
});
