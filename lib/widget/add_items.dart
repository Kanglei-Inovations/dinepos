import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/menuItem.dart';
import '../provider/menu_items.dart';
import 'package:path_provider/path_provider.dart';

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
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  // Image picker related variables
  File? _imageFile;

  String category = 'Vegetable'; // Default category
  String? subCategory; // Subcategory for non-vegetable items
  String unitType = 'Full'; // Default unit type (Full)

  // Method to clear all fields
  void clearFields() {
    _nameController.clear();
    _priceController.clear();
    _offerPriceController.clear();
    _stockController.clear();
    _descriptionController.clear();
    _imageUrlController.clear();
    setState(() {
      category = 'Vegetable';
      subCategory = null;
      unitType = 'Full'; // Reset unit type to default
      _imageFile = null; // Reset image selection
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
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
  Future<Directory> getWritableDirectory() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Use the user's home directory or a custom folder
      final home = Directory.current;
      return Directory('${home.path}/dbImage')..createSync(recursive: true);
    } else {
      // Use standard app document directory for mobile platforms
      return getApplicationDocumentsDirectory();
    }
  }
  // Method to pick an image from the gallery or camera
  Future<void> _pickImage() async {
    try {
      // Pick an image file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        String? filePath = result.files.single.path;

        if (filePath != null) {
          final originalFile = File(filePath);

          // Check if file exists
          if (await originalFile.exists()) {
            // Get writable directory based on platform
            final directory = await getWritableDirectory();
            final fileName = result.files.single.name;

            // Construct the target path
            final targetFilePath = '${directory.path}/$fileName';

            // Copy the file to the target directory
            final copiedFile = await originalFile.copy(targetFilePath);

            // Update the state with the new file path
            setState(() {
              _imageFile = copiedFile;
            });
            print('File copied to: $targetFilePath');
          } else {
            throw Exception('File not found at path: $filePath');
          }
        } else {
          throw Exception('Selected file path is null.');
        }
      } else {
        print('No file selected.');
      }
    } catch (e) {
      print('An error occurred while picking the file: $e');
    }
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
                _buildTextFormField('Description', _descriptionController),

                // Image Picker Section
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _imageFile == null
                        ? Center(child: Text("Tap to select an image"))
                        : Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // Category Dropdown
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

                // Unit Type Dropdown
                DropdownButtonFormField<String>(
                  value: unitType,
                  decoration: InputDecoration(labelText: 'Unit Type'),
                  items: ['Full', 'Half', 'Kg'].map((unit) {
                    return DropdownMenuItem(value: unit, child: Text(unit));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      unitType = value ?? 'Full';
                    });
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final randomId = Random().nextInt(100000);  // Random ID between 0 and 999999
                      final newMenuItem = MenuItem(
                        id: randomId,
                        name: _nameController.text,
                        price: double.tryParse(_priceController.text) ?? 0.0,
                        offerPrice: double.tryParse(_offerPriceController.text) ?? 0.0,
                        stock: int.tryParse(_stockController.text) ?? 0,
                        category: category,
                        subCategory: subCategory,
                        unitType: unitType,
                        description: _descriptionController.text,
                        imageUrl: _imageFile?.path ?? "", // Save the image path
                      );

                      // Get the MenuProvider from the context
                      final menuProvider = Provider.of<MenuItemsProvider>(context, listen: false);
                      menuProvider.addMenuItem(newMenuItem);
                      clearFields(); // Clear fields without closing the dialog
                    }
                  },
                  child: Text('Add Item'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
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
