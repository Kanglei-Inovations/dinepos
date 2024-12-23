import 'package:flutter/material.dart';
import 'package:dinepos/model/invoice_model.dart';
import 'package:intl/intl.dart';

import '../../utils/const.dart';  // Import Invoice model from the correct file

class RecentTransactions extends StatelessWidget {
  final List<Invoice> invoices;

  const RecentTransactions({
    Key? key,
    required this.invoices,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Transactions",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              columnSpacing: 16.0,
              columns: const [
                DataColumn(label: Text("Date")),
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Payment")),
                DataColumn(label: Text("Paid")),
                DataColumn(label: Text("Total")),
                DataColumn(label: Text("Due")),

              ],
              rows: List.generate(
                invoices.length > 5 ? 5 : invoices.length,
                    (index) => recentTransactionRow(invoices[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow recentTransactionRow(Invoice invoice) {
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

            ],
          ),
        ),

      ],
    );
  }
}
