import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/notification_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/providers/customers_provider.dart';
import '../models/monthly_target_model.dart';
import '../models/expense_model.dart';
import '../models/future_expense_model.dart';
import '../models/account_transfer_model.dart';

class PaymentsState {
  final List<MonthlyTargetModel> targets;
  final List<ExpenseModel> expenses;
  final List<FutureExpenseModel> futureExpenses;
  final List<AccountTransferModel> transfers;
  final bool isLoading;
  final String selectedMonthYear; // e.g. "11-2026"
  final String? expenseCategoryFilter;

  const PaymentsState({
    this.targets = const [],
    this.expenses = const [],
    this.futureExpenses = const [],
    this.transfers = const [],
    this.isLoading = false,
    required this.selectedMonthYear,
    this.expenseCategoryFilter,
  });

  MonthlyTargetModel? get currentMonthTarget {
    try {
      return targets.firstWhere((t) => t.monthYear == selectedMonthYear);
    } catch (_) {
      return null;
    }
  }

  // Filtered actual expenses for selected month
  List<ExpenseModel> get monthlyExpenses {
    final list = expenses.where((e) {
      return DateFormatter.formatMonthYear(e.date) == selectedMonthYear;
    }).toList();

    if (expenseCategoryFilter != null && expenseCategoryFilter!.isNotEmpty) {
      return list.where((e) => e.category == expenseCategoryFilter).toList();
    }
    return list;
  }

  int get totalMonthlyExpensesPaise {
    return monthlyExpenses.fold(0, (sum, e) => sum + e.amount);
  }

  // Expenses by category for charts
  Map<String, int> get expenseBreakdownByCategory {
    final map = <String, int>{
      AppConstants.expenseCategorySalary: 0,
      AppConstants.expenseCategoryPersonal: 0,
      AppConstants.expenseCategoryOther: 0,
    };
    for (final exp in monthlyExpenses) {
      map[exp.category] = (map[exp.category] ?? 0) + exp.amount;
    }
    return map;
  }

  // Future expenses: Pending & Overdue
  List<FutureExpenseModel> get pendingFutureExpenses =>
      futureExpenses.where((e) => !e.isPaid && !e.isOverdue).toList();

  List<FutureExpenseModel> get overdueFutureExpenses =>
      futureExpenses.where((e) => !e.isPaid && e.isOverdue).toList();

  List<FutureExpenseModel> get paidFutureExpenses =>
      futureExpenses.where((e) => e.isPaid).toList();

  int get totalPendingFutureExpensesPaise => futureExpenses
      .where((e) => !e.isPaid)
      .fold(0, (sum, e) => sum + e.amount);

  PaymentsState copyWith({
    List<MonthlyTargetModel>? targets,
    List<ExpenseModel>? expenses,
    List<FutureExpenseModel>? futureExpenses,
    List<AccountTransferModel>? transfers,
    bool? isLoading,
    String? selectedMonthYear,
    String? expenseCategoryFilter,
    bool clearCategoryFilter = false,
  }) {
    return PaymentsState(
      targets: targets ?? this.targets,
      expenses: expenses ?? this.expenses,
      futureExpenses: futureExpenses ?? this.futureExpenses,
      transfers: transfers ?? this.transfers,
      isLoading: isLoading ?? this.isLoading,
      selectedMonthYear: selectedMonthYear ?? this.selectedMonthYear,
      expenseCategoryFilter: clearCategoryFilter
          ? null
          : (expenseCategoryFilter ?? this.expenseCategoryFilter),
    );
  }
}

class PaymentsNotifier extends StateNotifier<PaymentsState> {
  final FirebaseService _service = FirebaseService();
  final Ref _ref;
  StreamSubscription? _targetsSub;
  StreamSubscription? _expensesSub;
  StreamSubscription? _futureExpSub;
  StreamSubscription? _transfersSub;

  PaymentsNotifier(this._ref)
      : super(PaymentsState(
          selectedMonthYear: DateFormatter.formatMonthYear(DateTime.now()),
          isLoading: true,
        )) {
    _init();
  }

