class MenuItem {
  final String id;
  final String name;
  final double price;
  final double offerPrice;
  final int stock;
  final String category;
  final String? subCategory;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.offerPrice,
    required this.stock,
    required this.category,
    this.subCategory,
  });
}
