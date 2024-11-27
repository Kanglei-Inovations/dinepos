import 'package:hive/hive.dart';

part 'menuItem.g.dart'; // Make sure to run build_runner to generate the '.g.dart' file

@HiveType(typeId: 0)
class MenuItem {
  @HiveField(0)
  final String id;

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
  final String? description; // New field for description

  @HiveField(9)
  final String? imageUrl; // New field for image URL

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
    this.imageUrl,
  });
}
