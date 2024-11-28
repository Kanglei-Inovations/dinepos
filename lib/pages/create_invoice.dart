import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/menuItem.dart';
import '../provider/menu_items.dart';
import '../utils/const.dart';

class CreateInvoice extends StatefulWidget {
  @override
  _CreateInvoiceState createState() => _CreateInvoiceState();
}

class _CreateInvoiceState extends State<CreateInvoice> {
  List<MenuItem> invoiceItems = [];
  double subtotal = 0.0;
  double discount = 0.0;
  double afterDiscount = 0.0;
  double taxRate = 0.0;
  double taxAmount = 0.0;
  double total = 0.0;
  String searchQuery = '';
  double amountPaid = 0.0; // Tracks the amount paid
  String selectedPaymentType = 'Cash'; // Tracks the selected payment type

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuProvider = Provider.of<MenuItemsProvider>(context, listen: false);
      menuProvider.loadMenuItems();
    });
  }

  void _calculateTotals() {
    setState(() {
      subtotal = invoiceItems.fold(
        0,
            (sum, item) => sum + item.price * item.quantity,
      );
      afterDiscount = subtotal - discount;
      taxAmount = afterDiscount * (taxRate / 100);
      total = afterDiscount + taxAmount;
    });
  }

  void _addMenuItem(MenuItem menuItem) {
    setState(() {
      final existingIndex = invoiceItems.indexWhere((item) => item.name == menuItem.name);
      if (existingIndex == -1) {
        invoiceItems.add(MenuItem(
          name: menuItem.name,
          price: menuItem.price,
          imageUrl: menuItem.imageUrl,
          quantity: 1,
          id: 1,
          offerPrice: menuItem.offerPrice,
          stock: menuItem.stock,
          category: '',
          unitType: '',
        ));
      } else {
        invoiceItems[existingIndex].quantity += 1;
      }
      _calculateTotals();
    });
  }
// Function to submit invoice
  Future<void> _submitOrder() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Don not forget to Collect Payment'),
        duration: Duration(seconds: 2),
      ),
    );
    // Call provider method to save invoice in SQL database


  }
  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuItemsProvider>(context);
    final filteredMenuItems = menuProvider.menuItems.where((menuItem) {
      return menuItem.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(

      body: Row(
        children: [
          // First row: Grid of menu items
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Menu Item',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredMenuItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredMenuItems[index];
                      return Card(
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Image.file(
                                File(item.imageUrl ?? 'https://via.placeholder.com/40'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text(item.name, style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Text('₹${item.price.toStringAsFixed(2)}'),
                            ElevatedButton(
                              onPressed: () => _addMenuItem(item),
                              child: Text('Add to Cart'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Second row: Invoice table
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(15)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Qty')),
                          DataColumn(label: Text('Total')),
                        ],
                        rows: invoiceItems.map((item) {
                          return DataRow(cells: [
                            DataCell(Text(item.name)),
                            DataCell(Text('₹${item.price.toStringAsFixed(2)}')),
                            DataCell(

                              SizedBox(
                                width: 60,
                                child: TextFormField(
                                  onChanged: (value) {
                                    setState(() {
                                      final newQty = int.tryParse(value) ?? 1;
                                      item.quantity =
                                      newQty > 0 ? newQty : 1; // Ensure quantity is at least 1
                                      _calculateTotals(); // Recalculate totals when quantity changes
                                    });
                                  },
                                  keyboardType: TextInputType.number,
                                  controller: TextEditingController(text: item.quantity.toString()),
                                  decoration: InputDecoration(
                                    floatingLabelBehavior: FloatingLabelBehavior.auto, // Animates label
                                    filled: true,
                                    fillColor: secondary2Color, // Light background color

                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide(
                                        color: Colors.red, // Error border color
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide(
                                        color: Colors.red, // Focused error border color
                                        width: 2,
                                      ),
                                    ),

                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter QTY';
                                    }
                                    if (!RegExp(r'^\d+$').hasMatch(value)) {
                                      return 'Please enter only numbers';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            DataCell(Text('₹${(item.price * item.quantity).toStringAsFixed(2)}')),
                          ]);
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end, // Align to the right
                        children: [
                          Card(
                            elevation: 5,
                            child: Container(
                              width: 450, // Fixed width for consistent layout
                              padding: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blueGrey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    title: Text('Subtotal'),
                                    trailing: Text('₹${subtotal.toStringAsFixed(2)}'),
                                  ),
                                  ListTile(
                                    title: TextField(
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        fillColor: secondary2Color,
                                        filled: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(Radius.circular(10)),
                                          borderSide: BorderSide.none,
                                        ),
                                        labelText: 'Discount (₹)',
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          discount = double.tryParse(value) ?? 0.0;
                                          _calculateTotals();
                                        });
                                      },
                                    ),
                                    trailing: Text('After Dis: ₹${afterDiscount.toStringAsFixed(2)}'),
                                  ),
                                  ListTile(
                                    title: TextField(
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        fillColor: secondary2Color,
                                        filled: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(Radius.circular(10)),
                                          borderSide: BorderSide.none,
                                        ),
                                        labelText: 'Tax Rate (%)',
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          taxRate = double.tryParse(value) ?? 0.0;
                                          _calculateTotals();
                                        });
                                      },
                                    ),
                                    trailing: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Tax Amount: ₹${taxAmount.toStringAsFixed(2)}'),
                                        Text(
                                          'After Tax: ₹${total.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ListTile(
                                    title: TextField(
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        fillColor: secondary2Color,
                                        filled: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(Radius.circular(10)),
                                          borderSide: BorderSide.none,
                                        ),
                                        labelText: 'Paid Amount',
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          amountPaid = double.tryParse(value) ?? 0.0;
                                          _calculateTotals();
                                        });
                                      },
                                    ),
                                    trailing: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Amount Due:', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(
                                          '₹${(total - amountPaid).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Payment Type:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: RadioListTile(
                                          title: Text('Cash'),
                                          value: 'Cash',
                                          groupValue: selectedPaymentType,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedPaymentType = value!;
                                            });
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile(
                                          title: Text('UPI'),
                                          value: 'UPI',
                                          groupValue: selectedPaymentType,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedPaymentType = value!;
                                            });
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile(
                                          title: Text('Due'),
                                          value: 'Due',
                                          groupValue: selectedPaymentType,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedPaymentType = value!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),


        ],

      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 10,
        onPressed: _submitOrder, // Submit Order function
        label: Text('Save Sell'), // Adds label text to the button
        icon: Icon(Icons.arrow_forward),
        backgroundColor: primaryColor,
        tooltip: 'Save invoice to Database', // Detailed tooltip
      ),
    );
  }
}
