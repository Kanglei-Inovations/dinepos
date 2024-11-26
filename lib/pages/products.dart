import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../const.dart';
import '../responsive.dart';
import '../widget/add_items.dart';
import '../widget/edit_menu_dialog.dart';

class MenuItemsScreen extends StatefulWidget {
  const MenuItemsScreen({super.key});

  @override
  _MenuItemsScreenState createState() => _MenuItemsScreenState();
}

class _MenuItemsScreenState extends State<MenuItemsScreen> {
  final menuItemsBox = Hive.box('menu_items'); // Ensure this box is initialized in main.dart
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            ValueListenableBuilder(
              valueListenable: menuItemsBox.listenable(),
              builder: (context, Box box, _) {
                final menuItems = box.values.where((item) {
                  final itemName = item['name'].toString().toLowerCase();
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
                          (index) => menuItemDataRow(menuItems[index], index, context),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  DataRow menuItemDataRow(dynamic menuItem, int index, BuildContext context) {
    return DataRow(
      cells: [
        DataCell(Text(menuItem['name'])),
        DataCell(Text('\$${menuItem['price']}')),
        DataCell(menuItem['offerPrice'] != null && menuItem['offerPrice'] > 0
            ? Text('\$${menuItem['offerPrice']}')
            : Text('-')),
        DataCell(Text(menuItem['stock'].toString())),
        DataCell(Text(menuItem['category'])),
        if (!Responsive.isMobile(context))
          DataCell(Text(menuItem['subcategory'] ?? '-')),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => EditMenuItemDialog(
                      id: index,
                      name: menuItem['name'],
                      price: menuItem['price'],
                      offerPrice: menuItem['offerPrice'],
                      stock: menuItem['stock'],
                      category: menuItem['category'],
                      subCategory: menuItem['subcategory'],
                    ),
                  ).then((_) => setState(() {})); // Refresh after editing
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  menuItemsBox.deleteAt(index);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
