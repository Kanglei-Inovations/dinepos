import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../model/menuItem.dart';

class MenuItemsProvider with ChangeNotifier {
  late Box<MenuItem> _menuBox;

  MenuItemsProvider() {
    loadMenuItems();
    _menuBox = Hive.box<MenuItem>('menu_items');  // Get the already opened box
  }

  // Getter for menuItems to expose the map
  List<MenuItem> get menuItems => _menuItems.values.toList();

  // List to store menu items
  Map<String, MenuItem> _menuItems = {};  // Use String as the key

  // Add a menu item to Hive box
  void addMenuItem(MenuItem item) {
    _menuBox.add(item);  // Store the menu item in Hive box
    loadMenuItems(); // Reload the menu items to sync with local map
    notifyListeners();
  }

  // Optionally, you can add a method to remove or update items
  void deleteMenuItem(String id) {
    _menuBox.delete(id); // Remove the menu item from Hive using its ID
    _menuItems.remove(id); // Also remove from the local map
    notifyListeners();
  }

// Fetch menu items from Hive and convert them into a map
  void loadMenuItems() {
    final menuItemsBox = Hive.box<MenuItem>('menu_items');
    _menuItems = {
      for (var item in menuItemsBox.values) item.id: item
    };
    notifyListeners(); // Notify listeners to rebuild widgets
  }

  // Method to update a menu item
  void updateMenuItem(String id, String name, double price, double? offerPrice, int stock, String category, String? subCategory) {
    final menuItemsBox = Hive.box<MenuItem>('menu_items');

    // Create the updated menu item
    final updatedMenuItem = MenuItem(
      id: id, // Ensure this matches the type used in MenuItem
      name: name,
      price: price,
      offerPrice: offerPrice ?? 0.0, // Handle nullable offerPrice
      stock: stock,
      category: category,
      subCategory: subCategory,
      unitType: '', // Include unit type if necessary
    );

    // Update the menu item in Hive
    menuItemsBox.put(id, updatedMenuItem); // Use the ID as key

    // Update the local map of menu items
    _menuItems[id] = updatedMenuItem; // Ensure map is updated with the new item

    notifyListeners(); // Notify listeners to rebuild widgets
  }

  // You can also provide a method to get a specific menu item by its ID
  MenuItem getMenuItemById(String id) {
    return _menuBox.values.firstWhere(
          (item) => item.id == id,
      orElse: () => MenuItem(  // Returning a default MenuItem
        id: '',
        name: 'Unknown',
        price: 0.0,
        offerPrice: 0.0,
        stock: 0,
        category: 'Unknown',
        subCategory: 'Unknown',
        unitType: 'Unknown',
      ),
    );
  }


}
