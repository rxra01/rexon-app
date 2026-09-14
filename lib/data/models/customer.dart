import 'date_helper.dart';

class Customer {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? address;
  final double outstandingAmount;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.address,
    this.outstandingAmount = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessId': businessId,
        'name': name,
        'phone': phone,
        'address': address,
        'outstandingAmount': outstandingAmount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String,
        businessId: json['businessId'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        outstandingAmount: (json['outstandingAmount'] as num?)?.toDouble() ?? 0.0,
        createdAt: parseModelDate(json['createdAt']),
      );

  Customer copyWith({
    String? name,
    String? phone,
    String? address,
    double? outstandingAmount,
  }) {
    return Customer(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      createdAt: createdAt,
    );
  }
}
