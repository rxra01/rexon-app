import 'date_helper.dart';

class Product {
  final String id;
  final String businessId;
  final String name;
  final String sku;
  final String? barcode;
  final String category;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final int currentStock;
  final int minStockLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.businessId,
    required this.name,
    required this.sku,
    this.barcode,
    this.category = 'General',
    this.unit = 'Piece',
    required this.purchasePrice,
    required this.sellingPrice,
    required this.currentStock,
    this.minStockLevel = 5,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => currentStock <= minStockLevel && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'category': category,
        'unit': unit,
        'purchasePrice': purchasePrice,
        'sellingPrice': sellingPrice,
        'currentStock': currentStock,
        'minStockLevel': minStockLevel,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        name: json['name'] as String,
        sku: json['sku'] as String,
        barcode: json['barcode'] as String?,
        category: json['category'] as String? ?? 'General',
        unit: json['unit'] as String? ?? 'Piece',
        purchasePrice: (json['purchasePrice'] as num).toDouble(),
        sellingPrice: (json['sellingPrice'] as num).toDouble(),
        currentStock: (json['currentStock'] as num).toInt(),
        minStockLevel: (json['minStockLevel'] as num?)?.toInt() ?? 5,
        createdAt: parseModelDate(json['createdAt']),
        updatedAt: parseModelDate(json['updatedAt']),
      );

  Product copyWith({
    String? name,
    String? sku,
    String? barcode,
    String? category,
    String? unit,
    double? purchasePrice,
    double? sellingPrice,
    int? currentStock,
    int? minStockLevel,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      currentStock: currentStock ?? this.currentStock,
      minStockLevel: minStockLevel ?? this.minStockLevel,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
