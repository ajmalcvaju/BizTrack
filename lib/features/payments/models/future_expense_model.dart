import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';

class FutureExpenseModel {
  final String id;
  final String title;
  final int amount; // In integer paise
  final String category;
  final DateTime dueDate;
  final String? dueTime; // "hh:mm a"
  final String remarks;
  final String paymentStatus; // Pending, Paid
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? paidAt;

  FutureExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    this.category = AppConstants.expenseCategoryOther,
    required this.dueDate,
    this.dueTime,
    this.remarks = '',
    this.paymentStatus = AppConstants.futureExpenseStatusPending,
    required this.createdAt,
    this.updatedAt,
    this.paidAt,
  });

  bool get isPaid => paymentStatus == AppConstants.futureExpenseStatusPaid;

  /// Combined Due DateTime
  DateTime get dueDateTime {
    final parsedTime = DateFormatter.parseTimeOfDay(dueTime);
    return DateFormatter.combineDateAndTime(
      dueDate,
      parsedTime ?? const TimeOfDay(hour: 23, minute: 59),
    );
  }

  /// Overdue logic: If not marked as paid by its scheduled date and time,
  /// automatically highlight it in red as overdue from the next day until it is marked as paid.
  bool get isOverdue {
    if (isPaid) return false;
    // Overdue if scheduled date is strictly before today, or if today and time has passed
    return DateFormatter.isPastDate(dueDate) ||
        (DateFormatter.isToday(dueDate) && DateFormatter.isPastMoment(dueDateTime));
  }

  factory FutureExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return FutureExpenseModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      category: data['category'] ?? AppConstants.expenseCategoryOther,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueTime: data['dueTime'],
      remarks: data['remarks'] ?? '',
      paymentStatus:
          data['paymentStatus'] ?? AppConstants.futureExpenseStatusPending,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'dueDate': Timestamp.fromDate(dueDate),
      'dueTime': dueTime,
      'remarks': remarks,
      'paymentStatus': paymentStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }

  FutureExpenseModel copyWith({
    String? title,
    int? amount,
    String? category,
    DateTime? dueDate,
    String? dueTime,
    String? remarks,
    String? paymentStatus,
    DateTime? paidAt,
  }) {
    return FutureExpenseModel(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      remarks: remarks ?? this.remarks,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      paidAt: paidAt ?? this.paidAt,
    );
  }
}
