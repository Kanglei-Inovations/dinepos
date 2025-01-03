import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:developer';
class SelectPrinterScreen extends StatefulWidget {
  final List<dynamic> invoiceItems;
  final String? name;
  final String? address;
  final String phone;

  SelectPrinterScreen({
    required this.invoiceItems,
    this.name,
    this.address,
    required this.phone,
  });

  @override
  _SelectPrinterScreenState createState() => _SelectPrinterScreenState();
}

class _SelectPrinterScreenState extends State<SelectPrinterScreen> {
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
    _devicesStreamSubscription?.cancel();
    await _flutterThermalPrinterPlugin.getPrinters(connectionTypes: [
      ConnectionType.USB,ConnectionType. BLE
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
    Future.delayed(const Duration(seconds: 5), () {
      _devicesStreamSubscription?.cancel();
      _flutterThermalPrinterPlugin.stopScan();
      setState(() {
        stopScan();
      });

    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              // startScan();
              startScan();
            },
            child: const Text('Get Printers'),
          ),
          ElevatedButton(
            onPressed: () {
              // startScan();
              stopScan();
            },
            child: const Text('Stop Scan'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: printers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  onTap: () async {
                    if (printers[index].isConnected ?? false) {
                      await _flutterThermalPrinterPlugin
                          .disconnect(printers[index]);
                    } else {
                      final isConnected = await _flutterThermalPrinterPlugin
                          .connect(printers[index]);
                      log("Devices: $isConnected");
                    }
                  },
                  title: Text(printers[index].name ?? 'No Name'),
                  subtitle: Text("Connected: ${printers[index].isConnected}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.connect_without_contact),
                    onPressed: () async {
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
                      bytes += generator.text('Item List:', styles: PosStyles(bold: true));
                      // Iterate over the items in the invoice list
                      for (var item in widget.invoiceItems) {
                        // Assuming each item is a map with keys: name, price, and quantity
                        bytes += generator.text(
                            '${item.name.padRight(20)} Rs${item.price.toStringAsFixed(2).padLeft(10)} x ${item.quantity.toString().padLeft(3)}');
                        bytes += generator.text(
                            'Total: Rs${(item.price * item.quantity).toStringAsFixed(2).padLeft(10)}');
                      }
                      // bytes += generator.text(
                      //   "Sunil Kumar",
                      //   styles: const PosStyles(
                      //     bold: true,
                      //     height: PosTextSize.size3,
                      //     width: PosTextSize.size3,
                      //   ),
                      // );
                      bytes += generator.text('Thank You, Visit Again!',
                          styles: PosStyles(align: PosAlign.center, bold: true));

                      bytes += generator.cut();
                      await _flutterThermalPrinterPlugin.printData(
                        printers[index],
                        bytes,

                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


}