import 'package:hive/hive.dart';

part 'menuItem.g.dart'; // Make sure to run build_runner to generate the '.g.dart' file

@HiveType(typeId: 2)
class MenuItem {
  @HiveField(0)
  final int id; // id is an int

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double price;

  @HiveField(3)
  final double offerPrice;

  @HiveField(4)
  final int stock;

  @HiveField(5)
  final String category;

  @HiveField(6)
  final String? subCategory;

  @HiveField(7)
  final String unitType;

  @HiveField(8)
  final String? description; // Optional description field

  @HiveField(9)
  final String imageUrl; // Required imageUrl

  @HiveField(10)
  int quantity; // Mutable quantity field to track the item count in invoices

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.offerPrice,
    required this.stock,
    required this.category,
    this.subCategory,
    required this.unitType,
    this.description,
    required this.imageUrl,
    this.quantity = 0, // Default quantity is 0
  });

  // Method to add quantity
  void addQuantity(int value) {
    quantity += value;
  }

  // Method to reset quantity
  void resetQuantity() {
    quantity = 0;
  }
}
