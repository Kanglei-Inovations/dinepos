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
    required this.invoiceId,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.total,
  });
  // FromJson constructor to handle null values in parsing
  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] ?? 0,  // Default to 0 if id is null
      invoiceId: json['invoiceId'] ?? '',  // Default to empty string if null
      itemName: json['itemName'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: json['price']?.toDouble() ?? 0.0,
      total: json['total']?.toDouble() ?? 0.0,
    );
  }

  /// Method to convert an `InvoiceItem` object to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'itemName': itemName,
      'quantity': quantity,
      'price': price,
      'total': total,
    };
  }
}
