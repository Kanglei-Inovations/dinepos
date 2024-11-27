import 'dart:io';
import 'package:flutter/material.dart';
import '../model/menuItem.dart';
import '../provider/menu_items.dart';
import '../utils/const.dart';
import '../utils/responsive.dart';
import '../widget/add_items.dart';
import '../widget/edit_menu_dialog.dart';
import 'package:provider/provider.dart';

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
    return Container(
      color: Colors.red,
      child: SingleChildScrollView(
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
                      DataColumn(label: Text("Price/Offer")),
                      DataColumn(label: Text("Stock")),
                      DataColumn(label: Text("Category")),
                      if (!Responsive.isMobile(context)) // Hide this column for mobile devices
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
            ),
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Using LayoutBuilder to get the available width
                          double width = constraints.maxWidth;
                          double imageSize = width * 0.25; // Responsive image size (25% of screen width)
                          double textSize = width * 0.04;  // Responsive text size (5% of screen width)

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              menuItem.imageUrl.isNotEmpty
                                  ? Image.file(
                                File(menuItem.imageUrl ?? 'https://via.placeholder.com/40'),
                                fit: BoxFit.cover,
                                height: imageSize,
                                width: imageSize,
                              )
                                  : Icon(Icons.fireplace, size: imageSize), // Default icon if no image is available

                              SizedBox(height: 8), // Add some space between image and text

                              Text(
                                menuItem.name,
                                style: TextStyle(
                                  fontSize: textSize,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center, // Center text
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                  child: menuItem.imageUrl.isNotEmpty
                      ? Image.file(
                    File(menuItem.imageUrl ?? 'https://via.placeholder.com/40'), // Use File class to load the local image
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                  )
                      : Icon(Icons.fireplace), // Default icon if no image is available
                ),
              ),
              SizedBox(width: 8), // Space between the image and name
              Expanded(
                child: Text(
                  menuItem.name,
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),

        DataCell(
          Responsive.isMobile(context)
              ? Column( // For mobile, use Column (stacked vertically)
            children: [
              if (menuItem.offerPrice != null && menuItem.offerPrice > 0)
                Text(
                  '\$${menuItem.price}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey, // Grey color for original price
                    decoration: TextDecoration.lineThrough, // Strikethrough effect
                  ),
                ),

              // Show offer price in bold and green if available
              if (menuItem.offerPrice != null && menuItem.offerPrice > 0)
                Text(
                  '\$${menuItem.offerPrice}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.green, // Green color for offer price
                    fontWeight: FontWeight.bold, // Bold text for offer price
                  ),
                ),
              // If no offer price, just display the normal price
              if (menuItem.offerPrice == null || menuItem.offerPrice <= 0)
                Text(
                  '\$${menuItem.price}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black, // Regular price in black
                  ),
                ),
            ],
          )
              : Row( // For larger screens, use Row (horizontal alignment)
            children: [
              if (menuItem.offerPrice != null && menuItem.offerPrice > 0)
                Text(
                  '\$${menuItem.price}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey, // Grey color for original price
                    decoration: TextDecoration.lineThrough, // Strikethrough effect
                  ),
                ),
              SizedBox(width: 5), // Space between the prices on large screens

              // Show offer price in bold and green if available
              if (menuItem.offerPrice != null && menuItem.offerPrice > 0)
                Text(
                  '\$${menuItem.offerPrice}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.green, // Green color for offer price
                    fontWeight: FontWeight.bold, // Bold text for offer price
                  ),
                ),
              // If no offer price, just display the normal price
              if (menuItem.offerPrice == null || menuItem.offerPrice <= 0)
                Text(
                  '\$${menuItem.price}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black, // Regular price in black
                  ),
                ),
            ],
          ),
        ),



        DataCell(
          Container(
            width: 60,// Use this on larger screens (tablet or desktop)
            height: 30,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: menuItem.stock >= 10 ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                menuItem.stock.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        DataCell(
          Container( // Use this on larger screens (tablet or desktop)
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: menuItem.category == 'Vegetable' ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center content inside Row
              children: [
                Icon(
                  menuItem.category == 'Vegetable' ? Icons.eco : Icons.local_dining,
                  size: 14,
                  color: Colors.white,
                ),
                SizedBox(width: 5),
                Text(
                  menuItem.category == 'Vegetable' ? 'Veg' : 'Non-Veg',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),


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
                      imageUrl: menuItem.imageUrl,
                      description: menuItem.description,
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
