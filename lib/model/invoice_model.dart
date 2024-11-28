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
}
