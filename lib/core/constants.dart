import 'package:intl/intl.dart';

class AppConstants {
  static const String appName = 'Rexon';
  static const String appTagline = 'Retailer Invoicing & Inventory';
  static const String version = 'v0.1';

  // Categories
  static const List<String> defaultCategories = [
    'All',
    'Electronics',
    'Apparel',
    'Groceries',
    'Hardware',
    'Footwear',
    'General',
  ];

  // Units
  static const List<String> units = [
    'Piece',
    'Kg',
    'Gram',
    'Box',
    'Meter',
    'Liter',
    'Pack',
    'Set',
    'Dozen',
  ];

  // Payment Methods
  static const List<String> paymentMethods = [
    'cash',
    'upi',
    'card',
    'bank_transfer',
    'cheque',
    'other',
  ];

  // Stock Adjustment Reasons
  static const List<String> adjustmentReasons = [
    'Supplier Restock',
    'Inventory Audit Correction',
    'Damaged / Expired Goods',
    'Internal / Display Use',
    'Theft / Missing Stock',
    'Customer Return',
    'Other Adjustment',
  ];

  // Currency formatter
  static String formatCurrency(double amount, {String symbol = '₹'}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: symbol,
      decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
    );
    return formatter.format(amount);
  }

  // Date formatter
  static String formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  static String formatShortDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }
}
