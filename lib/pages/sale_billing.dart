import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../model/invoice_model.dart';
import '../provider/InvoiceProvider.dart';
import '../utils/const.dart';
import '../utils/responsive.dart';
import '../widget/add_customer_dialog.dart';
import '../widget/add_items.dart';
import '../widget/papercut_design.dart';
import '../widget/printer_settings-dialog.dart';

class SaleBilling extends StatefulWidget {
  const SaleBilling({super.key});

  @override
  _SaleBillingState createState() => _SaleBillingState();
}

class _SaleBillingState extends State<SaleBilling> {
  String searchQuery = '';
  String paymentMethod = 'Cash'; // Default payment method

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final invoiceProvider =
          Provider.of<InvoiceProvider>(context, listen: false);
      invoiceProvider.loadInvoices(); // Initialize Hive boxes asynchronously
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
              color: secondaryColor, borderRadius: BorderRadius.circular(10)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // Title on the left, button on the right
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title on the left
                      Text(
                        "Invoice List",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),

                      // Button on the right
                      ElevatedButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: defaultPadding * 1.5,
                            vertical: defaultPadding /
                                (Responsive.isMobile(context) ? 2 : 1),
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddCustomer(),
                          ).then(
                              (_) => setState(() {})); // Refresh after adding
                        },
                        icon: Icon(Icons.add_shopping_cart),
                        label: Text("Sale Invoice"),
                      ),
                    ],
                  ),
                  SizedBox(
                      height:
                          defaultPadding), // Add spacing between the title row and the content
                  Consumer<InvoiceProvider>(
                    builder: (context, menuProvider, _) {
                      final menuItems = menuProvider.invoices.where((item) {
                        final itemName = item.name.toLowerCase();
                        return itemName.contains(searchQuery.toLowerCase());
                      }).toList();

                      if (menuItems.isEmpty) {
                        return Center(child: Text("No menu items available"));
                      }

                      return SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          columnSpacing: defaultPadding,
                          columns: [
                            DataColumn(label: Text("Date")),
                            DataColumn(label: Text("Name")),
                            DataColumn(label: Text("Payment")),
                            DataColumn(label: Text("Paid")),
                            DataColumn(label: Text("Total")),
                            DataColumn(label: Text("Due")),
                            DataColumn(label: Text("Actions")),
                          ],
                          rows: List.generate(
                            menuItems.length,
                            (index) => invoiceDataRow(
                                menuItems[index], index, menuProvider, context),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Create DataRow for each invoice
  DataRow invoiceDataRow(Invoice invoice, int index,
      InvoiceProvider invoiceProvider, BuildContext context) {
    return DataRow(
      cells: [
        DataCell(
            Text(DateFormat('yyyy-MM-dd').format(invoice.createdAt.toLocal()))),
        DataCell(Column(
          children: [Text(invoice.name), Text(invoice.phone)],
        )),
        DataCell(Text(invoice.paymentType)),
        DataCell(Text("₹ ${invoice.amountPaid}")),
        DataCell(
            Text("₹ ${invoice.subtotal + invoice.taxRate - invoice.discount}")),
        DataCell(
          invoice.subtotal +
                      invoice.taxRate -
                      invoice.discount -
                      invoice.amountPaid ==
                  0
              ? Text(
                  'Paid',
                  style: TextStyle(color: Colors.green),
                )
              : Row(
                  children: [
                    Text(
                      "₹ ${invoice.subtotal + invoice.taxRate - invoice.discount - invoice.amountPaid}",
                      style: TextStyle(color: Colors.red),
                    ),
                    IconButton(
                      icon: Icon(Icons.payment, color: Colors.blue),
                      onPressed: () {
                        // Open the dialog to pay now
                        _showPaymentSelectionCard(context,invoice.subtotal + invoice.taxRate - invoice.discount - invoice.amountPaid);
                      },
                    ),
                  ],
                ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.print, color: Colors.white),
                onPressed: () {
                  final provider = Provider.of<InvoiceProvider>(context, listen: false);
                  _showInvoiceDialog(context, invoice, provider);
                },
              ),
              IconButton(
                icon: Icon(Icons.receipt, color: Colors.white),
                onPressed: () {
                  final provider = Provider.of<InvoiceProvider>(context, listen: false);
                  _showInvoiceDialog(context, invoice, provider);
                },
              ),
              IconButton(
                icon: Icon(Icons.edit, color: primary2Color),
                onPressed: () {
                  // Show Edit Invoice Dialog
                  // showDialog(
                  //   context: context,
                  //   builder: (context) => EditInvoiceDialog(invoice: invoice),
                  // ).then((_) => setState(() {})); // Refresh after editing
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  invoiceProvider
                      .deleteInvoice(invoice.id); // Delete the invoice
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  void _showPaymentSelectionCard(BuildContext context, double dueamt) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String contentText = "Content of Dialog";
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: secondaryColor,
              title: Text("Pay Now", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Do you want to pay the outstanding amount?',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    // Custom card with radio buttons for Cash/UPI selection
                    Card(
                      color: secondary2Color,
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            if (paymentMethod == 'UPI')
                              SizedBox(
                                width: 150,
                                height: 150,
                                child: QrImageView(
                                  data: 'upi://pay?pa=9233784045@okbizaxis&am=$dueamt&pn=PRINTONEX&mc=7622&aid=uGICAgMDC1pr1fQ&ver=01&mode=01&tr=BCR2DN4T7L6LRW2G',
                                  version: QrVersions.auto,
backgroundColor: Colors.white,
size: 150,
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildPaymentMethodOption(
                                  icon: Icons.attach_money,
                                  label: 'Cash',
                                  value: 'Cash',
                                  setState: setState,
                                ),
                                _buildPaymentMethodOption(
                                  icon: Icons.qr_code,
                                  label: 'UPI',
                                  value: 'UPI',
                                  setState: setState,
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
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () {
                    // Handle the payment logic here
                    print("Payment Method: $paymentMethod");
                    Navigator.of(context).pop();
                  },
                  child: Text("Pay", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Build the payment method selection option (Cash or UPI)
  Widget _buildPaymentMethodOption({
    required IconData icon,
    required String label,
    required String value,
    required void Function(void Function()) setState,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: paymentMethod == value ? primaryColor : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              paymentMethod = value; // Update payment method on press
            });
          },
          tooltip: label,
        ),
        Text(
          label,
          style: TextStyle(
            color: paymentMethod == value ? primaryColor : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showInvoiceDialog(BuildContext context, Invoice invoice, InvoiceProvider provider) {
    final items = provider.getItemsForInvoice(invoice.id); // Get items for this invoice

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: secondaryColor,
          title: Text(
            "Invoice Details",
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Card(
              color: Colors.white,
              margin: EdgeInsets.symmetric(vertical: 1.0),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: secondaryColor,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [


                  // Invoice Information
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Invoice ID: ${invoice.id}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Date: ${DateFormat('yyyy-MM-dd').format(invoice.createdAt.toLocal())}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "Name: ${invoice.name}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "Phone: ${invoice.phone}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "Payment Type: ${invoice.paymentType}",
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

                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      "Item List",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Divider(
                    thickness: 2,
                    color: Colors.grey[400],
                  ),
                  // Item List

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: items.isNotEmpty
                        ? Column(
                      children: items.map((item) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "${item.itemName} - Qty: ${item.quantity} x ₹${item.price}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Text(
                              "₹${(item.quantity * item.price).toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    )
                        : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
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
                    thickness: 1,
                    color: Colors.black,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SubTotal : ₹ ${(invoice.subtotal)}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "Discount : ₹ ${(invoice.discount)}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "Tax :  ${(invoice.taxRate / (invoice.subtotal - invoice.discount) * 100)}%",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "Paid : ₹ ${invoice.amountPaid}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),

                        Text(
                          "Due : ₹ ${(invoice.subtotal + invoice.taxRate - invoice.discount - invoice.amountPaid)}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: invoice.subtotal +
                                invoice.taxRate -
                                invoice.discount -
                                invoice.amountPaid ==
                                0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Footer
                  Center(
                    child: Text(
                      "Thank You, Visit Again!",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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

          actions: [

            TextButton(
              onPressed: () {
                // Gather the necessary values to pass to the PrinterSettingsDialog
                List<dynamic> invoiceItems = provider.getItemsForInvoice(invoice.id);
                String? customerName = invoice.name;             // Customer's name
                String? customerAddress = invoice.address;       // Customer's address
                String customerPhone = invoice.phone;            // Customer's phone number
                double invoiceSubtotal = invoice.subtotal;       // Invoice subtotal before discounts/taxes
                double invoiceDiscount = invoice.discount;       // Discount applied
                double invoiceTax = invoice.taxRate;             // Tax applied
                double remainingBalance = invoice.subtotal + invoice.taxRate - invoice.discount - invoice.amountPaid; // Balance due after payment
                double paidAmount = invoice.amountPaid;          // Amount already paid
                Get.back();
                // Show the PrinterSettingsDialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return PrinterSettingsDialog(
                      invoiceItems: invoiceItems,
                      name: customerName,
                      address: customerAddress,
                      phone: customerPhone,
                      subtotal: invoiceSubtotal,
                      discount: invoiceDiscount,
                      tax: invoiceTax,
                      balance: remainingBalance,
                      amountPaid: paidAmount,
                    );
                  },
                );
              },
              child: Text("Print", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

}
