import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';

import '../provider/InvoiceProvider.dart';
import '../provider/MenuProvider.dart';
import '../provider/settings_provider.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final menuProvider = Provider.of<MenuItemsProvider>(context, listen: false);
      final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);
      Provider.of<SettingsProvider>(context, listen: false)
          .fetchDatabaseData(menuProvider, invoiceProvider);
    });
  }


  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                final menuProvider =
                Provider.of<MenuItemsProvider>(context, listen: false);
                final invoiceProvider =
                Provider.of<InvoiceProvider>(context, listen: false);
                settingsProvider.fetchDatabaseData(menuProvider, invoiceProvider);
              },
              icon: Icon(Icons.refresh),
              label: Text('Fetch Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
            ),
            SizedBox(height: 16),
            Center(child: LinearProgressIndicator(value: settingsProvider.backupProgress / 100)),
            ElevatedButton.icon(
              onPressed: () async { await settingsProvider.backupData(context);},
              icon: Icon(Icons.backup),
              label: Text('Backup Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final menuProvider =
                Provider.of<MenuItemsProvider>(context, listen: false);
                final invoiceProvider =
                Provider.of<InvoiceProvider>(context, listen: false);
                settingsProvider.restoreData(menuProvider,invoiceProvider);
              },
              icon: Icon(Icons.restore),
              label: Text('Restore Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Database Preview:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            _buildSection("Invoice", settingsProvider.invoices ),
            _buildSection("InvoiceItem", settingsProvider.invoiceItems ),
            _buildSection("MenuItem", settingsProvider.menuItems ),


          ],
        ),
      ),
    );
  }

   _buildSection(String title, List<dynamic> data) {
    if (data.isEmpty) {
      return ListTile(
        title:
            Text('$title: No Data Stored', style: TextStyle(color: Colors.red)),
      );
    }

    return ExpansionTile(
      title: Text(title, style: TextStyle(fontSize: 16)),
      children: data.map((item) {
        String displayText = item?.toString() ?? 'Empty item';
        return ListTile(
          title: Text(displayText),
        );
      }).toList(),
    );
  }
}
