import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:developer';
class SelectPrinterScreen extends StatefulWidget {
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
  }

  void startScan() async {
    _devicesStreamSubscription?.cancel();
    await _flutterThermalPrinterPlugin.getPrinters(connectionTypes: [
      ConnectionType.USB,
    ]);
    _devicesStreamSubscription = _flutterThermalPrinterPlugin.devicesStream
        .listen((List<Printer> event) {
      log(event.map((e) => e.name).toList().toString());
      setState(() {
        printers = event;
        printers
            .removeWhere((element) => element.name == null || element.name == ''
          //  ||
          // !element.name!.toLowerCase().contains('print')
        );
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
                      final generator = Generator(PaperSize.mm80, profile);
                      List<int> bytes = [];
                      bytes += generator.text(
                        "Sunil Kumar",
                        styles: const PosStyles(
                          bold: true,
                          height: PosTextSize.size3,
                          width: PosTextSize.size3,
                        ),
                      );
                      bytes += generator.cut();
                      await _flutterThermalPrinterPlugin.printData(
                        printers[index],
                        bytes,
                        longData: true,
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

  Widget receiptWidget() {
    return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.white,
        width: 300,
        height: 300,
        child: const Center(
          child: Column(
            children: [
              Text(
                "FLUTTER THERMAL PRINTER",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Hello World",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "This is a test receipt",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        )
    );
  }

}