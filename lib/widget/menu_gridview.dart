import 'dart:io';
import 'package:badges/badges.dart';
import 'package:dinepos/widget/unit_icons.dart';
import 'package:flutter/material.dart';
import '../model/invoice_items_model.dart';
import '../model/menuItem.dart';
import '../utils/responsive.dart';
import 'package:badges/badges.dart' as badges;
class MenuScreen extends StatefulWidget {
  final List<MenuItem> filteredMenuItems;
  final List<InvoiceItem> invoiceItems;
  final Function(MenuItem) addMenuItem;
  final Function(MenuItem) removeMenuItem;

  const MenuScreen({
    required this.invoiceItems,
    required this.filteredMenuItems,
    required this.addMenuItem,
    required this.removeMenuItem,
    Key? key,
  }) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    print(size.width);
    return Expanded(
      child: Responsive(
        mobile: MenuGridView(
          crossAxisCount: size.width < 650 ? 2 : 4,
          childAspectRatio: size.width < 650 ? 0.9 : 0.7,
          filteredMenuItems: widget.filteredMenuItems,
          invoiceItems: widget.invoiceItems,
          addMenuItem: widget.addMenuItem,
          removeMenuItem: widget.removeMenuItem,
        ),
        tablet: MenuGridView(
          crossAxisCount: 4,
          childAspectRatio: 0.6,
          filteredMenuItems: widget.filteredMenuItems,
          invoiceItems: widget.invoiceItems,
          addMenuItem: widget.addMenuItem,
          removeMenuItem: widget.removeMenuItem,
        ),
        desktop: MenuGridView(
          crossAxisCount: size.width < 1400 ? 4 : 5,
          childAspectRatio: size.width < 1400 ? 0.9 : 0.8,
          filteredMenuItems: widget.filteredMenuItems,
          invoiceItems: widget.invoiceItems,
          addMenuItem: widget.addMenuItem,
          removeMenuItem: widget.removeMenuItem,
        ),
      ),
    );
  }
}

class MenuGridView extends StatefulWidget {
  const MenuGridView({
    Key? key,
    required this.filteredMenuItems,
    required this.invoiceItems,
    required this.addMenuItem,
    required this.removeMenuItem,
    this.crossAxisCount = 4,
    this.childAspectRatio = 1,
  }) : super(key: key);

  final List<MenuItem> filteredMenuItems;
  final List<InvoiceItem> invoiceItems;
  final Function(MenuItem) addMenuItem;
  final Function(MenuItem) removeMenuItem;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  State<MenuGridView> createState() => _MenuGridViewState();
}

class _MenuGridViewState extends State<MenuGridView> {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemCount: widget.filteredMenuItems.length,
      itemBuilder: (context, index) {
        final item = widget.filteredMenuItems[index];

        // Find the corresponding InvoiceItem in the invoiceItems list
        final invoiceItem = widget.invoiceItems.firstWhere(
              (invoiceItem) => invoiceItem.id == item.id,
          orElse: () => InvoiceItem(id: item.id, price: item.price, quantity: 0, invoiceId: '', itemName: '', total: 0),  // Default value when not found
        );

        return Stack(
          children: [
            Card(
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildItemImage(item.imageUrl ?? '', item.category), // Updated image with category badge


                    Text(item.name),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Text(
                        ' ₹${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.redAccent,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        '₹${item.offerPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decrement Button
                      IconButton(
                        onPressed: () => widget.removeMenuItem(item),
                        icon: Icon(Icons.remove, color: Colors.redAccent),
                      ),
                      // Quantity Display (from the matched InvoiceItem)
                      Text(
                        '${invoiceItem.quantity}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Increment Button
                      IconButton(
                        onPressed: () => widget.addMenuItem(item),
                        icon: Icon(Icons.add, color: Colors.green),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                      ),

                      onPressed: (invoiceItem.quantity <= 0) ? () => widget.addMenuItem(item) : null, // Disable if quantity is 0 or less
                      child: Text(
                        'Add to Cart',
                        style: TextStyle(color: invoiceItem.quantity <= 0 ? Colors.white : Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: _buildBadgeQtyIcon(item.category, invoiceItem.quantity),),
            Positioned(
              top: 0,
              left: 0,
              child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child:     badges.Badge(

                    badgeStyle: badges.BadgeStyle(
                      padding: EdgeInsets.all(5),
                      shape: badges.BadgeShape.square, // Make the badge square
                      badgeColor: Colors.white, // Badge color based on type
                      borderSide: BorderSide(
                        color: item.category == "Vegetable" ? Colors.green : Colors.red , // Border color (can be customized)
                        width: 2, // Thickness of the border
                      ),
                    ),
                    badgeContent: Icon(
                      item.category == "Non-Vegetable" ? Icons.circle : Icons.circle, // Icon for Veg/Non-Veg
                      color:item.category == "Vegetable" ? Colors.green : Colors.red,
                      size: 12,
                    ),

                  )
              ),)

          ],
        );
      },
    );
  }
}

Widget _buildItemImage(String imageUrl, String category) {
  return Expanded(
    child: imageUrl != null && imageUrl.isNotEmpty
        ? Image.file(
      File(imageUrl),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.image_not_supported,
        size: 50,
        color: Colors.grey,
      ),
    )
        : Image.network(
      'https://via.placeholder.com/150',
      fit: BoxFit.cover,
    ),
  );
}
Widget _buildBadgeQtyIcon(String category,qty) {
  return badges.Badge(
    showBadge: qty>=1 ? true : false,
    badgeContent: Text('${qty}'),
     child: qty>=1 ? Container(
      child: Icon(Icons.shopping_cart),
    ): Container() // Empty container to overlay the badge on the image
  );
}