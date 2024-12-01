import 'dart:convert';
import 'dart:io';

import 'package:dinepos/provider/InvoiceProvider.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'MenuProvider.dart';

class SettingsProvider with ChangeNotifier {
  List<dynamic> invoices = [];
  List<dynamic> invoiceItems = [];
  List<dynamic> menuItems = [];
  double backupProgress = 0.0;

  // Fetch data from Hive boxes and prepare for UI
  Future<void> fetchDatabaseData(
      MenuItemsProvider menuProvider, InvoiceProvider invoiceProvider) async {
    try {
      // Fetch data from the provided menu and invoice providers
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

      debugPrint('Successfully fetched all data');
      notifyListeners(); // Notify listeners to update UI
    } catch (e) {
      debugPrint('Error fetching database data: $e');
    }
  }


  // Future<String> getBackupDBPath() async {
  //   String path = '';
  //   if (Platform.isAndroid || Platform.isIOS) {
  //     final directory = await getApplicationDocumentsDirectory();
  //     path = '${directory.path}/dinepos_db2';
  //   } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
  //     path = '${Directory.current.path}/dinepos_db2';
  //   }
  //   return path;
  // }
  Future<String> getBackupDBPath() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/dinepos_db2';
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return '${Directory.current.path}/dinepos_db2';
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Get backup path for images
  Future<Directory> getBackupImagePath() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final home = Directory.current;
      return Directory('${home.path}/dbImage')..createSync(recursive: true);
    } else {
      return getApplicationDocumentsDirectory();
    }
  }

  // Perform backup
  Future<void> backupData(BuildContext context) async {
    try {
      Directory imageDirectory = await getBackupImagePath();
      if (!await imageDirectory.exists()) {
        throw Exception('Image directory does not exist.');
      }

      List<FileSystemEntity> imageFiles = imageDirectory.listSync(recursive: true);
      final path = await getBackupDBPath();
      final backupDir = Directory(path);

      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }

      final tempJsonPath = '$path/temp_database_backup.json';
      Map<String, dynamic> database = {
        'invoices': invoices,
        'invoice_items': invoiceItems,
        'menu_items': menuItems,
      };

      String jsonData = jsonEncode(database);
      final jsonFile = File(tempJsonPath);
      await jsonFile.writeAsString(jsonData);

      final zipFilePath = '$path/dinepos_backup.zip';
      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);
      encoder.addFile(jsonFile, 'dinepos_db2/database_backup.json');

      // Backup images with progress
      // for (int i = 0; i < imageFiles.length; i++) {
      //   var image = imageFiles[i];
      //   encoder.addFile(image as File, 'dbImage/${image.path.split('/').last}');
      //   backupProgress = ((i + 1) / imageFiles.length) * 100;
      //   notifyListeners();
      // }
// Backup images with progress
      for (int i = 0; i < imageFiles.length; i++) {
        var image = imageFiles[i];
        if (image is File) { // Ensure only files are processed
          encoder.addFile(image, '${image.path.split('/').last}');
        }
        backupProgress = ((i + 1) / imageFiles.length) * 100;
        notifyListeners();
      }

      encoder.close();


      if (await jsonFile.exists()) {
        await jsonFile.delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Backup created successfully at $zipFilePath'),
      ));
      print(zipFilePath);

      // await Share.shareXFiles([XFile(zipFilePath.path)]);


    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Backup failed: $e'),
      ));
      print('Error during backup: $e');
    }
  }

  // Restore data from backup
  Future<void> restoreData(MenuItemsProvider menuProvider, InvoiceProvider invoiceProvider) async {
    final testDir = await getApplicationDocumentsDirectory();
    if (!await Directory(testDir.path).exists()) {
      throw Exception('Unable to access writeable directory on Android.');
    }
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null) {
        final zipFile = File(result.files.single.path!);
        final path = await getBackupDBPath();

        final bytes = zipFile.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);

        // for (var file in archive) {
        //   final filename = file.name;
        //   if (file.isFile) {
        //     final outputFile = File(filename);
        //     outputFile.createSync(recursive: true);
        //     outputFile.writeAsBytesSync(file.content as List<int>);
        //   }
        // }
        for (var file in archive) {
          final outputPath = await getBackupDBPath(); // Use backup path for Android
          final filename = '$outputPath/${file.name}';
          if (file.isFile) {
            final outputFile = File(filename);
            outputFile.createSync(recursive: true);
            outputFile.writeAsBytesSync(file.content as List<int>);
          }
        }
        final jsonFile = File('$path/database_backup.json');
        print(jsonFile);
        if (jsonFile.existsSync()) {
          String jsonData = jsonFile.readAsStringSync();
          Map<String, dynamic> database = jsonDecode(jsonData);


          // Delegate restoration to the provider
          await menuProvider.restoreMenuItems(database['menu_items']);
          await invoiceProvider.restoreInvoices(database['invoices']);
          await invoiceProvider.restoreInvoiceItems(database['invoice_items']);
          notifyListeners();
          print('Restore completed.');
        }
      }
    } catch (e) {
      debugPrint('Error during restore: $e');
    }
  }

  // Future<void> _restoreItemsToBox(List<dynamic> items, Box box) async {
  //   for (var item in items) {
  //     bool exists = box.values.any((existing) => existing['id'] == item['id']);
  //     if (!exists) {
  //       box.put(item.id, item);
  //     }
  //   }
  // }
}
