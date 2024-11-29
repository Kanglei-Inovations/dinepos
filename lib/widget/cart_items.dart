import 'package:dinepos/widget/papercut_design.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/invoice_items_model.dart';
import '../model/menuItem.dart';
import '../provider/menu_items.dart';
import '../utils/const.dart';

class CartItems extends StatefulWidget {
  final String phone;
  final String? name;
  final String? address;

  const CartItems(
      {super.key, required this.phone, this.name, this.address});

  @override
  State<CartItems> createState() => _CartItemsState();
}

class _CartItemsState extends State<CartItems> {
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuProvider =
      Provider.of<MenuItemsProvider>(context, listen: false);
      menuProvider.loadMenuItems();
    });
  }
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
    return Scaffold(
        appBar: AppBar(
        ),
      body: Expanded(
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
                                child: Column(
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
                              )
                            ],
                          ),
                        ),
                      ),

                      // Padding(
                      //   padding: const EdgeInsets.all(16.0),
                      //   child: LayoutBuilder(
                      //     builder: (context, constraints) {
                      //       final isWideScreen = constraints.maxWidth > 800; // Adjust threshold as needed
                      //       return Row(
                      //         mainAxisAlignment: MainAxisAlignment.center, // Center the card on small screens
                      //         children: [
                      //           Expanded(
                      //             flex: 1, // Take full width on smaller screens
                      //             child: Card(
                      //               elevation: 5,
                      //               child: Container(
                      //                 width: isWideScreen ? 450 : double.infinity, // Adjust width for smaller screens
                      //                 padding: const EdgeInsets.all(8.0),
                      //                 decoration: BoxDecoration(
                      //                   border: Border.all(color: Colors.blueGrey),
                      //                   borderRadius: BorderRadius.circular(8),
                      //                 ),
                      //                 child: Column(
                      //                   crossAxisAlignment: CrossAxisAlignment.start,
                      //                   children: [
                      //                     ListTile(
                      //                       title: Text('Subtotal'),
                      //                       trailing: Text('₹${subtotal.toStringAsFixed(2)}'),
                      //                     ),
                      //                     ListTile(
                      //                       title: TextField(
                      //                         keyboardType: TextInputType.number,
                      //                         textAlign: TextAlign.center,
                      //                         decoration: InputDecoration(
                      //                           isDense: true,
                      //                           fillColor: secondary2Color,
                      //                           filled: true,
                      //                           contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      //                           border: const OutlineInputBorder(
                      //                             borderRadius: BorderRadius.all(Radius.circular(10)),
                      //                             borderSide: BorderSide.none,
                      //                           ),
                      //                           labelText: 'Discount (₹)',
                      //                         ),
                      //                         onChanged: (value) {
                      //                           setState(() {
                      //                             discount = double.tryParse(value) ?? 0.0;
                      //                             _calculateTotals();
                      //                           });
                      //                         },
                      //                       ),
                      //                       trailing: Text('After Dis: ₹${afterDiscount.toStringAsFixed(2)}'),
                      //                     ),
                      //                     ListTile(
                      //                       title: TextField(
                      //                         keyboardType: TextInputType.number,
                      //                         textAlign: TextAlign.center,
                      //                         decoration: InputDecoration(
                      //                           isDense: true,
                      //                           fillColor: secondary2Color,
                      //                           filled: true,
                      //                           contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      //                           border: const OutlineInputBorder(
                      //                             borderRadius: BorderRadius.all(Radius.circular(10)),
                      //                             borderSide: BorderSide.none,
                      //                           ),
                      //                           labelText: 'Tax Rate (%)',
                      //                         ),
                      //                         onChanged: (value) {
                      //                           setState(() {
                      //                             taxRate = double.tryParse(value) ?? 0.0;
                      //                             _calculateTotals();
                      //                           });
                      //                         },
                      //                       ),
                      //                       trailing: Column(
                      //                         crossAxisAlignment: CrossAxisAlignment.end,
                      //                         children: [
                      //                           Text('Tax Amt: ₹${taxAmount.toStringAsFixed(2)}'),
                      //                           Text(
                      //                             'After Tax: ₹${total.toStringAsFixed(2)}',
                      //                             style: const TextStyle(
                      //                               color: Colors.greenAccent,
                      //                               fontSize: 13,
                      //                               fontWeight: FontWeight.bold,
                      //                             ),
                      //                           ),
                      //                         ],
                      //                       ),
                      //                     ),
                      //                     ListTile(
                      //                       title: TextField(
                      //                         keyboardType: TextInputType.number,
                      //                         textAlign: TextAlign.center,
                      //                         decoration: InputDecoration(
                      //                           isDense: true,
                      //                           fillColor: secondary2Color,
                      //                           filled: true,
                      //                           contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      //                           border: const OutlineInputBorder(
                      //                             borderRadius: BorderRadius.all(Radius.circular(10)),
                      //                             borderSide: BorderSide.none,
                      //                           ),
                      //                           labelText: 'Paid Amt',
                      //                         ),
                      //                         onChanged: (value) {
                      //                           setState(() {
                      //                             amountPaid = double.tryParse(value) ?? 0.0;
                      //                             _calculateTotals();
                      //                           });
                      //                         },
                      //                       ),
                      //                       trailing: Column(
                      //                         crossAxisAlignment: CrossAxisAlignment.end,
                      //                         children: [
                      //                           const Text('Due Amt', style: TextStyle(fontWeight: FontWeight.bold)),
                      //                           Text(
                      //                             '₹${(total - amountPaid).toStringAsFixed(2)}',
                      //                             style: const TextStyle(
                      //                               color: Colors.redAccent,
                      //                               fontSize: 20,
                      //                               fontWeight: FontWeight.bold,
                      //                             ),
                      //                           ),
                      //                         ],
                      //                       ),
                      //                     ),
                      //                     const SizedBox(height: 10),
                      //                     const Text(
                      //                       'Payment Type:',
                      //                       style: TextStyle(fontWeight: FontWeight.bold),
                      //                     ),
                      //                     Row(
                      //                       mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Spread the icons evenly
                      //                       children: [
                      //                         Column(
                      //                           children: [
                      //                             IconButton(
                      //                               icon: Icon(
                      //                                 Icons.attach_money, // Icon for Cash
                      //                                 color: selectedPaymentType == 'Cash' ? primaryColor : Colors.grey,
                      //                               ),
                      //                               onPressed: () {
                      //                                 setState(() {
                      //                                   selectedPaymentType = 'Cash';
                      //                                 });
                      //                               },
                      //                               tooltip: 'Cash', // Tooltip for accessibility
                      //                             ),
                      //                             Text(
                      //                               'CASH',
                      //                               style: TextStyle(
                      //                                 color: selectedPaymentType == 'Cash' ? primaryColor : Colors.grey,
                      //                                 fontWeight: FontWeight.bold,
                      //                               ),
                      //                             ),
                      //                           ],
                      //                         ),
                      //                         Column(
                      //                           children: [
                      //                             IconButton(
                      //                               icon: Icon(
                      //                                 Icons.qr_code, // Icon for UPI
                      //                                 color: selectedPaymentType == 'UPI' ? primaryColor : Colors.grey,
                      //                               ),
                      //                               onPressed: () {
                      //                                 setState(() {
                      //                                   selectedPaymentType = 'UPI';
                      //                                 });
                      //                               },
                      //                               tooltip: 'UPI', // Tooltip for accessibility
                      //                             ),
                      //                             Text(
                      //                               'UPI',
                      //                               style: TextStyle(
                      //                                 color: selectedPaymentType == 'UPI' ? primaryColor : Colors.grey,
                      //                                 fontWeight: FontWeight.bold,
                      //                               ),
                      //                             ),
                      //                           ],
                      //                         ),
                      //                         Column(
                      //                           children: [
                      //                             IconButton(
                      //                               icon: Icon(
                      //                                 Icons.schedule, // Icon for Due
                      //                                 color: selectedPaymentType == 'Due' ? primaryColor : Colors.grey,
                      //                               ),
                      //                               onPressed: () {
                      //                                 setState(() {
                      //                                   selectedPaymentType = 'Due';
                      //                                 });
                      //                               },
                      //                               tooltip: 'Due', // Tooltip for accessibility
                      //                             ),
                      //                             Text(
                      //                               'DUE',
                      //                               style: TextStyle(
                      //                                 color: selectedPaymentType == 'Due' ? primaryColor : Colors.grey,
                      //                                 fontWeight: FontWeight.bold,
                      //                               ),
                      //                             ),
                      //                           ],
                      //                         ),
                      //                       ],
                      //                     )
                      //
                      //
                      //                   ],
                      //                 ),
                      //               ),
                      //             ),
                      //           ),
                      //         ],
                      //       );
                      //     },
                      //   ),
                      // ),
                    ],
                  );
                }),
          ),
        ),
      ),

    );
  }
}
