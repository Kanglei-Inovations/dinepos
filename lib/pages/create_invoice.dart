import 'dart:developer';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../model/invoice_items_model.dart';
import '../model/invoice_model.dart';
import '../model/menuItem.dart';
import '../provider/InvoiceProvider.dart';
import '../provider/MenuProvider.dart';
import '../utils/const.dart';
import '../utils/responsive.dart';
import '../widget/menu_gridview.dart';
import '../widget/papercut_design.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/services.dart';
import 'dart:async';

import '../widget/printer_settings-dialog.dart';

class CreateInvoice extends StatefulWidget {
  final String phone;
  final String? name;
  final String? address;

  const CreateInvoice(
      {super.key, required this.phone, this.name, this.address});

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
  double amountPaid = 0.0;
  String selectedPaymentType = 'Cash';
  final _formKey = GlobalKey<FormState>();

  int qty = 0;

  // Method to generate an invoice number based on the current time
  String generateInvoiceNumber() {
    const String prefix = "NAAZ";
    // Get the current time
    DateTime now = DateTime.now();

    // Format the hour (24-hour format) and minute
    String hour =
        now.hour.toString().padLeft(2, '0'); // 24-hour format (e.g., 09, 14)
    String minute =
        now.minute.toString().padLeft(2, '0'); // Format minute (e.g., 01, 25)
    // Combine into invoice number
    return "$prefix$hour$minute";
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
      final existingIndex =
          invoiceItems.indexWhere((item) => item.id == menuItem.id);
      if (existingIndex == -1) {
        invoiceItems.add(
          MenuItem(
            itemName: menuItem.itemName,
            price: menuItem.price,
            imageUrl: menuItem.imageUrl,
            quantity: 1,
            id: menuItem.id,
            offerPrice: menuItem.offerPrice,
            stock: menuItem.stock,
            category: menuItem.category,
            subCategory: menuItem.subCategory,
            unitType: menuItem.unitType,
          ),
        );
      } else {
        invoiceItems[existingIndex].quantity += 1;
      }
      _calculateTotals();
      _updateQty();
    });
  }

  void _removeMenuItem(MenuItem menuItem) {
    setState(() {
      final existingIndex =
          invoiceItems.indexWhere((item) => item.id == menuItem.id);
      if (existingIndex != -1) {
        if (invoiceItems[existingIndex].quantity > 1) {
          // Decrement quantity if greater than 1
          invoiceItems[existingIndex].quantity -= 1;
        } else {
          // Remove item if quantity is 1
          invoiceItems.removeAt(existingIndex);
        }
        _calculateTotals();
        _updateQty();
      }
    });
  }

  void _removeItem(MenuItem menuItem) {
    setState(() {
      // Remove all items with the matching id
      invoiceItems.removeWhere((item) => item.id == menuItem.id);
      // Recalculate totals and update quantities after removal
      _calculateTotals();
      _updateQty();
    });
  }



  int generateRandomTimestamp() {
    Random random = Random();

    // Generate a random number between 1 and 1,000,000
    int timestamp = random.nextInt(1000000000) + 1;  // Ensures the number is between 1 and 1,000,000

    return timestamp;
  }
  Future<void> _submitOrder(
      {required double subtotal,
      required String phone,
      required double balance,
      String? address,
      String? name,
      required double tax,
      required List<MenuItem> invoiceItems,
      required double discount}) async {
    try {
      Get.back();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Don\'t forget to collect payment.'),
          duration: Duration(seconds: 2),
        ),
      );
