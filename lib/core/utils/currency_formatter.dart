import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inrWithDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrWithoutDecimals = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _compactInr = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
  );

  /// Convert standard Rupees (can be double) to integer paise
  static int toPaise(num rupees) {
    return (rupees * 100).round();
  }

  /// Convert integer paise to double Rupees
  static double toRupees(int paise) {
    return paise / 100.0;
  }

  /// Format integer paise into Indian Rupee display string
  static String formatPaise(int paise, {bool showDecimals = false}) {
    final double rupees = toRupees(paise);
    if (showDecimals || (paise % 100 != 0)) {
      return _inrWithDecimals.format(rupees);
    }
    return _inrWithoutDecimals.format(rupees);
  }

  /// Compact format for dashboard cards e.g. ₹1.2L, ₹50K
  static String formatCompactPaise(int paise) {
    final double rupees = toRupees(paise);
    if (rupees.abs() >= 100000) {
      return _compactInr.format(rupees);
    }
    return formatPaise(paise);
  }

  /// Parse text input in Rupees into integer paise safely
  static int parseRupeesToPaise(String input) {
    final cleaned = input.replaceAll('₹', '').replaceAll(',', '').trim();
    if (cleaned.isEmpty) return 0;
    final value = double.tryParse(cleaned) ?? 0.0;
    return toPaise(value);
  }
}
