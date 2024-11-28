import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
      invoiceProvider.loadInvoices(); // Initialize Hive boxes asynchronously
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(color: secondaryColor, borderRadius: BorderRadius.circular(10)),

          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Title on the left, button on the right
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title on the left
                      Text(
                        "Menu Items",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),

                      // Button on the right
                      ElevatedButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: defaultPadding * 1.5,
                            vertical: defaultPadding / (Responsive.isMobile(context) ? 2 : 1),
                          ),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddCustomer(),
                          ).then((_) => setState(() {})); // Refresh after adding
                        },
                        icon: Icon(Icons.add),
                        label: Text("Add Menu Item"),
                      ),
                    ],
                  ),
                  SizedBox(height: defaultPadding), // Add spacing between the title row and the content
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
                            DataColumn(label: Text("paymentType")),
                            DataColumn(label: Text("amountPaid")),
                            DataColumn(label: Text("Actions")),
                          ],
                          rows: List.generate(
                            menuItems.length,
                                (index) =>
                                    invoiceDataRow(menuItems[index], index, menuProvider, context),
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
  DataRow invoiceDataRow(Invoice invoice, int index, InvoiceProvider invoiceProvider, BuildContext context) {
    return DataRow(
      cells: [
        DataCell(Text(DateFormat('yyyy-MM-dd').format(invoice.createdAt.toLocal()))),
        DataCell(Column(
          children: [
            Text(invoice.name),Text(invoice.phone)
          ],
        )),

        DataCell(Text(invoice.paymentType)),
        DataCell(Text("\$${invoice.amountPaid}")),
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
                  invoiceProvider.deleteInvoice(invoice.id); // Delete the invoice

                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
