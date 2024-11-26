import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/menuItem.dart';
import '../provider/menuprovider.dart';

class AddMenuItem extends StatefulWidget {
  @override
  _AddMenuItemState createState() => _AddMenuItemState();
}

class _AddMenuItemState extends State<AddMenuItem> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _offerPriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  String category = 'Vegetable'; // Default category
  String? subCategory; // Subcategory for non-vegetable items

  // Method to clear all fields
  void clearFields() {
    _nameController.clear();
    _priceController.clear();
    _offerPriceController.clear();
    _stockController.clear();
    setState(() {
      category = 'Vegetable';
      subCategory = null;
    });
    _formKey.currentState?.reset();
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is disposed
    _nameController.dispose();
    _priceController.dispose();
    _offerPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Menu Item'),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextFormField('Item Name', _nameController),
                Row(
                  children: [
                    Expanded(child: _buildNumberFormField('Price', _priceController)),
                    SizedBox(width: 10),
                    Expanded(child: _buildNumberFormField('Offer Price', _offerPriceController)),
                  ],
                ),
                _buildNumberFormField('Stock', _stockController),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(labelText: 'Category'),
                  items: ['Vegetable', 'Non-Vegetable'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      category = value ?? 'Vegetable';
                      subCategory = null; // Reset subcategory if category changes
                    });
                  },
                ),
                if (category == 'Non-Vegetable') ...[
                  DropdownButtonFormField<String>(
                    value: subCategory,
                    decoration: InputDecoration(labelText: 'Subcategory'),
                    items: ['Beef', 'Chicken', 'Fish'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        subCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a subcategory';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newMenuItem = MenuItem(
                id: DateTime.now().toString(),
                name: _nameController.text,
                price: double.tryParse(_priceController.text) ?? 0.0,
                offerPrice: double.tryParse(_offerPriceController.text) ?? 0.0,
                stock: int.tryParse(_stockController.text) ?? 0,
                category: category,
                subCategory: subCategory,
              );

              // Get the MenuProvider from the context
              final menuProvider = Provider.of<MenuProvider>(context, listen: false);
              menuProvider.addMenuItem(newMenuItem);

              clearFields(); // Clear fields without closing the dialog
            }
          },
          child: Text('Add Item'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }

  // Helper functions to build form fields
  Widget _buildTextFormField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildNumberFormField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
