import 'package:hive/hive.dart';

part 'menuItem.g.dart'; // Make sure to run build_runner to generate the '.g.dart' file

@HiveType(typeId: 2)
class MenuItem {
  @HiveField(0)
  final int id; // id is an int

  @HiveField(1)
  final String itemName;

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
    required this.itemName,
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
  // Factory constructor for JSON deserialization
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      itemName: json['itemName'],
      price: json['price'],
      offerPrice: json['offerPrice'],
      stock: json['stock'],
      category: json['category'],
      subCategory: json['subCategory'],
      unitType: json['unitType'],
      description: json['description'],
      imageUrl: json['imageUrl'],
    );
  }

  // Method to convert a MenuItem to JSON (optional, for backup or debugging)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemName': itemName,
      'price': price,
      'offerPrice': offerPrice,
      'stock': stock,
      'category': category,
      'subCategory': subCategory,
      'unitType': unitType,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}
