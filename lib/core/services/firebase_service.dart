import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/leads/models/lead_model.dart';
import '../../features/customers/models/customer_model.dart';
import '../../features/customers/models/payment_model.dart';
import '../../features/payments/models/monthly_target_model.dart';
import '../../features/payments/models/expense_model.dart';
import '../../features/payments/models/future_expense_model.dart';
import '../../features/payments/models/account_transfer_model.dart';
import '../../features/day_planner/models/task_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final Uuid _uuid = const Uuid();

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  String get currentUserId {
    try {
      final uid = _auth?.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) return uid;
    } catch (_) {}
    return 'owner';
  }

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final fs = _firestore;
    if (fs == null) return null;
    return fs.collection(AppConstants.usersCollection).doc(currentUserId);
  }

  // ==================== USER PROFILE ====================

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final fs = _firestore;
      if (fs == null) return null;
      final doc = await fs.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveUserProfile(UserModel user) async {
    try {
      final fs = _firestore;
      if (fs == null) return;
      await fs
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (_) {}
  }

  // ==================== LEADS ====================

  CollectionReference<Map<String, dynamic>>? get _leadsRef =>
      _userDoc?.collection(AppConstants.leadsCollection);

  Stream<List<LeadModel>> streamLeads() {
    final ref = _leadsRef;
    if (ref == null) return Stream.value([]);
    return ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => LeadModel.fromFirestore(d)).toList());
  }

  Future<String> addLead(LeadModel lead) async {
    final ref = _leadsRef;
    final id = lead.id.isNotEmpty ? lead.id : _uuid.v4();
    if (ref != null) {
      await ref.doc(id).set(lead.toMap());
    }
    return id;
  }

  Future<void> updateLead(LeadModel lead) async {
    final ref = _leadsRef;
    if (ref != null) {
      await ref.doc(lead.id).update(lead.toMap());
    }
  }

  Future<void> deleteLead(String leadId) async {
    final ref = _leadsRef;
    if (ref != null) {
      await ref.doc(leadId).delete();
    }
  }

  // ==================== CUSTOMERS & PAYMENTS ====================

  CollectionReference<Map<String, dynamic>>? get _customersRef =>
      _userDoc?.collection(AppConstants.customersCollection);

  Stream<List<CustomerModel>> streamCustomers() {
    final ref = _customersRef;
    if (ref == null) return Stream.value([]);
    return ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => CustomerModel.fromFirestore(d)).toList());
  }

  Future<String> addCustomer(CustomerModel customer) async {
    final ref = _customersRef;
    final id = customer.id.isNotEmpty ? customer.id : _uuid.v4();
    if (ref != null) {
      await ref.doc(id).set(customer.toMap());
    }
    return id;
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    final ref = _customersRef;
    if (ref != null) {
      await ref.doc(customer.id).update(customer.toMap());
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    final ref = _customersRef;
    if (ref != null) {
      await ref.doc(customerId).delete();
    }
  }

  Stream<List<PaymentModel>> streamCustomerPayments(String customerId) {
    final ref = _customersRef?.doc(customerId).collection(AppConstants.paymentsCollection);
    if (ref == null) return Stream.value([]);
    return ref
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => PaymentModel.fromFirestore(d)).toList());
  }

  Future<void> recordPayment({
    required CustomerModel customer,
    required int amountReceived,
    required String paymentMethod,
    required String remarks,
    required DateTime paymentDate,
    String? accountType,
  }) async {
    final fs = _firestore;
    final ref = _customersRef;
    if (fs == null || ref == null) return;

    final customerDocRef = ref.doc(customer.id);
    final paymentDocRef = customerDocRef.collection(AppConstants.paymentsCollection).doc(_uuid.v4());

    final resolvedAccountType = accountType ??
        (paymentMethod == AppConstants.paymentMethodCash
            ? AppConstants.accountTypeCash
            : AppConstants.accountTypeBank);

    final payment = PaymentModel(
      id: paymentDocRef.id,
      customerId: customer.id,
      amountReceived: amountReceived,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod,
      accountType: resolvedAccountType,
      remarks: remarks,
      createdAt: DateTime.now(),
    );

    final newReceived = customer.totalAmountReceived + amountReceived;
    final newBalance = customer.totalWorkAmount - newReceived;

    final batch = fs.batch();
    batch.set(paymentDocRef, payment.toMap());
    batch.update(customerDocRef, {
      'totalAmountReceived': newReceived,
      'balanceAmount': newBalance,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> deletePayment({
    required CustomerModel customer,
    required PaymentModel payment,
  }) async {
    final fs = _firestore;
    final ref = _customersRef;
    if (fs == null || ref == null) return;

    final customerDocRef = ref.doc(customer.id);
    final paymentDocRef = customerDocRef.collection(AppConstants.paymentsCollection).doc(payment.id);

    final newReceived = (customer.totalAmountReceived - payment.amountReceived).clamp(0, double.infinity).toInt();
    final newBalance = customer.totalWorkAmount - newReceived;

    final batch = fs.batch();
    batch.delete(paymentDocRef);
    batch.update(customerDocRef, {
      'totalAmountReceived': newReceived,
      'balanceAmount': newBalance,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ==================== MONTHLY TARGETS ====================

  CollectionReference<Map<String, dynamic>>? get _targetsRef =>
      _userDoc?.collection(AppConstants.monthlyTargetsCollection);

  Stream<List<MonthlyTargetModel>> streamMonthlyTargets() {
    final ref = _targetsRef;
    if (ref == null) return Stream.value([]);
    return ref
        .orderBy('monthYear', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => MonthlyTargetModel.fromFirestore(d)).toList());
  }

  Future<void> setMonthlyTarget(MonthlyTargetModel target) async {
    final ref = _targetsRef;
    if (ref == null) return;
    await ref.doc(target.monthYear).set(target.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteMonthlyTarget(String monthYear) async {
    final ref = _targetsRef;
    if (ref != null) {
      await ref.doc(monthYear).delete();
    }
  }

  // ==================== EXPENSES ====================

  CollectionReference<Map<String, dynamic>>? get _expensesRef =>
      _userDoc?.collection(AppConstants.expensesCollection);

  Stream<List<ExpenseModel>> streamExpenses() {
    final ref = _expensesRef;
    if (ref == null) return Stream.value([]);
    return ref
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => ExpenseModel.fromFirestore(d)).toList());
  }

  Future<String> addExpense(ExpenseModel expense) async {
    final ref = _expensesRef;
    final id = expense.id.isNotEmpty ? expense.id : _uuid.v4();
    if (ref != null) {
      await ref.doc(id).set(expense.toMap());
    }
    return id;
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final ref = _expensesRef;
    if (ref != null) {
      await ref.doc(expense.id).update(expense.toMap());
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    final ref = _expensesRef;
    if (ref != null) {
      await ref.doc(expenseId).delete();
    }
  }

  // ==================== FUTURE EXPENSES ====================

  CollectionReference<Map<String, dynamic>>? get _futureExpensesRef =>
      _userDoc?.collection(AppConstants.futureExpensesCollection);

  Stream<List<FutureExpenseModel>> streamFutureExpenses() {
    final ref = _futureExpensesRef;
    if (ref == null) return Stream.value([]);
    return ref
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => FutureExpenseModel.fromFirestore(d)).toList());
  }

  Future<String> addFutureExpense(FutureExpenseModel expense) async {
    final ref = _futureExpensesRef;
    final id = expense.id.isNotEmpty ? expense.id : _uuid.v4();
    if (ref != null) {
      await ref.doc(id).set(expense.toMap());
    }
    return id;
  }

  Future<void> markFutureExpenseAsPaid(
    FutureExpenseModel expense, {
    String accountType = AppConstants.accountTypeBank,
  }) async {
    final ref = _futureExpensesRef;
    if (ref != null) {
      await ref.doc(expense.id).update({
        'paymentStatus': AppConstants.futureExpenseStatusPaid,
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await addExpense(ExpenseModel(
        id: _uuid.v4(),
        title: expense.title,
        amount: expense.amount,
        category: expense.category,
        accountType: accountType,
        date: DateTime.now(),
        remarks: 'Paid future expense: ${expense.remarks}',
        createdAt: DateTime.now(),
      ));
    }
  }

  Future<void> updateFutureExpense(FutureExpenseModel expense) async {
    final ref = _futureExpensesRef;
    if (ref != null) {
      await ref.doc(expense.id).update(expense.toMap());
    }
  }

  Future<void> deleteFutureExpense(String expenseId) async {
    final ref = _futureExpensesRef;
    if (ref != null) {
      await ref.doc(expenseId).delete();
    }
  }

  // ==================== ACCOUNT TRANSFERS ====================

  CollectionReference<Map<String, dynamic>>? get _transfersRef =>
      _userDoc?.collection(AppConstants.transfersCollection);

  Stream<List<AccountTransferModel>> streamTransfers() {
    final ref = _transfersRef;
    if (ref == null) return Stream.value([]);
    return ref
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => AccountTransferModel.fromFirestore(d)).toList());
  }

  Future<String> addTransfer(AccountTransferModel transfer) async {
    final ref = _transfersRef;
    final id = transfer.id.isNotEmpty ? transfer.id : _uuid.v4();
    if (ref != null) {
      await ref.doc(id).set(transfer.toMap());
    }
    return id;
  }

  Future<void> deleteTransfer(String transferId) async {
    final ref = _transfersRef;
    if (ref != null) {
      await ref.doc(transferId).delete();
    }
  }

  // ==================== DAY PLANNER / TASKS ====================

  CollectionReference<Map<String, dynamic>>? get _tasksRef =>
      _userDoc?.collection(AppConstants.tasksCollection);

  Stream<List<TaskModel>> streamTasks() {
    final ref = _tasksRef;
    if (ref == null) return Stream.value([]);
    return ref
        .orderBy('taskDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => TaskModel.fromFirestore(d)).toList());
  }

  Future<String> addTask(TaskModel task) async {
    final ref = _tasksRef;
    final id = task.id.isNotEmpty ? task.id : _uuid.v4();
    if (ref != null) {
      await ref.doc(id).set(task.toMap());
    }
    return id;
  }

  Future<void> updateTask(TaskModel task) async {
    final ref = _tasksRef;
    if (ref != null) {
      await ref.doc(task.id).update(task.toMap());
    }
  }

  Future<void> toggleTaskStatus(TaskModel task) async {
    final ref = _tasksRef;
    if (ref != null) {
      final isNowCompleted = !task.isCompleted;
      await ref.doc(task.id).update({
        'status': isNowCompleted
            ? AppConstants.taskStatusCompleted
            : AppConstants.taskStatusPending,
        'completedAt': isNowCompleted ? FieldValue.serverTimestamp() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteTask(String taskId) async {
    final ref = _tasksRef;
    if (ref != null) {
      await ref.doc(taskId).delete();
    }
  }
}
