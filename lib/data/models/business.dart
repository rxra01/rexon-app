import 'date_helper.dart';

class Business {
  final String id;
  final String ownerUid;
  final String name;
  final String type; // "retailer"
  final String ownerName;
  final String phone;
  final String? email;
  final String address;
  final String? gstin;
  final String? logoUrl;
  final String currency;
  final DateTime createdAt;

  Business({
    required this.id,
    required this.ownerUid,
    required this.name,
    this.type = 'retailer',
    required this.ownerName,
    required this.phone,
    this.email,
    required this.address,
    this.gstin,
    this.logoUrl,
    this.currency = '₹',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerUid': ownerUid,
        'name': name,
        'type': type,
        'ownerName': ownerName,
        'phone': phone,
        'email': email,
        'address': address,
        'gstin': gstin,
        'logoUrl': logoUrl,
        'currency': currency,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Business.fromJson(Map<String, dynamic> json) => Business(
        id: json['id'] as String,
        ownerUid: json['ownerUid'] as String,
        name: json['name'] as String,
        type: json['type'] as String? ?? 'retailer',
        ownerName: json['ownerName'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        address: json['address'] as String,
        gstin: json['gstin'] as String?,
        logoUrl: json['logoUrl'] as String?,
        currency: json['currency'] as String? ?? '₹',
        createdAt: parseModelDate(json['createdAt']),
      );

  Business copyWith({
    String? name,
    String? type,
    String? ownerName,
    String? phone,
    String? email,
    String? address,
    String? gstin,
    String? logoUrl,
    String? currency,
  }) {
    return Business(
      id: id,
      ownerUid: ownerUid,
      name: name ?? this.name,
      type: type ?? this.type,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      logoUrl: logoUrl ?? this.logoUrl,
      currency: currency ?? this.currency,
      createdAt: createdAt,
    );
  }
}
