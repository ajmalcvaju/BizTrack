import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';

class LeadModel {
  final String id;
  final String shopName;
  final String customerName;
  final DateTime createdAt;
  final String responseStatus; // Follow Up, Interested, DNP
  final DateTime? nextFollowUpDate;
  final String? nextFollowUpTime; // "hh:mm a"
  final String customerRemarks;
  final String contactNumber;
  final String address;
  final bool isConverted;
  final String? convertedCustomerId;
  final DateTime? updatedAt;

  LeadModel({
    required this.id,
    required this.shopName,
    required this.customerName,
    required this.createdAt,
    this.responseStatus = AppConstants.leadStatusFollowUp,
    this.nextFollowUpDate,
    this.nextFollowUpTime,
    this.customerRemarks = '',
    this.contactNumber = '',
    this.address = '',
    this.isConverted = false,
    this.convertedCustomerId,
    this.updatedAt,
  });

  /// Computed DateTime combining follow-up date and 12-hour time string
  DateTime? get followUpDateTime {
    if (nextFollowUpDate == null) return null;
    final time = DateFormatter.parseTimeOfDay(nextFollowUpTime);
    return DateFormatter.combineDateAndTime(
      nextFollowUpDate!,
      time ?? const TimeOfDay(hour: 10, minute: 0),
    );
  }

  /// Whether the follow-up moment is strictly in the future
  bool get isUpcoming {
    if (isConverted) return false;
    final dt = followUpDateTime;
    if (dt == null) return false;
    return dt.isAfter(DateTime.now());
  }

  /// Whether the follow-up moment has arrived or passed
  bool get isDue {
    if (isConverted) return false;
    final dt = followUpDateTime;
    if (dt == null) return false;
    return !dt.isAfter(DateTime.now());
  }

  /// True if active and has no follow-up date/time scheduled
  bool get hasNoFollowUpScheduled {
    if (isConverted) return false;
    return nextFollowUpDate == null;
  }

  bool get isInterested => responseStatus == AppConstants.leadStatusInterested;
  bool get isDNP => responseStatus == AppConstants.leadStatusDNP;

  factory LeadModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return LeadModel(
      id: doc.id,
      shopName: data['shopName'] ?? '',
      customerName: data['customerName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      responseStatus: data['responseStatus'] ?? AppConstants.leadStatusFollowUp,
      nextFollowUpDate: (data['nextFollowUpDate'] as Timestamp?)?.toDate(),
      nextFollowUpTime: data['nextFollowUpTime'],
      customerRemarks: data['customerRemarks'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      address: data['address'] ?? '',
      isConverted: data['isConverted'] ?? false,
      convertedCustomerId: data['convertedCustomerId'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopName': shopName,
      'customerName': customerName,
      'createdAt': Timestamp.fromDate(createdAt),
      'responseStatus': responseStatus,
      'nextFollowUpDate': nextFollowUpDate != null
          ? Timestamp.fromDate(nextFollowUpDate!)
          : null,
      'nextFollowUpTime': nextFollowUpTime,
      'customerRemarks': customerRemarks,
      'contactNumber': contactNumber,
      'address': address,
      'isConverted': isConverted,
      'convertedCustomerId': convertedCustomerId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  LeadModel copyWith({
    String? shopName,
    String? customerName,
    String? responseStatus,
    DateTime? nextFollowUpDate,
    String? nextFollowUpTime,
    bool clearFollowUp = false,
    String? customerRemarks,
    String? contactNumber,
    String? address,
    bool? isConverted,
    String? convertedCustomerId,
  }) {
    return LeadModel(
      id: id,
      shopName: shopName ?? this.shopName,
      customerName: customerName ?? this.customerName,
      createdAt: createdAt,
      responseStatus: responseStatus ?? this.responseStatus,
      nextFollowUpDate: clearFollowUp ? null : (nextFollowUpDate ?? this.nextFollowUpDate),
      nextFollowUpTime: clearFollowUp ? null : (nextFollowUpTime ?? this.nextFollowUpTime),
      customerRemarks: customerRemarks ?? this.customerRemarks,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      isConverted: isConverted ?? this.isConverted,
      convertedCustomerId: convertedCustomerId ?? this.convertedCustomerId,
      updatedAt: DateTime.now(),
    );
  }
}
