import 'package:cloud_firestore/cloud_firestore.dart';

class MonthlyTargetModel {
  final String id;
  final String monthYear; // "MM-yyyy" e.g. "11-2026"
  final int targetAmount; // In integer paise
  final String remarks;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MonthlyTargetModel({
    required this.id,
    required this.monthYear,
    required this.targetAmount,
    this.remarks = '',
    required this.createdAt,
    this.updatedAt,
  });

  factory MonthlyTargetModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return MonthlyTargetModel(
      id: doc.id,
      monthYear: data['monthYear'] ?? '',
      targetAmount: (data['targetAmount'] as num?)?.toInt() ?? 0,
      remarks: data['remarks'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'monthYear': monthYear,
      'targetAmount': targetAmount,
      'remarks': remarks,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  MonthlyTargetModel copyWith({
    String? monthYear,
    int? targetAmount,
    String? remarks,
  }) {
    return MonthlyTargetModel(
      id: id,
      monthYear: monthYear ?? this.monthYear,
      targetAmount: targetAmount ?? this.targetAmount,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
