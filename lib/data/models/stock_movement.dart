import 'date_helper.dart';

class StockMovement {
  final String id;
  final String businessId;
  final String productId;
  final String productName;
  final String type; // "sale" | "adjustment" | "opening"
  final int quantityChange; // negative for reductions
  final String? reason;
  final String? referenceId; // e.g. saleId
  final DateTime createdAt;
  final String createdBy;

  StockMovement({
    required this.id,
    required this.businessId,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantityChange,
    this.reason,
    this.referenceId,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'productId': productId,
        'productName': productName,
        'type': type,
        'quantityChange': quantityChange,
        'reason': reason,
        'referenceId': referenceId,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
      };

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        productId: json['productId'] as String,
        productName: json['productName'] as String? ?? 'Unknown Product',
        type: json['type'] as String,
        quantityChange: (json['quantityChange'] as num).toInt(),
        reason: json['reason'] as String?,
        referenceId: json['referenceId'] as String?,
        createdAt: parseModelDate(json['createdAt']),
        createdBy: json['createdBy'] as String,
      );
}
