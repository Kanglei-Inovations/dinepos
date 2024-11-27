import 'dart:io';

import 'package:flutter/material.dart';
import '../model/menuItem.dart';
import '../provider/menu_items.dart';
import '../utils/const.dart';
import '../utils/responsive.dart';
import '../widget/add_items.dart';
import '../widget/edit_menu_dialog.dart';
import 'package:provider/provider.dart'; // Make sure to import provider

class MenuItemsScreen extends StatefulWidget {
  const MenuItemsScreen({super.key});

  @override
  _MenuItemsScreenState createState() => _MenuItemsScreenState();
}

class _MenuItemsScreenState extends State<MenuItemsScreen> {
  String searchQuery = '';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuProvider = Provider.of<MenuItemsProvider>(context, listen: false);
      menuProvider.loadMenuItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "Menu Items",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: defaultPadding * 1.5,
                      vertical: defaultPadding / (Responsive.isMobile(context) ? 2 : 1),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddMenuItem(),
                    ).then((_) => setState(() {})); // Refresh after adding
                  },
                  icon: Icon(Icons.add),
                  label: Text("Add Menu Item"),
                ),
              ],
            ),
            Consumer<MenuItemsProvider>(
              builder: (context, menuProvider, _) {
                final menuItems = menuProvider.menuItems.where((item) {
                  final itemName = item.name.toLowerCase();
                  return itemName.contains(searchQuery.toLowerCase());
                }).toList();

                if (menuItems.isEmpty) {
                  return Center(child: Text("No menu items available"));
                }

                return SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    columnSpacing: defaultPadding,
                    columns: [
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Price")),
                      DataColumn(label: Text("Offer Price")),
                      DataColumn(label: Text("Stock")),
                      DataColumn(label: Text("Category")),
                      if (!Responsive.isMobile(context))
                        DataColumn(label: Text("Subcategory")),
                      DataColumn(label: Text("Actions")),
                    ],
                    rows: List.generate(
                      menuItems.length,
                          (index) => menuItemDataRow(menuItems[index], index, menuProvider, context),
                    ),
                  ),
                );
              },
            )


          ],
        ),
      ),
    );
  }

  // Pass menuProvider to the data row
  DataRow menuItemDataRow(
      MenuItem menuItem, int index, MenuItemsProvider menuProvider, BuildContext context) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Show enlarged image in a dialog
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          menuItem.imageUrl!.isNotEmpty
                              ?Image.file(
                            File(menuItem.imageUrl ?? 'https://via.placeholder.com/40'), // Use File class to load the local image
                            fit: BoxFit.cover,
                          ):Icon(Icons.fireplace),

                          Text(
                            menuItem.name,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                  child: menuItem.imageUrl!.isNotEmpty
                  ?Image.file(
                    File(menuItem.imageUrl ?? 'https://via.placeholder.com/40'), // Use File class to load the local image
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                  ):Icon(Icons.fireplace)

                ),
              ),
              SizedBox(width: 8), // Space between the image and name
              Text(menuItem.name),
            ],
          ),
        ),
        DataCell(Text('\$${menuItem.price}')),
        DataCell(menuItem.offerPrice != null && menuItem.offerPrice > 0
            ? Text('\$${menuItem.offerPrice}')
            : Text('-')),
        DataCell(Text(menuItem.stock.toString())),
        DataCell(Text(menuItem.category)),
        if (!Responsive.isMobile(context))
          DataCell(Text(menuItem.subCategory ?? '-')),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EditMenuItemDialog(
                      id: menuItem.id,
                      name: menuItem.name,
                      price: menuItem.price,
                      offerPrice: menuItem.offerPrice,
                      stock: menuItem.stock,
                      category: menuItem.category,
                      subCategory: menuItem.subCategory,
                      unitType: menuItem.unitType,
                    ),
                  ).then((_) => setState(() {})); // Refresh after editing
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  // Call deleteMenuItem from MenuProvider
                  menuProvider.deleteMenuItem(menuItem.id);
                  setState(() {}); // Refresh the UI after deletion
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

}
