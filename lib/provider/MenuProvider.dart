import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../model/menuItem.dart';

class MenuItemsProvider with ChangeNotifier {
  late Box<MenuItem> _menuBox;

  MenuItemsProvider() {
    loadMenuItems();
    _menuBox = Hive.box<MenuItem>('menu_items');  // Get the already opened box
  }

  // Getter for menuItems to expose the list
  List<MenuItem> get menuItems => _menuBox.values.toList();

  // Map to store menu items with their ID as the key
  List<MenuItem> _menuItems = []; // Map with int as key and MenuItem as value
  // Fetch menu items from Hive and convert them into a map
  void loadMenuItems() {
    final menuItemsBox = Hive.box<MenuItem>('menu_items');
    _menuItems = menuItemsBox.values.toList();
    notifyListeners();
  }
  // Add a menu item to Hive box
  void addMenuItem(MenuItem item) {
    _menuBox.put(item.id, item);  // Store the menu item in Hive box using the id as the key
    loadMenuItems(); // Reload the menu items to sync with the local map
    notifyListeners();
  }

  // Optionally, you can add a method to remove or update items
  void deleteMenuItem(int id) {
    print('Attempting to delete item with ID: $id');
    _menuBox.delete(id); // Remove the menu item from Hive using its ID
    _menuItems.remove(id); // Also remove from the local map
    notifyListeners();
  }

  Future<void> restoreMenuItems(List<dynamic> items) async {
    try {
      if (items != null) {
        // Convert the list into a Map for batch insertion
        final dataMap = {for (var item in items) item['id']: MenuItem.fromJson(item)};

        // Use putAll for batch insertions
        await _menuBox.putAll(dataMap);

        // Refresh in-memory data
        _menuItems = _menuBox.values.toList();
        notifyListeners();
        debugPrint('Menu items restored successfully.');
      }
    } catch (e) {
      debugPrint('Error restoring menu items: $e');
    }
  }



  // Method to update a menu item
  void updateMenuItem(int id, String itemName, double price, double? offerPrice, int stock, String category, String? subCategory, String? imageUrl, String? description) {
    final menuItemsBox = Hive.box<MenuItem>('menu_items');
print(id);

    try {
      // Create the updated menu item
      final updatedMenuItem = MenuItem(
        id: id, // id is now an int
        itemName: itemName,
        price: price,
        offerPrice: offerPrice ?? 0.0, // Handle nullable offerPrice
        stock: stock,
        category: category,
        subCategory: subCategory,
        unitType: '', // Include unit type if necessary
        imageUrl: imageUrl??'',
        description: description,// Ensure a value is passed for imageUrl
      );
      menuItemsBox.put(id, updatedMenuItem); // Use the ID as the key
      notifyListeners(); // Notify listeners to rebuild widgets
    } catch (e) {
      print("Error Update from Database: $e");
    }
  }


  // Method to get a specific menu item by its ID
  MenuItem getMenuItemById(int id) {
    return _menuBox.values.firstWhere(
          (item) => item.id == id,
      orElse: () => MenuItem(  // Returning a default MenuItem if not found
        id: 0,
        itemName: 'Unknown',
        price: 0.0,
        offerPrice: 0.0,
        stock: 0,
        category: 'Unknown',
        subCategory: 'Unknown',
        unitType: 'Unknown',
        imageUrl: '',  // Default empty image URL
      ),
    );
  }
}
