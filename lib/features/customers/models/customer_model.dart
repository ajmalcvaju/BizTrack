import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class CustomerModel {
  final String id;
  final String shopName;
  final String customerName;
  final String contactNumber;
  final String address;
  final String workDetails;
  final String workStatus; // Not Started, In Progress, In Review, On Hold, Completed, Cancelled
  final String customerRemarks;
  final int totalWorkAmount; // In integer paise
  final int totalAmountReceived; // In integer paise
  final int balanceAmount; // In integer paise: totalWorkAmount - totalAmountReceived
  final DateTime createdAt;
  final DateTime? updatedAt;

  CustomerModel({
    required this.id,
    required this.shopName,
    required this.customerName,
    this.contactNumber = '',
    this.address = '',
    this.workDetails = '',
    this.workStatus = AppConstants.workStatusNotStarted,
    this.customerRemarks = '',
    required this.totalWorkAmount,
    this.totalAmountReceived = 0,
    int? balanceAmount,
    required this.createdAt,
    this.updatedAt,
  }) : balanceAmount = balanceAmount ?? (totalWorkAmount - totalAmountReceived);

  bool get isCompleted => workStatus == AppConstants.workStatusCompleted;
  bool get isCancelled => workStatus == AppConstants.workStatusCancelled;
  bool get isIncomplete => !isCompleted && !isCancelled;
  bool get hasOutstanding => balanceAmount > 0;
  bool get isAdvanceOrSettled => balanceAmount <= 0;

  factory CustomerModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final total = (data['totalWorkAmount'] as num?)?.toInt() ?? 0;
    final received = (data['totalAmountReceived'] as num?)?.toInt() ?? 0;
    final storedBalance = (data['balanceAmount'] as num?)?.toInt();
    final calculatedBalance = storedBalance ?? (total - received);

    return CustomerModel(
      id: doc.id,
      shopName: data['shopName'] ?? '',
      customerName: data['customerName'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      address: data['address'] ?? '',
      workDetails: data['workDetails'] ?? '',
      workStatus: data['workStatus'] ?? AppConstants.workStatusNotStarted,
      customerRemarks: data['customerRemarks'] ?? '',
      totalWorkAmount: total,
      totalAmountReceived: received,
      balanceAmount: calculatedBalance,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopName': shopName,
      'customerName': customerName,
      'contactNumber': contactNumber,
      'address': address,
      'workDetails': workDetails,
      'workStatus': workStatus,
      'customerRemarks': customerRemarks,
      'totalWorkAmount': totalWorkAmount,
      'totalAmountReceived': totalAmountReceived,
      'balanceAmount': totalWorkAmount - totalAmountReceived,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CustomerModel copyWith({
    String? shopName,
    String? customerName,
    String? contactNumber,
    String? address,
    String? workDetails,
    String? workStatus,
    String? customerRemarks,
    int? totalWorkAmount,
    int? totalAmountReceived,
    int? balanceAmount,
  }) {
    final newTotal = totalWorkAmount ?? this.totalWorkAmount;
    final newReceived = totalAmountReceived ?? this.totalAmountReceived;
    final newBalance = balanceAmount ?? (newTotal - newReceived);

    return CustomerModel(
      id: id,
      shopName: shopName ?? this.shopName,
      customerName: customerName ?? this.customerName,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      workDetails: workDetails ?? this.workDetails,
      workStatus: workStatus ?? this.workStatus,
      customerRemarks: customerRemarks ?? this.customerRemarks,
      totalWorkAmount: newTotal,
      totalAmountReceived: newReceived,
      balanceAmount: newBalance,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
