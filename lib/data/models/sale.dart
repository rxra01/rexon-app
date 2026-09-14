import 'date_helper.dart';

class SaleItem {
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'sku': sku,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'lineTotal': lineTotal,
      };

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        sku: json['sku'] as String? ?? '',
        quantity: (json['quantity'] as num).toInt(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
        lineTotal: (json['lineTotal'] as num).toDouble(),
      );
}

class Sale {
  final String id;
  final String businessId;
  final String invoiceNumber;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final List<SaleItem> items;
  final double discount;
  final double tax;
  final double grandTotal;
  final String paymentStatus; // "paid" | "partial" | "unpaid"
  final double amountPaid;
  final String paymentMethod;
  final bool voided;
  final String? voidReason;
  final DateTime createdAt;
  final String createdBy;

  Sale({
    required this.id,
    required this.businessId,
    required this.invoiceNumber,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.items,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.grandTotal,
    required this.paymentStatus,
    required this.amountPaid,
    this.paymentMethod = 'cash',
    this.voided = false,
    this.voidReason,
    required this.createdAt,
    required this.createdBy,
  });

  double get balanceDue => (grandTotal - amountPaid).clamp(0.0, double.infinity);

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'invoiceNumber': invoiceNumber,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'items': items.map((i) => i.toJson()).toList(),
        'discount': discount,
        'tax': tax,
        'grandTotal': grandTotal,
        'paymentStatus': paymentStatus,
        'amountPaid': amountPaid,
        'paymentMethod': paymentMethod,
        'voided': voided,
        'voidReason': voidReason,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
      };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        invoiceNumber: json['invoiceNumber'] as String,
        customerId: json['customerId'] as String?,
        customerName: json['customerName'] as String,
        customerPhone: json['customerPhone'] as String?,
        items: (json['items'] as List<dynamic>)
            .map((item) => SaleItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
        grandTotal: (json['grandTotal'] as num).toDouble(),
        paymentStatus: json['paymentStatus'] as String,
        amountPaid: (json['amountPaid'] as num).toDouble(),
        paymentMethod: json['paymentMethod'] as String? ?? 'cash',
        voided: json['voided'] as bool? ?? false,
        voidReason: json['voidReason'] as String?,
        createdAt: parseModelDate(json['createdAt']),
        createdBy: json['createdBy'] as String,
      );

  Sale copyWith({
    String? paymentStatus,
    double? amountPaid,
    bool? voided,
    String? voidReason,
  }) {
    return Sale(
      id: id,
      businessId: businessId,
      invoiceNumber: invoiceNumber,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      items: items,
      discount: discount,
      tax: tax,
      grandTotal: grandTotal,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentMethod: paymentMethod,
      voided: voided ?? this.voided,
      voidReason: voidReason ?? this.voidReason,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }
}
