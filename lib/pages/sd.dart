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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Shrink-wrap the Column
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryCard('Today Sales', todaySales),
                  _buildSummaryCard('Monthly Sales', monthlySales),
                  _buildSummaryCard('Yearly Sales', yearlySales),
                  _buildSummaryCard('Total Due', totalDue),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200, // Provide a fixed height for the chart
                child: _buildCustomSalesChart(context, invoiceProvider.invoices),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300, // Provide a fixed height for the transactions list
                child: _buildRecentTransactions(invoiceProvider.invoices),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Summary Card Widget
  Widget _buildSummaryCard(String title, double amount) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        width: 120, // Adjusted for better layout
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

  // Custom Sales Chart Widget
  Widget _buildCustomSalesChart(BuildContext context, List<Invoice> invoices) {
    List<double> dailySales = [500, 1200, 800, 1500, 2000, 1700, 2200]; // Mock data
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text(
              'Sales Chart (Last 7 Days)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: CustomPaint(
                painter: SalesChartPainter(dailySales),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recent Transactions Widget
  Widget _buildRecentTransactions(List<Invoice> invoices) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: invoices.length > 5 ? 5 : invoices.length, // Show only 5 recent transactions
                itemBuilder: (context, index) {
                  final invoice = invoices[index];
                  return ListTile(
                    leading: const Icon(Icons.receipt),
                    title: Text('Invoice ID: ${invoice.id}'),
                    subtitle: Text('Date: ${invoice.createdAt}'),
                    trailing: Text('₹ ${invoice.subtotal.toStringAsFixed(2)}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
