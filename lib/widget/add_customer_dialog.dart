import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../pages/create_invoice.dart';
import '../utils/const.dart';

class AddCustomer extends StatefulWidget {
  @override
  _AddCustomerState createState() => _AddCustomerState();
}

class _AddCustomerState extends State<AddCustomer> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    // Dispose controllers when the widget is disposed
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: secondaryColor,
      shadowColor: bgColor,
      title: Text(
        'Add Customer',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextFormField(
                'Phone',
                Icons.phone,
                _phoneController,
                isNumber: true,
              ),
              _buildTextFormField(
                'Customer Name',
                Icons.person,
                _nameController,
                isOptional: true, // Make optional
              ),
              _buildTextFormField(
                'Address',
                Icons.home,
                _addressController,
                isOptional: true, // Make optional
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Navigate to InvoiceMaking page with customer details
                    Get.to(() => CreateInvoice(name: _nameController.text,
                      phone: _phoneController.text,
                      address: _addressController.text,), arguments: {
                      'name': _nameController.text,
                      'phone': _phoneController.text,
                      'address': _addressController.text,
                    });
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build a text form field
  Widget _buildTextFormField(
      String label,
      IconData icon,
      TextEditingController controller, {
        bool isNumber = false,
        bool isOptional = false,
        bool autofocus = true, // New parameter
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
        autofocus: autofocus, // Apply autofocus
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (!isOptional && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          }
          if (isNumber &&
              value != null &&
              value.isNotEmpty &&
              !RegExp(r'^[0-9]+$').hasMatch(value)) {
            return 'Enter a valid phone number';
          }
          return null;
        },
      ),
    );
  }

}
