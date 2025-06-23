import 'package:intl/intl.dart';

class ConversionUtils {
  /// Safely converts any value to double
  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remove currency symbols, commas, and other non-numeric characters
      String cleanValue = value.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(cleanValue) ?? 0.0;
    }
    return 0.0;
  }

  /// Safely converts any value to int
  static int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Remove currency symbols, commas, and other non-numeric characters
      String cleanValue = value.replaceAll(RegExp(r'[^\d.-]'), '');
      return int.tryParse(cleanValue) ?? 0;
    }
    return 0;
  }

  /// Safely converts any value to string - FIXED: Renamed to avoid conflict
  static String toStringValue(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  /// Format currency in Indonesian Rupiah format
  static String formatCurrency(dynamic value, {String symbol = 'Rp '}) {
    final amount = toDouble(value);
    final formatter = NumberFormat.currency(
      locale: 'id_ID', 
      symbol: symbol, 
      decimalDigits: 0
    );
    return formatter.format(amount);
  }

  /// Format number with thousand separators
  static String formatNumber(dynamic value) {
    final number = toDouble(value);
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(number);
  }

  /// Check if value is numeric
  static bool isNumeric(dynamic value) {
    if (value == null) return false;
    if (value is num) return true;
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^\d.-]'), '')) != null;
    }
    return false;
  }
}