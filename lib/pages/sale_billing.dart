import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../model/invoice_model.dart';
import '../provider/InvoiceProvider.dart';
import '../utils/const.dart';
import '../utils/responsive.dart';
import '../widget/add_customer_dialog.dart';
import '../widget/add_items.dart';

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
                icon: Icon(Icons.edit, color: Colors.blue),
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
              backgroundColor: Colors.black,
              title: Text("Pay Now", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Do you want to pay the outstanding amount?',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  // Custom card with radio buttons for Cash/UPI selection
                  Card(
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
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
                          if (paymentMethod == 'UPI')
                            QrImageView(
                              data: 'upi://pay?pa=9233784045@okbizaxis&am=&pn=PRINTONEX&mc=7622&aid=uGICAgMDC1pr1fQ&ver=01&mode=01&tr=BCR2DN4T7L6LRW2G',
                              version: QrVersions.auto,
                              size: 200.0,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
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

}
