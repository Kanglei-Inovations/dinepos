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
import '../provider/menu_items.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  List<dynamic> invoices = [];
  List<dynamic> invoiceItems = [];
  List<dynamic> menuItems = [];
  String database = "";
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDatabaseData(); // Corrected: Calling the method properly
    });
  }

  Future<void> _fetchDatabaseData() async {
    try {
      final menuProvider =
          Provider.of<MenuItemsProvider>(context, listen: false);
      final invoiceProvider =
          Provider.of<InvoiceProvider>(context, listen: false);

      setState(() {
        // Fetch data from providers
        menuItems = menuProvider.menuItems.map((item) {
          return {
            'id': item.id,
            'name': item.name,
            'price': item.price,
            'offerPrice': item.offerPrice,
            'stock': item.stock,
            'category': item.category,
            'subCategory': item.subCategory,
            'unitType': item.unitType,
            'description': item.description,
            'imageUrl': item.imageUrl,
            'quantity': item.quantity,
          };
        }).toList();
        invoices = invoiceProvider.invoices;
        invoiceItems = invoiceProvider.invoiceItems;

        print('Menu Items loaded: $menuItems');
        print('Invoices loaded: $invoices');
        print('Invoice Items loaded: $invoiceItems');
      });
    } catch (e) {
      print('Error fetching database data: $e');
    }
  }


  Future<void> _backupData() async {
    try {
      // Get the directory containing the images
      Directory imageDirectory = await getWritableDirectory(); // Use your method to get directory
      if (!await imageDirectory.exists()) {
        throw Exception('Image directory does not exist.');
      }

      // Get all image files from the directory (assuming you store images here)
      List<FileSystemEntity> imageFiles = imageDirectory.listSync(recursive: true);
      List<File> imagesToBackup = imageFiles
          .where((entity) => entity is File && entity.path.endsWith('.jpg') || entity.path.endsWith('.png')) // Add more formats as needed
          .map((entity) => entity as File)
          .toList();

      // Create a backup directory for the zip file
      final directory = await getApplicationDocumentsDirectory();
      final backupFile = File('${directory.path}/dinepos_backup.zip');
      final encoder = ZipFileEncoder();
      encoder.create(backupFile.path);

      // Backup JSON data
      Map<String, dynamic> database = {
        'invoices': invoices, // Replace with your actual data
        'invoice_items': invoiceItems, // Replace with your actual data
        'menu_items': menuItems, // Replace with your actual data
      };

      String jsonData = jsonEncode(database);
      File jsonBackupFile = File('${directory.path}/database_backup.json');
      jsonBackupFile.writeAsStringSync(jsonData);

      encoder.addFile(jsonBackupFile);

      // Add all images from the image directory to the zip file
      for (var image in imagesToBackup) {
        // Add each image with the original folder structure
        String relativePath = image.path.replaceFirst(imageDirectory.path, '');
        encoder.addFile(image, relativePath);
      }

      encoder.close();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Backup created successfully at ${backupFile.path}'),
      ));

      // Optionally, share the backup file
      await Share.shareXFiles([XFile(backupFile.path)],
          text: 'DinePOS Database Backup');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Backup failed: $e'),
      ));
      print('Error during backup: $e');
    }
  }

// Function to get the writable directory based on the platform
  Future<Directory> getWritableDirectory() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Use the user's home directory or a custom folder
      final home = Directory.current;
      return Directory('${home.path}/dbImage')..createSync(recursive: true);
    } else {
      // Use standard app document directory for mobile platforms
      return getApplicationDocumentsDirectory();
    }
  }

  Future<void> _restoreData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null) {
        final zipFile = File(result.files.single.path!);
        final directory = await getApplicationDocumentsDirectory();
        final extractPath = directory.path;

        final bytes = zipFile.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);

        // Extract files from the archive (JSON and images)
        for (var file in archive) {
          final filename = '$extractPath/${file.name}';
          if (file.isFile) {
            final outputFile = File(filename);
            outputFile.createSync(recursive: true);
            outputFile.writeAsBytesSync(file.content as List<int>);

            // Check if the file is an image and store it in the image directory
            if (filename.endsWith('.jpg') || filename.endsWith('.png')) {
              // Move the image to the app's image directory
              Directory imageDirectory = await getWritableDirectory();
              File restoredImage = File('${imageDirectory.path}/${file.name}');
              restoredImage.writeAsBytesSync(file.content as List<int>);
            }
          }
        }

        // Restore JSON data
        final jsonFile = File('$extractPath/database_backup.json');
        if (!jsonFile.existsSync()) {
          throw Exception('Extracted JSON file not found.');
        }

        String jsonData = jsonFile.readAsStringSync();
        Map<String, dynamic> database = jsonDecode(jsonData);

        var invoiceBox = Hive.box('invoices');
        var invoiceItemBox = Hive.box('invoice_items');
        var menuItemBox = Hive.box('menu_items');

        // Check and add new data to Hive boxes, skipping duplicates based on id
        await _restoreItemsToBox(database['invoices'], invoiceBox);
        await _restoreItemsToBox(database['invoice_items'], invoiceItemBox);
        await _restoreItemsToBox(database['menu_items'], menuItemBox);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Data restored successfully!'),
        ));

        _fetchDatabaseData(); // Refresh the UI
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Restore failed: $e'),
      ));
      print('Error during restore: $e');
    }
  }

// Helper method to restore items into a Hive box
  Future<void> _restoreItemsToBox(List<dynamic> items, Box box) async {
    for (var item in items) {
      // Check if the item already exists based on the 'id' field
      bool itemExists = box.values.any((existingItem) {
        if (existingItem is Map<String, dynamic>) {
          return existingItem['id'] == item['id']; // Assuming the item has an 'id' field
        }
        return false;
      });

      // If item doesn't exist, add it
      if (!itemExists) {
        box.add(item);
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                _fetchDatabaseData();
              },
              icon: Icon(Icons.refresh),
              label: Text('Fetch Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _backupData,
              icon: Icon(Icons.backup),
              label: Text('Backup Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _restoreData,
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
