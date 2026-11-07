import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class AccountTransferModel {
  final String id;
  final String fromAccount; // Cash, Bank, Father's Account
  final String toAccount;   // Father's Account, Cash, Bank
  final int amount;         // In integer paise
  final DateTime date;
  final String remarks;
  final DateTime createdAt;

  AccountTransferModel({
    required this.id,
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.date,
    this.remarks = '',
    required this.createdAt,
  });

  factory AccountTransferModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return AccountTransferModel(
      id: doc.id,
      fromAccount: data['fromAccount'] ?? AppConstants.accountTypeCash,
      toAccount: data['toAccount'] ?? AppConstants.accountTypeFatherBank,
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      remarks: data['remarks'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromAccount': fromAccount,
      'toAccount': toAccount,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'remarks': remarks,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AccountTransferModel copyWith({
    String? fromAccount,
    String? toAccount,
    int? amount,
    DateTime? date,
    String? remarks,
  }) {
    return AccountTransferModel(
      id: id,
      fromAccount: fromAccount ?? this.fromAccount,
      toAccount: toAccount ?? this.toAccount,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt,
    );
  }
}
