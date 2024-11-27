import 'package:hive/hive.dart';

part 'menuItem.g.dart'; // Make sure to run build_runner to generate the '.g.dart' file

@HiveType(typeId: 0)
class MenuItem {
  @HiveField(0)
  final int id; // Change id from String to int

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
  final String imageUrl; // Make imageUrl required (no longer nullable)

  MenuItem({
    required this.id, // id is now an int
    required this.name,
    required this.price,
    required this.offerPrice,
    required this.stock,
    required this.category,
    this.subCategory,
    required this.unitType,
    this.description,
    required this.imageUrl, // imageUrl is required
  });
}
