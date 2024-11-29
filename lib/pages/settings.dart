import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  List<dynamic> invoices = [];
  List<dynamic> invoiceItems = [];
  List<dynamic> menuItems = [];

  @override
  void initState() {
    super.initState();
    _fetchDatabaseData();
  }

  Future<void> _fetchDatabaseData() async {
    var invoiceBox = Hive.box('invoices');
    var invoiceItemBox = Hive.box('invoice_items');
    var menuItemBox = Hive.box('menu_items');

    setState(() {
      invoices = invoiceBox.values.toList();
      invoiceItems = invoiceItemBox.values.toList();
      menuItems = menuItemBox.values.toList();
    });
  }

  Future<void> _backupData() async {
    try {
      Map<String, dynamic> database = {
        'invoices': invoices,
        'invoice_items': invoiceItems,
        'menu_items': menuItems,
      };

      // Serialize to JSON
      String jsonData = jsonEncode(database);

      // Save as a ZIP file
      final directory = await getApplicationDocumentsDirectory();
      final backupFile = File('${directory.path}/dinepos_backup.zip');

      final encoder = ZipFileEncoder();
      encoder.create(backupFile.path);
      encoder.addFile(File('${directory.path}/database_backup.json')..writeAsStringSync(jsonData));
      encoder.close();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Backup created successfully at ${backupFile.path}'),
      ));

      // Share the backup
      await Share.shareXFiles([XFile(backupFile.path)], text: 'DinePOS Database Backup');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Backup failed: $e'),
      ));
    }
  }

  Future<void> _restoreData() async {
    try {
      // Pick a ZIP file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null) {
        final zipFile = File(result.files.single.path!);
        final directory = await getApplicationDocumentsDirectory();
        final extractPath = directory.path;

        // Extract the ZIP file
        final bytes = zipFile.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);

        for (var file in archive) {
          final filename = '$extractPath/${file.name}';
          if (file.isFile) {
            final outputFile = File(filename);
            outputFile.createSync(recursive: true);
            outputFile.writeAsBytesSync(file.content as List<int>);
          }
        }

        // Read the extracted JSON file
        final jsonFile = File('$extractPath/database_backup.json');
        String jsonData = jsonFile.readAsStringSync();
        Map<String, dynamic> database = jsonDecode(jsonData);

        // Restore the data into Hive
        var invoiceBox = Hive.box('invoices');
        var invoiceItemBox = Hive.box('invoice_items');
        var menuItemBox = Hive.box('menu_items');

        await invoiceBox.clear();
        await invoiceItemBox.clear();
        await menuItemBox.clear();

        for (var item in database['invoices']) {
          invoiceBox.add(item);
        }
        for (var item in database['invoice_items']) {
          invoiceItemBox.add(item);
        }
        for (var item in database['menu_items']) {
          menuItemBox.add(item);
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Data restored successfully!'),
        ));
        _fetchDatabaseData(); // Refresh the UI
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Restore failed: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Backup & Restore'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _backupData,
              icon: Icon(Icons.backup),
              label: Text('Backup Data'),
              style: ElevatedButton.styleFrom(
                primary: Colors.teal,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _restoreData,
              icon: Icon(Icons.restore),
              label: Text('Restore Data'),
              style: ElevatedButton.styleFrom(
                primary: Colors.teal,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Database Preview:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildSection('Invoices', invoices),
                  _buildSection('Invoice Items', invoiceItems),
                  _buildSection('Menu Items', menuItems),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> data) {
    return ExpansionTile(
      title: Text(title, style: TextStyle(fontSize: 16)),
      children: data
          .map((item) => ListTile(
        title: Text(item.toString()),
      ))
          .toList(),
    );
  }
}
