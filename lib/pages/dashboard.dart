import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/invoice_model.dart';
import '../provider/InvoiceProvider.dart';
import '../utils/const.dart';
import '../utils/responsive.dart';
import '../widget/dashboard/recent_transactions.dart';
// Import the RecentTransactions widget
import '../widget/dashboard/storage_details.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);

    // Calculate Sales and Dues
    double todaySales = 0;
    double monthlySales = 0;
    double yearlySales = 0;
    double totalDue = 0;
    DateTime now = DateTime.now();

    for (var invoice in invoiceProvider.invoices) {
      DateTime invoiceDate = invoice.createdAt;
      double invoiceTotal = invoice.subtotal + invoice.taxRate - invoice.discount;
      double invoiceDue = invoiceTotal - invoice.amountPaid;

      if (invoiceDate.year == now.year) {
        yearlySales += invoiceTotal;

        if (invoiceDate.month == now.month) {
          monthlySales += invoiceTotal;

          if (invoiceDate.day == now.day) {
            todaySales += invoiceTotal;
          }
        }
      }

      if (invoiceDue > 0) {
        totalDue += invoiceDue;
      }
    }

    final Size _size = MediaQuery.of(context).size;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align to the start
                      children: [
                        Container(
                          // Ensure consistent height if needed
                          constraints: BoxConstraints(
                            minHeight: 150, // Adjust this value based on your needs
                          ),
                          child: Row(
                            children: [
                              _buildSummaryCard('Today Sales', todaySales),
                              _buildSummaryCard('Monthly Sales', monthlySales),
                              _buildSummaryCard('Yearly Sales', yearlySales),
                              _buildSummaryCard('Total Due', totalDue),
                            ],
                          ),
                        ),
                        SizedBox(height: defaultPadding),
                        // Call RecentTransactions here and pass invoices from the provider
                        RecentTransactions(invoices: invoiceProvider.invoices),
                        if (Responsive.isMobile(context)) SizedBox(height: defaultPadding),
                        if (Responsive.isMobile(context))
                          Container(
                            constraints: BoxConstraints(
                              minHeight: 150, // Ensure this is the same as MyFiles
                            ),
                            child: StorageDetails(),
                          ),
                      ],
                    ),
                  ),
                  if (!Responsive.isMobile(context))
                    SizedBox(width: defaultPadding),
                  if (!Responsive.isMobile(context))
                    Expanded(
                      flex: 2,
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: 150, // Match the height with MyFiles
                        ),
                        child: StorageDetails(),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: 200, // Adjusted for better layout
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '₹ ${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