  void _init() {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        _subscribeAll(next.isDemoUser);
      } else {
        _clear();
      }
    });

    final currentAuth = _ref.read(authProvider);
    if (currentAuth.isAuthenticated) {
      _subscribeAll(currentAuth.isDemoUser);
    }
  }

  void _clear() {
    _targetsSub?.cancel();
    _expensesSub?.cancel();
    _futureExpSub?.cancel();
    _transfersSub?.cancel();
    state = PaymentsState(
      selectedMonthYear: DateFormatter.formatMonthYear(DateTime.now()),
    );
  }

  void _subscribeAll(bool isDemo) {
    _clear();
    if (isDemo) {
      state = state.copyWith(
        targets: _sampleTargets,
        expenses: _sampleExpenses,
        futureExpenses: _sampleFutureExpenses,
        transfers: _sampleTransfers,
        isLoading: false,
      );
      _checkFutureExpenseNotifications(_sampleFutureExpenses);
      return;
    }

    state = state.copyWith(isLoading: true);

    _targetsSub = _service.streamMonthlyTargets().listen((targets) {
      state = state.copyWith(targets: targets, isLoading: false);
    });

    _expensesSub = _service.streamExpenses().listen((expenses) {
      state = state.copyWith(expenses: expenses, isLoading: false);
    });

    _futureExpSub = _service.streamFutureExpenses().listen((futureExp) {
      state = state.copyWith(futureExpenses: futureExp, isLoading: false);
      _checkFutureExpenseNotifications(futureExp);
    });

    _transfersSub = _service.streamTransfers().listen((transfers) {
      state = state.copyWith(transfers: transfers, isLoading: false);
    });
  }

  void _checkFutureExpenseNotifications(List<FutureExpenseModel> list) {
    for (final exp in list) {
      if (!exp.isPaid) {
        if (exp.isOverdue) {
          NotificationService().notifyFutureExpense(
            expenseId: exp.id,
            title: exp.title,
            amountFormatted: CurrencyFormatter.formatPaise(exp.amount),
            isOverdue: true,
          );
        } else if (DateFormatter.isToday(exp.dueDate)) {
          NotificationService().notifyFutureExpense(
            expenseId: exp.id,
            title: exp.title,
            amountFormatted: CurrencyFormatter.formatPaise(exp.amount),
            isOverdue: false,
          );
        }
      }
    }
  }

  void setSelectedMonthYear(String my) {
    state = state.copyWith(selectedMonthYear: my);
  }

  void setExpenseCategoryFilter(String? category) {
    state = state.copyWith(
      expenseCategoryFilter: category,
      clearCategoryFilter: category == null,
    );
  }

  // Target operations
  Future<void> saveTarget({
    required String monthYear,
    required int targetAmountPaise,
    required String remarks,
  }) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    final model = MonthlyTargetModel(
      id: monthYear,
      monthYear: monthYear,
      targetAmount: targetAmountPaise,
      remarks: remarks,
      createdAt: DateTime.now(),
    );

    if (isDemo) {
      final updated = state.targets.where((t) => t.monthYear != monthYear).toList();
      state = state.copyWith(targets: [model, ...updated]);
    } else {
      await _service.setMonthlyTarget(model);
    }
  }

  Future<void> deleteTarget(String monthYear) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    if (isDemo) {
      state = state.copyWith(
        targets: state.targets.where((t) => t.monthYear != monthYear).toList(),
      );
    } else {
      await _service.deleteMonthlyTarget(monthYear);
    }
  }

  // Expense operations
  Future<void> addExpense(ExpenseModel expense) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    final id = expense.id.isEmpty ? const Uuid().v4() : expense.id;
    final finalExp = ExpenseModel(
      id: id,
      title: expense.title,
      amount: expense.amount,
      category: expense.category,
      accountType: expense.accountType,
      date: expense.date,
      remarks: expense.remarks,
      createdAt: DateTime.now(),
    );

    if (isDemo) {
      state = state.copyWith(expenses: [finalExp, ...state.expenses]);
    } else {
      await _service.addExpense(finalExp);
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    if (isDemo) {
      final updated =
          state.expenses.map((e) => e.id == expense.id ? expense : e).toList();
      state = state.copyWith(expenses: updated);
    } else {
      await _service.updateExpense(expense);
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    if (isDemo) {
      state = state.copyWith(
        expenses: state.expenses.where((e) => e.id != expenseId).toList(),
      );
    } else {
      await _service.deleteExpense(expenseId);
    }
  }

  // Future expense operations
  Future<void> addFutureExpense(FutureExpenseModel expense) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    final id = expense.id.isEmpty ? const Uuid().v4() : expense.id;
    final finalExp = FutureExpenseModel(
      id: id,
      title: expense.title,
      amount: expense.amount,
      category: expense.category,
      dueDate: expense.dueDate,
      dueTime: expense.dueTime,
      remarks: expense.remarks,
      paymentStatus: expense.paymentStatus,
      createdAt: DateTime.now(),
    );

    if (isDemo) {
      state = state.copyWith(
        futureExpenses: [finalExp, ...state.futureExpenses],
      );
    } else {
      await _service.addFutureExpense(finalExp);
    }
  }

  Future<void> markFutureExpensePaid(
    FutureExpenseModel expense, {
    String accountType = AppConstants.accountTypeBank,
  }) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    if (isDemo) {
      final paid = expense.copyWith(
        paymentStatus: AppConstants.futureExpenseStatusPaid,
        paidAt: DateTime.now(),
      );
      final updatedFuture =
          state.futureExpenses.map((e) => e.id == expense.id ? paid : e).toList();

      // Automatically add to actual expenses
      final actualExp = ExpenseModel(
        id: const Uuid().v4(),
        title: expense.title,
        amount: expense.amount,
        category: expense.category,
        accountType: accountType,
        date: DateTime.now(),
        remarks: 'Paid scheduled expense: ${expense.remarks}',
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        futureExpenses: updatedFuture,
        expenses: [actualExp, ...state.expenses],
      );
    } else {
      await _service.markFutureExpenseAsPaid(expense, accountType: accountType);
    }
  }

  Future<void> updateFutureExpense(FutureExpenseModel expense) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    if (isDemo) {
      final updated = state.futureExpenses
          .map((e) => e.id == expense.id ? expense : e)
          .toList();
      state = state.copyWith(futureExpenses: updated);
    } else {
      await _service.updateFutureExpense(expense);
    }
  }

  Future<void> deleteFutureExpense(String expenseId) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    if (isDemo) {
      state = state.copyWith(
        futureExpenses:
            state.futureExpenses.where((e) => e.id != expenseId).toList(),
      );
    } else {
      await _service.deleteFutureExpense(expenseId);
    }
  }

  // Transfer operations (e.g. Save cash to Father's Account, or transfer between accounts)
  Future<void> addTransfer({
    required String fromAccount,
    required String toAccount,
    required int amount,
    required DateTime date,
    String remarks = '',
  }) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    final id = const Uuid().v4();
    final model = AccountTransferModel(
      id: id,
      fromAccount: fromAccount,
      toAccount: toAccount,
      amount: amount,
      date: date,
      remarks: remarks,
      createdAt: DateTime.now(),
    );

    if (isDemo) {
      state = state.copyWith(transfers: [model, ...state.transfers]);
    } else {
      await _service.addTransfer(model);
    }
  }

  Future<void> deleteTransfer(String transferId) async {
    final isDemo = _ref.read(authProvider).isDemoUser;
    if (isDemo) {
      state = state.copyWith(
        transfers: state.transfers.where((t) => t.id != transferId).toList(),
      );
    } else {
      await _service.deleteTransfer(transferId);
    }
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  static final List<MonthlyTargetModel> _sampleTargets = [
    MonthlyTargetModel(
      id: '11-2026',
      monthYear: '11-2026',
      targetAmount: 20000000, // ₹2,00,000.00
      remarks: 'Diwali festive season expansion target',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    MonthlyTargetModel(
      id: '10-2026',
      monthYear: '10-2026',
      targetAmount: 18000000, // ₹1,80,000.00
      remarks: 'Q3 closing collection target',
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
    ),
  ];

  static final List<ExpenseModel> _sampleExpenses = [
    ExpenseModel(
      id: 'exp-1',
      title: 'Office Assistant Salary - November',
      amount: 2500000, // ₹25,000
      category: AppConstants.expenseCategorySalary,
      accountType: AppConstants.accountTypeBank,
      date: DateTime.now().subtract(const Duration(days: 3)),
      remarks: 'Paid via bank transfer',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ExpenseModel(
      id: 'exp-2',
      title: 'High-speed Fiber Internet & Hosting',
      amount: 450000, // ₹4,500
      category: AppConstants.expenseCategoryOther,
      accountType: AppConstants.accountTypeBank,
      date: DateTime.now().subtract(const Duration(days: 2)),
      remarks: 'Quarterly server hosting bill',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ExpenseModel(
      id: 'exp-3',
      title: 'Fuel & Client Meeting Travel',
      amount: 220000, // ₹2,200
      category: AppConstants.expenseCategoryPersonal,
      accountType: AppConstants.accountTypeCash,
      date: DateTime.now().subtract(const Duration(days: 1)),
      remarks: 'Travel to client site in Noida',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final List<FutureExpenseModel> _sampleFutureExpenses = [
    FutureExpenseModel(
      id: 'fe-1',
      title: 'Office Space Rent',
      amount: 3500000, // ₹35,000
      category: AppConstants.expenseCategoryOther,
      dueDate: DateTime.now().add(const Duration(days: 3)),
      dueTime: '05:00 PM',
      remarks: 'Monthly rent to landlord',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    FutureExpenseModel(
      id: 'fe-2',
      title: 'GST Accountant Quarterly Filing Fee',
      amount: 750000, // ₹7,500
      category: AppConstants.expenseCategorySalary,
      dueDate: DateTime.now().subtract(const Duration(days: 1)), // Overdue!
      dueTime: '12:00 PM',
      remarks: 'Tax consultant invoice',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  static final List<AccountTransferModel> _sampleTransfers = [
    AccountTransferModel(
      id: 'tr-sample-1',
      fromAccount: AppConstants.accountTypeCash,
      toAccount: AppConstants.accountTypeFatherBank,
      amount: 500000, // ₹5,000 saved into father's bank
      date: DateTime.now().subtract(const Duration(days: 2)),
      remarks: "Cash saved in Father's Account",
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}

final paymentsProvider =
    StateNotifierProvider<PaymentsNotifier, PaymentsState>((ref) {
  return PaymentsNotifier(ref);
});

// Financial summary computed provider
class FinancialSummary {
  final int totalCollectedPaise;
  final int thisMonthCollectedPaise;
  final int totalExpensesPaise;
  final int thisMonthExpensesPaise;
  final int netCashFlowPaise; // Total Collected - Total Expenses
  final int completedWorkOutstandingPaise;
  final int incompleteWorkOutstandingPaise;
  final int totalOutstandingPaise;

  // Exact Bank, Cash & Father's Account Breakdowns
  final int cashReceivedPaise;
  final int bankReceivedPaise;
  final int fatherReceivedPaise;

  final int cashSpentPaise;
  final int bankSpentPaise;
  final int fatherSpentPaise;

  final int cashTransfersNetPaise;
  final int bankTransfersNetPaise;
  final int fatherTransfersNetPaise;

  final int cashBalancePaise; // (cashReceived - cashSpent) + cashTransfersNet
  final int bankBalancePaise; // (bankReceived - bankSpent) + bankTransfersNet
  final int fatherBalancePaise; // (fatherReceived - fatherSpent) + fatherTransfersNet
  final int totalLiquidBalancePaise; // cashBalance + bankBalance + fatherBalance

  const FinancialSummary({
    required this.totalCollectedPaise,
    required this.thisMonthCollectedPaise,
    required this.totalExpensesPaise,
    required this.thisMonthExpensesPaise,
    required this.netCashFlowPaise,
    required this.completedWorkOutstandingPaise,
    required this.incompleteWorkOutstandingPaise,
    required this.totalOutstandingPaise,
    required this.cashReceivedPaise,
    required this.bankReceivedPaise,
    required this.fatherReceivedPaise,
    required this.cashSpentPaise,
    required this.bankSpentPaise,
    required this.fatherSpentPaise,
    required this.cashTransfersNetPaise,
    required this.bankTransfersNetPaise,
    required this.fatherTransfersNetPaise,
    required this.cashBalancePaise,
    required this.bankBalancePaise,
    required this.fatherBalancePaise,
    required this.totalLiquidBalancePaise,
  });
}

final financialSummaryProvider = Provider<FinancialSummary>((ref) {
  final custState = ref.watch(customersProvider);
  final payState = ref.watch(paymentsProvider);

  final totalCollected = custState.totalReceivedPaise;
  final allPayments = custState.allPayments;

  final now = DateTime.now();
  final currentMY = DateFormatter.formatMonthYear(now);

  final thisMonthCollected = allPayments
      .where((p) => DateFormatter.formatMonthYear(p.paymentDate) == currentMY)
      .fold(0, (sum, p) => sum + p.amountReceived);

  final totalExpenses =
      payState.expenses.fold(0, (sum, e) => sum + e.amount);
  final thisMonthExpenses = payState.totalMonthlyExpensesPaise;

  // Net Cash Flow = Total Amount Collected - Total Expenses
  // (Outstanding payments are NOT included in actual collected revenue)
  final netCashFlow = totalCollected - totalExpenses;

  // Cash vs Bank vs Father's Account collections
  final cashReceived = allPayments
      .where((p) => p.isCash)
      .fold(0, (sum, p) => sum + p.amountReceived);
  final bankReceived = allPayments
      .where((p) => p.isBank)
      .fold(0, (sum, p) => sum + p.amountReceived);
  final fatherReceived = allPayments
      .where((p) => p.isFatherBank)
      .fold(0, (sum, p) => sum + p.amountReceived);

  // Expenses spent from each account
  final cashSpent = payState.expenses
      .where((e) => e.isCash)
      .fold(0, (sum, e) => sum + e.amount);
  final bankSpent = payState.expenses
      .where((e) => e.isBank)
      .fold(0, (sum, e) => sum + e.amount);
  final fatherSpent = payState.expenses
      .where((e) => e.isFatherBank)
      .fold(0, (sum, e) => sum + e.amount);

  // Transfers between accounts
  int cashTransfersNet = 0;
  int bankTransfersNet = 0;
  int fatherTransfersNet = 0;

  for (final tr in payState.transfers) {
    // Outflow from source
    if (tr.fromAccount == AppConstants.accountTypeCash) {
      cashTransfersNet -= tr.amount;
    } else if (tr.fromAccount == AppConstants.accountTypeBank) {
      bankTransfersNet -= tr.amount;
    } else if (tr.fromAccount == AppConstants.accountTypeFatherBank) {
      fatherTransfersNet -= tr.amount;
    }

    // Inflow to destination
    if (tr.toAccount == AppConstants.accountTypeCash) {
      cashTransfersNet += tr.amount;
    } else if (tr.toAccount == AppConstants.accountTypeBank) {
      bankTransfersNet += tr.amount;
    } else if (tr.toAccount == AppConstants.accountTypeFatherBank) {
      fatherTransfersNet += tr.amount;
    }
  }

  final cashBalance = (cashReceived - cashSpent) + cashTransfersNet;
  final bankBalance = (bankReceived - bankSpent) + bankTransfersNet;
  final fatherBalance = (fatherReceived - fatherSpent) + fatherTransfersNet;
  final totalLiquidBalance = cashBalance + bankBalance + fatherBalance;

  return FinancialSummary(
    totalCollectedPaise: totalCollected,
    thisMonthCollectedPaise: thisMonthCollected,
    totalExpensesPaise: totalExpenses,
    thisMonthExpensesPaise: thisMonthExpenses,
    netCashFlowPaise: netCashFlow,
    completedWorkOutstandingPaise: custState.completedWorkOutstandingPaise,
    incompleteWorkOutstandingPaise: custState.incompleteWorkOutstandingPaise,
    totalOutstandingPaise: custState.totalOutstandingPaise,
    cashReceivedPaise: cashReceived,
    bankReceivedPaise: bankReceived,
    fatherReceivedPaise: fatherReceived,
    cashSpentPaise: cashSpent,
    bankSpentPaise: bankSpent,
    fatherSpentPaise: fatherSpent,
    cashTransfersNetPaise: cashTransfersNet,
    bankTransfersNetPaise: bankTransfersNet,
    fatherTransfersNetPaise: fatherTransfersNet,
    cashBalancePaise: cashBalance,
    bankBalancePaise: bankBalance,
    fatherBalancePaise: fatherBalance,
    totalLiquidBalancePaise: totalLiquidBalance,
  );
});
