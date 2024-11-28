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
      title: Text('Add Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
      content : SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextFormField('Customer Name', Icons.person, _nameController),
              _buildTextFormField('Phone', Icons.phone, _phoneController, isNumber: true),
               _buildTextFormField('Address', Icons.home, _addressController, isMultiline: true),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Navigate to InvoiceMaking page with customer details
                    Get.to(() => CreateInvoice(), arguments: {
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
  Widget _buildTextFormField(String label, IconData icon, TextEditingController controller,
      {bool isNumber = false, bool isEmail = false, bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber
            ? TextInputType.phone
            : isEmail
            ? TextInputType.emailAddress
            : isMultiline
            ? TextInputType.multiline
            : TextInputType.text,
        maxLines: isMultiline ? null : 1,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Please enter a valid email address';
          }
          if (isNumber && !RegExp(r'^[0-9]+$').hasMatch(value)) {
            return 'Please enter a valid phone number';
          }
          return null;
        },
      ),
    );
  }
}

class InvoiceMakingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final customerDetails = Get.arguments as Map<String, String>;

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice Making'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer Name: ${customerDetails['name']}'),
            Text('Phone: ${customerDetails['phone']}'),
            Text('Email: ${customerDetails['email']}'),
            Text('Address: ${customerDetails['address']}'),
            // Add your invoice-making functionality here
          ],
        ),
      ),
    );
  }
}
