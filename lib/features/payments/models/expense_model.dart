import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class ExpenseModel {
  final String id;
  final String title;
  final int amount; // In integer paise
  final String category; // Salary, Personal Expense, Other Expense
  final String accountType; // Bank or Cash
  final DateTime date;
  final String remarks;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    this.category = AppConstants.expenseCategoryOther,
    this.accountType = AppConstants.accountTypeBank,
    required this.date,
    this.remarks = '',
    required this.createdAt,
    this.updatedAt,
  });

  bool get isCash => accountType == AppConstants.accountTypeCash;
  bool get isBank => accountType == AppConstants.accountTypeBank;
  bool get isFatherBank => accountType == AppConstants.accountTypeFatherBank;

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ExpenseModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      category: data['category'] ?? AppConstants.expenseCategoryOther,
      accountType: data['accountType'] ?? AppConstants.accountTypeBank,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      remarks: data['remarks'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'accountType': accountType,
      'date': Timestamp.fromDate(date),
      'remarks': remarks,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ExpenseModel copyWith({
    String? title,
    int? amount,
    String? category,
    String? accountType,
    DateTime? date,
    String? remarks,
  }) {
    return ExpenseModel(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      accountType: accountType ?? this.accountType,
      date: date ?? this.date,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
