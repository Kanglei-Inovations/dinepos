import 'package:hive/hive.dart';

part 'invoice_items_model.g.dart';

@HiveType(typeId: 0)
class InvoiceItem {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String invoiceId;  // Ensure this is an int, not a String.

  @HiveField(2)
  final String itemName;

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final double price;

  @HiveField(5)
  final double total;

  InvoiceItem({
    required this.id,
    required this.invoiceId,  // Make sure the type is int
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.total,
  });
}
