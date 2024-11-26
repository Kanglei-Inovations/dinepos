import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EditMenuItemDialog extends StatefulWidget {
  final int id; // The Hive index of the menu item
  final String name;
  final double price;
  final double? offerPrice;
  final int stock;
  final String category;
  final String? subCategory;

  const EditMenuItemDialog({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    this.offerPrice,
    required this.stock,
    required this.category,
    this.subCategory,
  });

  @override
  _EditMenuItemDialogState createState() => _EditMenuItemDialogState();
}

class _EditMenuItemDialogState extends State<EditMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late double price;
  late double? offerPrice;
  late int stock;
  late String category;
  String? subCategory;

  @override
  void initState() {
    super.initState();
    name = widget.name;
    price = widget.price;
    offerPrice = widget.offerPrice;
    stock = widget.stock;
    category = widget.category;
    subCategory = widget.subCategory;
  }

  void _updateMenuItem() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final menuItemsBox = Hive.box('menu_items');

      // Update the menu item
      menuItemsBox.putAt(widget.id, {
        'name': name,
        'price': price,
        'offerPrice': offerPrice,
        'stock': stock,
        'category': category,
        'subcategory': subCategory,
      });

      Navigator.of(context).pop(); // Close the dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Edit Menu Item",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  initialValue: name,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Name is required' : null,
                  onSaved: (value) => name = value!,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: price.toString(),
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value == null || double.tryParse(value) == null
                      ? 'Enter a valid price'
                      : null,
                  onSaved: (value) => price = double.parse(value!),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: offerPrice?.toString(),
                  decoration: InputDecoration(labelText: 'Offer Price (Optional)'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => offerPrice = value?.isEmpty ?? true
                      ? null
                      : double.parse(value!),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: stock.toString(),
                  decoration: InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                  value == null || int.tryParse(value) == null
                      ? 'Enter a valid stock quantity'
                      : null,
                  onSaved: (value) => stock = int.parse(value!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(labelText: 'Category'),
                  items: ['Vegetable', 'Non-Vegetable']
                      .map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ))
                      .toList(),
                  onChanged: (value) => setState(() => category = value!),
                ),
                const SizedBox(height: 10),
                if (category == 'Non-Vegetable')
                  DropdownButtonFormField<String>(
                    value: subCategory,
                    decoration: InputDecoration(labelText: 'Subcategory'),
                    items: ['Beef', 'Chicken', 'Fish']
                        .map((sub) => DropdownMenuItem(
                      value: sub,
                      child: Text(sub),
                    ))
                        .toList(),
                    onChanged: (value) => setState(() => subCategory = value),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: _updateMenuItem,
                      child: Text("Update"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
