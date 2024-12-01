import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:dinepos/pages/printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../model/invoice_items_model.dart';
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
  final _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuProvider =
          Provider.of<MenuItemsProvider>(context, listen: false);
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
      final existingIndex =
          invoiceItems.indexWhere((item) => item.id == menuItem.id);
      if (existingIndex == -1) {
        invoiceItems.add(
          MenuItem(
            name: menuItem.name,
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


  Future<void> _submitOrder() async {
    // InvoiceProvider.addInvoice(invoiceItems);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Don\'t forget to collect payment.'),
        duration: Duration(seconds: 2),
      ),
    );
    // Save invoice logic here
  }

  int qty = 0; // Quantity of items
  void _updateQty() {
    setState(() {
      qty = invoiceItems.fold(0, (sum, item) => sum + item.quantity);
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
            menuItem.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
    List<InvoiceItem> invoiceItemList = invoiceItems.map((menuItem) {
      return InvoiceItem(
        id: menuItem.id,
        price: menuItem.price,
        quantity: menuItem.quantity,
        invoiceId: '',
        itemName: menuItem.name,
        total: menuItem.price * menuItem.quantity,
      );
    }).toList();




    void _printInvoice() async {
      try {
        // Load the capability profile for the printer
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);

        // Initialize a list of bytes for the invoice data
        List<int> bytes = [];

        // Add restaurant name and address
        bytes += generator.text('NAAZ RESTAURANT',
            styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
        bytes += generator.text('Lilong Bazar - 795135', styles: PosStyles(align: PosAlign.center));
        bytes += generator.hr(); // Horizontal line

        // Add customer details
        bytes += generator.text('Invoice To:', styles: PosStyles(bold: true));
        bytes += generator.text('Name: ${widget.name}');
        bytes += generator.text('Phone: ${widget.phone.isNotEmpty ? widget.phone : 'N/A'}');
        bytes += generator.text('Address: ${widget.address}');
        bytes += generator.hr();

        // Add item list
        bytes += generator.text('Item List:', styles: PosStyles(bold: true));
        for (var item in invoiceItems) {
          bytes += generator.text(
              '${item.name.padRight(20)} ₹${item.price.toStringAsFixed(2).padLeft(10)} x ${item.quantity.toString().padLeft(3)}');
          bytes += generator.text(
              'Total: ₹${(item.price * item.quantity).toStringAsFixed(2).padLeft(10)}');
        }
        bytes += generator.hr();

        // Add a thank you message
        bytes += generator.text('Thank You, Visit Again!',
            styles: PosStyles(align: PosAlign.center, bold: true));

        // Cut the paper after printing
        bytes += generator.cut();

        // Wait for the printer list to load
        await FlutterThermalPrinter.instance.getPrinters();  // Initiates the search for printers

        // Listen to the devices stream to get the list of printers
        FlutterThermalPrinter.instance.devicesStream.listen((printers) async {
          // Find the printer with the name 'Everycom-58-Series'
          Printer everycomPrinter = printers.firstWhere(
                (printer) => printer.name == 'Everycom-58-Series',
            orElse: () => throw Exception("Everycom-58-Series printer not found"),
          );

          // Check if the printer is connected
          if (everycomPrinter.isConnected ?? false) {
            // Send the invoice data to the printer
            await FlutterThermalPrinter.instance.printData(everycomPrinter, bytes);
            print("Invoice sent to printer");
          } else {
            // If the printer is not connected, try to connect it
            final isConnected = await FlutterThermalPrinter.instance.connect(everycomPrinter);
            if (isConnected) {
              // Send the data once connected
              await FlutterThermalPrinter.instance.printData(everycomPrinter, bytes);
              print("Invoice sent to printer");
            } else {
              print("Failed to connect to the printer");
            }
          }
        });

      } catch (e) {
        // Handle any errors
        print("Error: $e");
      }
    }

    return Scaffold(
    resizeToAvoidBottomInset: false,
      appBar: !Responsive.isTablet(context) && !Responsive.isDesktop(context)
          ? AppBar(
              title: Text('Dashboard'),
              actions: [
                InkWell(
                  onTap: (){
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
                            child: Icon(Icons.shopping_cart,size: 50),
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
                      removeItem: _removeItem
                  ),
                ),
              ],
            ),
          ),
          if (!Responsive.isMobile(context))
            // Second row: Invoice table
            Expanded(
              flex: 1,
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
                                          if (isScreenBigger)
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  "Invoice Number: ${generateInvoiceNumber()}",
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
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isScreenSmaller)
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
                                                            "(${index + 1}) ${item.name} - ${item.unitType}",
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color:
                                                                  Colors.black,
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
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: ElevatedButton.icon(
                                        onPressed: (){
                                          _printInvoice();
                                            },
                                        icon: Icon(Icons.print),
                                        label: Text("Print Invoice"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Expanded(
                            //   child: Padding(
                            //     padding: const EdgeInsets.all(16.0),
                            //     child: LayoutBuilder(
                            //       builder: (context, constraints) {
                            //         final isWideScreen = constraints.maxWidth > 800; // Adjust threshold as needed
                            //         return Row(
                            //           mainAxisAlignment: MainAxisAlignment.center, // Center the card on small screens
                            //           children: [
                            //             Expanded(
                            //               flex: 1, // Take full width on smaller screens
                            //               child: Card(
                            //                 elevation: 5,
                            //                 child: Container(
                            //                   width: isWideScreen ? 450 : double.infinity, // Adjust width for smaller screens
                            //                   padding: const EdgeInsets.all(8.0),
                            //                   decoration: BoxDecoration(
                            //                     border: Border.all(color: Colors.blueGrey),
                            //                     borderRadius: BorderRadius.circular(8),
                            //                   ),
                            //                   child: Column(
                            //                     crossAxisAlignment: CrossAxisAlignment.start,
                            //                     children: [
                            //                       ListTile(
                            //                         title: Text('Subtotal'),
                            //                         trailing: Text('₹${subtotal.toStringAsFixed(2)}'),
                            //                       ),
                            //                       ListTile(
                            //                         title: TextField(
                            //                           keyboardType: TextInputType.number,
                            //                           textAlign: TextAlign.center,
                            //                           decoration: InputDecoration(
                            //                             isDense: true,
                            //                             fillColor: secondary2Color,
                            //                             filled: true,
                            //                             contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            //                             border: const OutlineInputBorder(
                            //                               borderRadius: BorderRadius.all(Radius.circular(10)),
                            //                               borderSide: BorderSide.none,
                            //                             ),
                            //                             labelText: 'Discount (₹)',
                            //                           ),
                            //                           onChanged: (value) {
                            //                             setState(() {
                            //                               discount = double.tryParse(value) ?? 0.0;
                            //                               _calculateTotals();
                            //                             });
                            //                           },
                            //                         ),
                            //                         trailing: Text('After Dis: ₹${afterDiscount.toStringAsFixed(2)}'),
                            //                       ),
                            //                       ListTile(
                            //                         title: TextField(
                            //                           keyboardType: TextInputType.number,
                            //                           textAlign: TextAlign.center,
                            //                           decoration: InputDecoration(
                            //                             isDense: true,
                            //                             fillColor: secondary2Color,
                            //                             filled: true,
                            //                             contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            //                             border: const OutlineInputBorder(
                            //                               borderRadius: BorderRadius.all(Radius.circular(10)),
                            //                               borderSide: BorderSide.none,
                            //                             ),
                            //                             labelText: 'Tax Rate (%)',
                            //                           ),
                            //                           onChanged: (value) {
                            //                             setState(() {
                            //                               taxRate = double.tryParse(value) ?? 0.0;
                            //                               _calculateTotals();
                            //                             });
                            //                           },
                            //                         ),
                            //                         trailing: Column(
                            //                           crossAxisAlignment: CrossAxisAlignment.end,
                            //                           children: [
                            //                             Text('Tax Amt: ₹${taxAmount.toStringAsFixed(2)}'),
                            //                             Text(
                            //                               'After Tax: ₹${total.toStringAsFixed(2)}',
                            //                               style: const TextStyle(
                            //                                 color: Colors.greenAccent,
                            //                                 fontSize: 13,
                            //                                 fontWeight: FontWeight.bold,
                            //                               ),
                            //                             ),
                            //                           ],
                            //                         ),
                            //                       ),
                            //                       ListTile(
                            //                         title: TextField(
                            //                           keyboardType: TextInputType.number,
                            //                           textAlign: TextAlign.center,
                            //                           decoration: InputDecoration(
                            //                             isDense: true,
                            //                             fillColor: secondary2Color,
                            //                             filled: true,
                            //                             contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            //                             border: const OutlineInputBorder(
                            //                               borderRadius: BorderRadius.all(Radius.circular(10)),
                            //                               borderSide: BorderSide.none,
                            //                             ),
                            //                             labelText: 'Paid Amt',
                            //                           ),
                            //                           onChanged: (value) {
                            //                             setState(() {
                            //                               amountPaid = double.tryParse(value) ?? 0.0;
                            //                               _calculateTotals();
                            //                             });
                            //                           },
                            //                         ),
                            //                         trailing: Column(
                            //                           crossAxisAlignment: CrossAxisAlignment.end,
                            //                           children: [
                            //                             const Text('Due Amt', style: TextStyle(fontWeight: FontWeight.bold)),
                            //                             Text(
                            //                               '₹${(total - amountPaid).toStringAsFixed(2)}',
                            //                               style: const TextStyle(
                            //                                 color: Colors.redAccent,
                            //                                 fontSize: 20,
                            //                                 fontWeight: FontWeight.bold,
                            //                               ),
                            //                             ),
                            //                           ],
                            //                         ),
                            //                       ),
                            //                       const SizedBox(height: 10),
                            //                       const Text(
                            //                         'Payment Type:',
                            //                         style: TextStyle(fontWeight: FontWeight.bold),
                            //                       ),
                            //                       Row(
                            //                         mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Spread the icons evenly
                            //                         children: [
                            //                           Column(
                            //                             children: [
                            //                               IconButton(
                            //                                 icon: Icon(
                            //                                   Icons.attach_money, // Icon for Cash
                            //                                   color: selectedPaymentType == 'Cash' ? primaryColor : Colors.grey,
                            //                                 ),
                            //                                 onPressed: () {
                            //                                   setState(() {
                            //                                     selectedPaymentType = 'Cash';
                            //                                   });
                            //                                 },
                            //                                 tooltip: 'Cash', // Tooltip for accessibility
                            //                               ),
                            //                               Text(
                            //                                 'CASH',
                            //                                 style: TextStyle(
                            //                                   color: selectedPaymentType == 'Cash' ? primaryColor : Colors.grey,
                            //                                   fontWeight: FontWeight.bold,
                            //                                 ),
                            //                               ),
                            //                             ],
                            //                           ),
                            //                           Column(
                            //                             children: [
                            //                               IconButton(
                            //                                 icon: Icon(
                            //                                   Icons.qr_code, // Icon for UPI
                            //                                   color: selectedPaymentType == 'UPI' ? primaryColor : Colors.grey,
                            //                                 ),
                            //                                 onPressed: () {
                            //                                   setState(() {
                            //                                     selectedPaymentType = 'UPI';
                            //                                   });
                            //                                 },
                            //                                 tooltip: 'UPI', // Tooltip for accessibility
                            //                               ),
                            //                               Text(
                            //                                 'UPI',
                            //                                 style: TextStyle(
                            //                                   color: selectedPaymentType == 'UPI' ? primaryColor : Colors.grey,
                            //                                   fontWeight: FontWeight.bold,
                            //                                 ),
                            //                               ),
                            //                             ],
                            //                           ),
                            //                           Column(
                            //                             children: [
                            //                               IconButton(
                            //                                 icon: Icon(
                            //                                   Icons.schedule, // Icon for Due
                            //                                   color: selectedPaymentType == 'Due' ? primaryColor : Colors.grey,
                            //                                 ),
                            //                                 onPressed: () {
                            //                                   setState(() {
                            //                                     selectedPaymentType = 'Due';
                            //                                   });
                            //                                 },
                            //                                 tooltip: 'Due', // Tooltip for accessibility
                            //                               ),
                            //                               Text(
                            //                                 'DUE',
                            //                                 style: TextStyle(
                            //                                   color: selectedPaymentType == 'Due' ? primaryColor : Colors.grey,
                            //                                   fontWeight: FontWeight.bold,
                            //                                 ),
                            //                               ),
                            //                             ],
                            //                           ),
                            //                         ],
                            //                       )
                            //
                            //
                            //                     ],
                            //                   ),
                            //                 ),
                            //               ),
                            //             ),
                            //           ],
                            //         );
                            //       },
                            //     ),
                            //   ),
                            // ),
                          ],
                        );
                      }),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: invoiceItems.isEmpty
          ? null
          : FloatingActionButton.extended(
              elevation: 10,
              onPressed: () {
                // Show the confirmation alert dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    final isWideScreen = MediaQuery.of(context).size.width >
                        800; // Check screen width
                    return AlertDialog(
                      title: Text('Save Invoice'),
                      content: SingleChildScrollView(
                        // Add scroll for long content
                        child: Center(
                          child: SizedBox(
                            width: isWideScreen
                                ? 450
                                : MediaQuery.of(context).size.width *
                                    0.9, // Responsive width
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize:
                                  MainAxisSize.min, // Avoid unnecessary height
                              children: [
                                // Subtotal Section
                                ListTile(
                                  title: Text('Subtotal'),
                                  trailing:
                                      Text('₹${subtotal.toStringAsFixed(2)}'),
                                ),
                                // Discount Input
                                ListTile(
                                  title: TextField(
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      fillColor: secondary2Color,
                                      filled: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 16),
                                      border: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)),
                                        borderSide: BorderSide.none,
                                      ),
                                      labelText: 'Discount (₹)',
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        discount =
                                            double.tryParse(value) ?? 0.0;
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
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      fillColor: secondary2Color,
                                      filled: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 16),
                                      border: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)),
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
                                  title: TextField(
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      fillColor: secondary2Color,
                                      filled: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 16),
                                      border: const OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)),
                                        borderSide: BorderSide.none,
                                      ),
                                      labelText: 'Paid Amt',
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        amountPaid =
                                            double.tryParse(value) ?? 0.0;
                                        _calculateTotals();
                                      });
                                    },
                                  ),
                                  trailing: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Due Amt',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
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
                                Text('Payment Type:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceEvenly, // Spread the icons evenly
                                  children: [
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.attach_money, // Icon for Cash
                                            color: selectedPaymentType == 'Cash'
                                                ? primaryColor
                                                : Colors.grey,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              selectedPaymentType = 'Cash';
                                            });
                                          },
                                          tooltip:
                                              'Cash', // Tooltip for accessibility
                                        ),
                                        Text(
                                          'CASH',
                                          style: TextStyle(
                                            color: selectedPaymentType == 'Cash'
                                                ? primaryColor
                                                : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.qr_code, // Icon for UPI
                                            color: selectedPaymentType == 'UPI'
                                                ? primaryColor
                                                : Colors.grey,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              selectedPaymentType = 'UPI';
                                            });
                                          },
                                          tooltip:
                                              'UPI', // Tooltip for accessibility
                                        ),
                                        Text(
                                          'UPI',
                                          style: TextStyle(
                                            color: selectedPaymentType == 'UPI'
                                                ? primaryColor
                                                : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.schedule, // Icon for Due
                                            color: selectedPaymentType == 'Due'
                                                ? primaryColor
                                                : Colors.grey,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              selectedPaymentType = 'Due';
                                            });
                                          },
                                          tooltip:
                                              'Due', // Tooltip for accessibility
                                        ),
                                        Text(
                                          'DUE',
                                          style: TextStyle(
                                            color: selectedPaymentType == 'Due'
                                                ? primaryColor
                                                : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            // Close the dialog
                            Navigator.of(context).pop();
                          },
                          child: Text('Cancel',
                              style: TextStyle(color: Colors.red)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Call the function to save the invoice
                            _submitOrder();
                            // Close the dialog
                            Navigator.of(context).pop();
                          },
                          child: Text('Save'),
                        ),
                      ],
                    );
                  },
                );
              },
              label: Text('Save Invoice'),
              icon: Icon(Icons.save),
              backgroundColor: primaryColor,
              tooltip: 'Save invoice to database',
            ),
    );
  }
  // Function to show the bottom sheet
  void _openBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible:true,
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
                                                    "(${index + 1}) ${item.name} - ${item.unitType}",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                      FontWeight
                                                          .w500,
                                                      color:
                                                      Colors.black,
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