print(DateTime.now().millisecondsSinceEpoch);
      // Generate random ID for Invoice
      int invoiceId = generateRandomTimestamp();
      Invoice invoice = Invoice(
        id: invoiceId, // Unique ID
        userId: 'U123456', // Replace with actual user ID
        name: name ?? "", // Customer name
        phone: phone, // Customer phone
        address: address ?? "", // Customer address
        status: 'Pending', // Order status
        subtotal: subtotal, // Subtotal
        discount: discount, // Discount
        taxRate: taxAmount, // Tax rate
        amountPaid: subtotal + taxAmount - discount - balance, // Amount paid
        paymentType: 'Cash', // Payment type
        createdAt: DateTime.now(),
      );

      // Save the invoice using the provider
      final invoiceProvider =
          Provider.of<InvoiceProvider>(context, listen: false);
      invoiceProvider.addInvoice(invoice);

      // Convert and save each selected MenuItem as an InvoiceItem
      for (MenuItem menuItem in invoiceItems) {
        InvoiceItem invoiceItem = InvoiceItem(
          id: generateRandomTimestamp(),
          invoiceId: invoice.id.toString(), // Link to the invoice
          itemName: menuItem.itemName, // Name of the item
          price: menuItem.price, // Price of the item
          quantity: menuItem.quantity,
          total: menuItem.price+menuItem.quantity, // Quantity of the item
        );
        invoiceProvider.addInvoiceItem(invoiceItem);
      }

      debugPrint('Invoice and items saved successfully.');
    } catch (e) {
      debugPrint('Error saving invoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save the invoice.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _updateQty() {
    setState(() {
      qty = invoiceItems.fold(0, (sum, item) => sum + item.quantity);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuProvider =
          Provider.of<MenuItemsProvider>(context, listen: false);
      menuProvider.loadMenuItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    bool isScreenBigger = size.width > 1000;
    bool isScreenSmaller = size.width <= 1000;
    final menuProvider = Provider.of<MenuItemsProvider>(context);
    final filteredMenuItems = menuProvider.menuItems
        .where((menuItem) =>
            menuItem.itemName.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
    List<InvoiceItem> invoiceItemList = invoiceItems.map((menuItem) {
      return InvoiceItem(
        id: menuItem.id,
        price: menuItem.price,
        quantity: menuItem.quantity,
        invoiceId: '',
        itemName: menuItem.itemName,
        total: menuItem.price * menuItem.quantity,
      );
    }).toList();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: !Responsive.isTablet(context) && !Responsive.isDesktop(context)
          ? AppBar(
              title: Text('Dashboard'),
              actions: [
                InkWell(
                  onTap: () {
                    _openBottomSheet(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: badges.Badge(
                      onTap: () {
                        _openBottomSheet(context);
                      },
                      showBadge: true,
                      badgeContent: Text('${qty}'),

                      child: Container(
                        child: Icon(Icons.shopping_cart, size: 50),
                      ),
                      // Empty container to overlay the badge on the image
                    ),
                  ),
                )
              ],
            )
          : null, // No AppBar for larger screens
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    // autofocus: true,
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
                  child: MenuScreen(
                      invoiceItems: invoiceItemList,
                      filteredMenuItems: filteredMenuItems,
                      addMenuItem: _addMenuItem,
                      removeMenuItem: _removeMenuItem,
                      removeItem: _removeItem),
                ),
              ],
            ),
          ),
          if (!Responsive.isMobile(context))
            // Second row: Invoice table
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2), // Shadow color
                          blurRadius: 6, // How much the shadow is blurred
                          offset: Offset(-4,
                              0), // Shadow only on the left (negative X offset)
                        ),
                      ],
                    ),
                    child: StreamBuilder<Object>(
                        stream: null,
                        builder: (context, snapshot) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SingleChildScrollView(
                                child: Card(
                                  color: Colors.white,
                                  margin: EdgeInsets.symmetric(vertical: 1.0),
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color: secondaryColor, // Border color
                                      // Border width
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(
                                          15), // Radius for the top-left corner
                                      topRight: Radius.circular(
                                          15), // Radius for the top-right corner
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Invoice Header
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Text(
                                                "NAAZ RESTAURANT",
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.brown,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "Lilong Bazar - 795135",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Divider(
                                        thickness: 2,
                                        color: Colors.grey[400],
                                      ),
                                      // Invoice to Details
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Invoice To:",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  "Name: ${widget.name}",
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87),
                                                ),
                                                Text(
                                                  "Phone: ${widget.phone}",
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87),
                                                ),
                                                Text(
                                                  "Address: ${widget.address}",
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              " Invoice Number: ${generateInvoiceNumber()}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              "Date: ${DateTime.now().toString().split(' ')[0]}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Divider Line
                                      Divider(
                                        thickness: 2,
                                        color: Colors.grey[400],
                                      ),

                                      // Invoice Number and Date
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Text(
                                          "Item List",
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14),
                                        ),
                                      ),
                                      // Invoice Items
                                      Padding(
                                        padding: const EdgeInsets.all(
                                            defaultPadding),
                                        child: invoiceItems.isNotEmpty
                                            ? Column(
                                                children: invoiceItems
                                                    .asMap()
                                                    .entries
                                                    .map((entry) {
                                                  int index = entry
                                                      .key; // Get the index
                                                  var item = entry
                                                      .value; // Get the item

                                                  return Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              "(${index + 1}) ${item.itemName} - ${item.unitType}",
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                            ),
                                                            Text(
                                                              "₹${item.price.toStringAsFixed(2)} x Qty ${item.quantity}",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .black),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Text(
                                                        "₹ ${(item.price * item.quantity).toStringAsFixed(2)}",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }).toList(),
                                              )
                                            : Center(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 80, bottom: 80),
                                                  child: Text(
                                                    "No Items Added",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                      ),
                                      Divider(
                                        thickness: 1,
                                        color: Colors.black,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Subtotal",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  "₹ ${subtotal.toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Discount",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  "(-)    ${discount.toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Tax",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  "₹ ${taxAmount.toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Balance/Due",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  "₹ ${(total - amountPaid).toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Divider(
                                        thickness: 5,
                                        color: Colors.white,
                                      ),
                                      Center(
                                        child: Text(
                                          "Tank You, Visit Again",
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Divider(
                                        thickness: 10,
                                        color: Colors.white,
                                      ),
                                      // Paper Cut Design
                                      ClipPath(
                                        clipper: PaperCutClipper(),
                                        child: Container(
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: secondaryColor,
                                            border: Border.all(
                                              color:
                                                  secondaryColor, // Border color
                                              width: 1, // Border width
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "",
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Center(
                                child: invoiceItems.isEmpty
                                    ? null
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize
                                            .min, // Avoid unnecessary height
                                        children: [
                                          // Subtotal Section
                                          ListTile(
                                            title: Text('Subtotal',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            trailing: Text(
                                                '₹${subtotal.toStringAsFixed(2)}'),
                                          ),
                                          // Discount Input
                                          ListTile(
                                            title: TextField(
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                fillColor: secondary2Color,
                                                filled: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16),
                                                border:
                                                    const OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(10)),
                                                  borderSide: BorderSide.none,
                                                ),
                                                labelText: 'Discount (₹)',
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  discount =
                                                      double.tryParse(value) ??
                                                          0.0;
                                                  _calculateTotals();
                                                });
                                              },
                                            ),
                                            trailing: Text(
                                                'After Dis: ₹${afterDiscount.toStringAsFixed(2)}'),
                                          ),
                                          // Tax Rate Input
                                          ListTile(
                                            title: TextField(
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                fillColor: secondary2Color,
                                                filled: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 16),
                                                border:
                                                    const OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(10)),
                                                  borderSide: BorderSide.none,
                                                ),
                                                labelText: 'Tax Rate (%)',
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  taxRate =
                                                      double.tryParse(value) ??
                                                          0.0;
                                                  _calculateTotals();
                                                });
                                              },
                                            ),
                                            trailing: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                    'Tax Amt: ₹${taxAmount.toStringAsFixed(2)}'),
                                                Text(
                                                  'After Tax: ₹${total.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: Colors.greenAccent,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Paid Amount Input
                                          ListTile(
                                            title: Form(
                                              key: _formKey,
                                              child: TextFormField(
                                                validator: (value) {
                                                  if (value!.isNotEmpty &&
                                                      (value == null ||
                                                          value.isEmpty)) {
                                                    return 'Please enter Paid AMount';
                                                  }

                                                  return null;
                                                },
                                                keyboardType:
                                                    TextInputType.number,
                                                textAlign: TextAlign.center,
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  fillColor: secondary2Color,
                                                  filled: true,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          vertical: 16),
                                                  border:
                                                      const OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                10)),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  labelText: 'Paid Amt',
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    amountPaid =
                                                        double.tryParse(
                                                                value) ??
                                                            0.0;
                                                    _calculateTotals();
                                                  });
                                                },
                                              ),
                                            ),
                                            trailing: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                const Text('Due Amt',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(
                                                  '₹${(total - amountPaid).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: Colors.redAccent,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Payment Type Selection
                                          const SizedBox(height: 10),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                left: 20.0),
                                            child: Text('Payment Type:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment
                                                .spaceEvenly, // Spread the icons evenly
                                            children: [
                                              Column(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons
                                                          .attach_money, // Icon for Cash
                                                      color:
                                                          selectedPaymentType ==
                                                                  'Cash'
                                                              ? primaryColor
                                                              : Colors.grey,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        selectedPaymentType =
                                                            'Cash';
                                                      });
                                                    },
                                                    tooltip:
                                                        'Cash', // Tooltip for accessibility
                                                  ),
                                                  Text(
                                                    'CASH',
                                                    style: TextStyle(
                                                      color:
                                                          selectedPaymentType ==
                                                                  'Cash'
                                                              ? primaryColor
                                                              : Colors.grey,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons
                                                          .qr_code, // Icon for UPI
                                                      color:
                                                          selectedPaymentType ==
                                                                  'UPI'
                                                              ? primaryColor
                                                              : Colors.grey,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        selectedPaymentType =
                                                            'UPI';
                                                      });
                                                    },
                                                    tooltip:
                                                        'UPI', // Tooltip for accessibility
                                                  ),
                                                  Text(
                                                    'UPI',
                                                    style: TextStyle(
                                                      color:
                                                          selectedPaymentType ==
                                                                  'UPI'
                                                              ? primaryColor
                                                              : Colors.grey,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons
                                                          .schedule, // Icon for Due
                                                      color:
                                                          selectedPaymentType ==
                                                                  'Due'
                                                              ? primaryColor
                                                              : Colors.grey,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        selectedPaymentType =
                                                            'Due';
                                                      });
                                                    },
                                                    tooltip:
                                                        'Due', // Tooltip for accessibility
                                                  ),
                                                  Text(
                                                    'DUE',
                                                    style: TextStyle(
                                                      color:
                                                          selectedPaymentType ==
                                                                  'Due'
                                                              ? primaryColor
                                                              : Colors.grey,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          SizedBox(
                                            height: 100,
                                          )
                                        ],
                                      ),
                              ),
                            ],
                          );
                        }),
                  ),
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _submitOrder(
                subtotal: subtotal,
                discount: discount,
                tax: taxAmount,
                balance: total - amountPaid,
                invoiceItems: invoiceItems,
                name: widget.name,
                address: widget.address,
                phone: widget.phone);
            showDialog(
              context: context,
              builder: (context) => PrinterSettingsDialog(
                amountPaid: amountPaid,
                subtotal: subtotal,
                discount: discount,
                tax: taxAmount,
                balance: total - amountPaid,
                invoiceItems: invoiceItems,
                name: widget.name,
                address: widget.address,
                phone: widget.phone,
              ),
            ).then((_) => setState(() {}));
          }
        },

        child: Icon(Icons.save), // Use an icon, like a save icon
        backgroundColor: Colors.blue, // Optional: Customize color
        tooltip: 'Save',
      ),
    );
  }

  // Function to show the bottom sheet
  void _openBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      scrollControlDisabledMaxHeightRatio: 10,
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          // height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: secondaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2), // Shadow color
                      blurRadius: 6, // How much the shadow is blurred
                      offset: Offset(
                          -4, 0), // Shadow only on the left (negative X offset)
                    ),
                  ],
                ),
                child: StreamBuilder<Object>(
                    stream: null,
                    builder: (context, snapshot) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SingleChildScrollView(
                            child: Card(
                              color: Colors.white,
                              margin: EdgeInsets.symmetric(vertical: 1.0),
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: secondaryColor, // Border color
                                  // Border width
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(
                                      15), // Radius for the top-left corner
                                  topRight: Radius.circular(
                                      15), // Radius for the top-right corner
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Invoice Header
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Text(
                                            "NAAZ RESTAURANT",
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.brown,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "Lilong Bazar - 795135",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Divider(
                                    thickness: 2,
                                    color: Colors.grey[400],
                                  ),
                                  // Invoice to Details
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Invoice To:",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              "Name: ${widget.name}",
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87),
                                            ),
                                            Text(
                                              "Phone: ${widget.phone}",
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87),
                                            ),
                                            Text(
                                              "Address: ${widget.address}",
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          " Invoice Number: ${generateInvoiceNumber()}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          "Date: ${DateTime.now().toString().split(' ')[0]}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Divider Line
                                  Divider(
                                    thickness: 2,
                                    color: Colors.grey[400],
                                  ),

                                  // Invoice Number and Date
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      "Item List",
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 14),
                                    ),
                                  ),
                                  // Invoice Items
                                  Padding(
                                    padding:
                                        const EdgeInsets.all(defaultPadding),
                                    child: invoiceItems.isNotEmpty
                                        ? Column(
                                            children: invoiceItems
                                                .asMap()
                                                .entries
                                                .map((entry) {
                                              int index =
                                                  entry.key; // Get the index
                                              var item =
                                                  entry.value; // Get the item

                                              return Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "(${index + 1}) ${item.itemName} - ${item.unitType}",
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        Text(
                                                          "₹${item.price.toStringAsFixed(2)} x Qty ${item.quantity}",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.black),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    "₹${(item.price * item.quantity).toStringAsFixed(2)}",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          )
                                        : Center(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 80, bottom: 80),
                                              child: Text(
                                                "No Items Added",
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),

                                  Divider(
                                    thickness: 5,
                                    color: Colors.white,
                                  ),
                                  Center(
                                    child: Text(
                                      "Tank You, Visit Again",
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Divider(
                                    thickness: 10,
                                    color: Colors.white,
                                  ),
                                  // Paper Cut Design
                                  ClipPath(
                                    clipper: PaperCutClipper(),
                                    child: Container(
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: secondaryColor,
                                        border: Border.all(
                                          color: secondaryColor, // Border color
                                          width: 1, // Border width
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "",
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
              ),
            ),
          ),
        );
      },
    );
  }
}
