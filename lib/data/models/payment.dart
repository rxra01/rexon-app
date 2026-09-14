import 'date_helper.dart';

class Payment {
  final String id;
  final String businessId;
  final String? saleId;
  final String? customerId;
  final String customerName;
  final double amount;
  final String method; // "cash" | "upi" | "bank_transfer" | "card" | "cheque" | "other"
  final String? note;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.businessId,
    this.saleId,
    this.customerId,
    required this.customerName,
    required this.amount,
    required this.method,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'saleId': saleId,
        'customerId': customerId,
        'customerName': customerName,
        'amount': amount,
        'method': method,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        saleId: json['saleId'] as String?,
        customerId: json['customerId'] as String?,
        customerName: json['customerName'] as String? ?? 'Walk-in Customer',
        amount: (json['amount'] as num).toDouble(),
        method: json['method'] as String,
        note: json['note'] as String?,
        createdAt: parseModelDate(json['createdAt']),
      );
}
