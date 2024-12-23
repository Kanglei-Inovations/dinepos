import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:developer';
import '../utils/const.dart';


class PrinterSettingsDialog extends StatefulWidget {
  final List<dynamic> invoiceItems;
  final String? name;
  final String? address;
  final String phone;
  final double subtotal;
  final double discount;
  final double tax;
  final double balance;
  final double amountPaid;
  const PrinterSettingsDialog({
    required this.invoiceItems,
    this.name,
    this.address,
    required this.phone,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.balance, required this.amountPaid,
  });

  @override
  State<PrinterSettingsDialog> createState() => _PrinterSettingsDialogState();
}

class _PrinterSettingsDialogState extends State<PrinterSettingsDialog> {
  final _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;
  List<Printer> printers = [];
  StreamSubscription<List<Printer>>? _devicesStreamSubscription;

  @override
  void initState() {
    super.initState();
    startScan();
    // initializeBluetooth();
  }



  void startScan() async {
    try {
      _devicesStreamSubscription?.cancel();
      await _flutterThermalPrinterPlugin.getPrinters(connectionTypes: [
        ConnectionType.USB,ConnectionType.BLE
      ]);
      _devicesStreamSubscription = _flutterThermalPrinterPlugin.devicesStream
          .listen((List<Printer> event) {
        log(event.map((e) => e.name).toList().toString());
        setState(() {
          printers = event;
          printers.removeWhere((element) => element.name == null || element.name == ''
            //  ||
            // !element.name!.toLowerCase().contains('print')
          );
        });
      });
      Future.delayed(const Duration(seconds: 2), () {
        _devicesStreamSubscription?.cancel();
        _flutterThermalPrinterPlugin.stopScan();
        setState(() {
          stopScan();
        });

      });
    } catch (e) {
      print('Error during scan: $e');
    }



  }

  stopScan() {
    _devicesStreamSubscription?.cancel();
    _flutterThermalPrinterPlugin.stopScan();
  }

  void getUsbDevices() async {
    await _flutterThermalPrinterPlugin.getUsbDevices();
  }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                onPressed: () {
                  startScan();
                },
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 5,),
                    Text('Get Printers'),
                  ],
                ),
              ),
                SizedBox(width: 10,),
                ElevatedButton(
                  onPressed: () {
                    stopScan();
                  },
                  child: Row(
                    children: [
                      Icon(Icons.stop_circle_outlined),
                      SizedBox(width: 5,),
                      Text('Stop Scan'),
                    ],
                  ),
                ),],
            ),
            SizedBox(height: 10,),
            Divider(
              thickness: 2,
              color: primary2Color,
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: printers.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () async {
                      final profile = await CapabilityProfile.load();
                      final generator = Generator(PaperSize.mm58, profile);
                      List<int> bytes = [];
                      // Add restaurant name and address
                      bytes += generator.text('NAAZ RESTAURANT',
                          styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
                      bytes += generator.text('Lilong Bazar - 795135', styles: PosStyles(align: PosAlign.center));
                      bytes += generator.hr(); // Horizontal line
                      bytes += generator.text('Invoice To:', styles: PosStyles(bold: true));
                      bytes += generator.text('Name: ${widget.name}');
                      bytes += generator.text('Phone: ${widget.phone.isNotEmpty ? widget.phone : 'N/A'}');
                      bytes += generator.text('Address: ${widget.address}');
                      bytes += generator.hr();
                      bytes += generator.text('Item List:----------------------', styles: PosStyles(bold: true));
                      bytes += generator.text('Name------------RateXQty--Total', styles: PosStyles(bold: true));
                      // Iterate over the items in the invoice list
                      int serialNumber = 1;
                      for (var item in widget.invoiceItems) {
                        // Assuming each item is a map with keys: name, price, and quantity
                        bytes += generator.text(
                          '${serialNumber.toString()})  ${item.itemName }'.padRight(32) + // Item name padded to 20 characters
                              '${item.price.toStringAsFixed(2)}' + // Price padded to 8 characters
                              ' x ${item.quantity.toString()}' + // Quantity padded to 4 characters
                              ' =${(item.price * item.quantity).toStringAsFixed(2)}', // Total padded to 10 characters
                          styles: PosStyles(align: PosAlign.right, bold: true),
                        );
                        serialNumber++;
                      }
                      bytes += generator.hr();
                      // Subtotal
                      bytes += generator.text('Subtotal: Rs${widget.subtotal.toStringAsFixed(2)}',
                          styles: PosStyles(align: PosAlign.right));

// Discount
                      bytes += generator.text('Discount: Rs${widget.discount.toStringAsFixed(2)}',
                          styles: PosStyles(align: PosAlign.right));

// Tax "Tax :  ${(invoice.taxRate / (invoice.subtotal - invoice.discount) * 100)}%",
                      bytes += generator.text("Tax :  ${(widget.tax / (widget.subtotal - widget.discount) * 100)}%",
                          styles: PosStyles(align: PosAlign.right));

// Balance
                      print(widget.balance);
                      bytes += generator.text('Paid: Rs${widget.amountPaid.toStringAsFixed(2)}',
                          styles: PosStyles(align: PosAlign.right));

                        bytes += generator.text(
                          'Balance: Rs${widget.balance.toStringAsFixed(2)}',
                          styles: PosStyles(align: PosAlign.right),
                        );

                      bytes += generator.emptyLines(1);

                      bytes += generator.text('Thank You, Visit Again!',
                          styles: PosStyles(align: PosAlign.center, bold: true));
                      bytes += generator.drawer();
                      bytes += generator.cut();
                      await _flutterThermalPrinterPlugin.printData(
                        printers[index],
                        bytes,

                      );
                      Get.back();
                    },
                    title: Text(printers[index].name ?? 'No Name'),
                    subtitle: Text("Connected: ${printers[index].isConnected}"),
                    trailing: Icon(Icons.print),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: Text("Cancel"),
                ),
              ],
            ),
          ],
        ),
      ),

    );
  }
}
