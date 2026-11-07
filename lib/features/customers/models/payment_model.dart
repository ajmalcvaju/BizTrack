import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class PaymentModel {
  final String id;
  final String customerId;
  final int amountReceived; // In paise
  final DateTime paymentDate;
  final String paymentMethod; // Cash, UPI, Bank Transfer, Other
  final String accountType; // Bank or Cash
  final String remarks;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.customerId,
    required this.amountReceived,
    required this.paymentDate,
    this.paymentMethod = AppConstants.paymentMethodCash,
    String? accountType,
    this.remarks = '',
    required this.createdAt,
  }) : accountType = accountType ??
            (paymentMethod == AppConstants.paymentMethodCash
                ? AppConstants.accountTypeCash
                : AppConstants.accountTypeBank);

  bool get isCash => accountType == AppConstants.accountTypeCash;
  bool get isBank => accountType == AppConstants.accountTypeBank;
  bool get isFatherBank => accountType == AppConstants.accountTypeFatherBank;

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final method = data['paymentMethod'] ?? AppConstants.paymentMethodCash;
    final storedAccount = data['accountType'];
    final effectiveAccount = storedAccount ??
        (method == AppConstants.paymentMethodCash
            ? AppConstants.accountTypeCash
            : AppConstants.accountTypeBank);

    return PaymentModel(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      amountReceived: (data['amountReceived'] as num?)?.toInt() ?? 0,
      paymentDate:
          (data['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentMethod: method,
      accountType: effectiveAccount,
      remarks: data['remarks'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'amountReceived': amountReceived,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'paymentMethod': paymentMethod,
      'accountType': accountType,
      'remarks': remarks,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
