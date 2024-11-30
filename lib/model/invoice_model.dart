import 'package:hive/hive.dart';

part 'invoice_model.g.dart';

@HiveType(typeId: 1)
class Invoice {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String phone;

  @HiveField(4)
  final String address;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final double subtotal;

  @HiveField(7)
  final double discount;

  @HiveField(8)
  final double taxRate;

  @HiveField(9)
  final double amountPaid;

  @HiveField(10)
  final String paymentType;

  @HiveField(11)
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.address,
    required this.status,
    required this.subtotal,
    required this.discount,
    required this.taxRate,
    required this.amountPaid,
    required this.paymentType,
    required this.createdAt,
  });

  // FromJson constructor to handle null values in parsing
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] ?? 0,  // Default to 0 if id is null
      userId: json['userId'] ?? '',  // Default to empty string if null
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? '',
      subtotal: json['subtotal']?.toDouble() ?? 0.0,
      discount: json['discount']?.toDouble() ?? 0.0,
      taxRate: json['taxRate']?.toDouble() ?? 0.0,
      amountPaid: json['amountPaid']?.toDouble() ?? 0.0,
      paymentType: json['paymentType'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Method to convert an `Invoice` object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'address': address,
      'status': status,
      'subtotal': subtotal,
      'discount': discount,
      'taxRate': taxRate,
      'amountPaid': amountPaid,
      'paymentType': paymentType,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
