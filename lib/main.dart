import 'dart:io';
import 'package:dinepos/pages/menu_items.dart';
import 'package:dinepos/pages/sale_billing.dart';
import 'package:dinepos/provider/InvoiceProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'model/invoice_items_model.dart';
import 'model/invoice_model.dart';
import 'provider/settings_provider.dart';
import 'utils/const.dart';
import 'widget/side_menu.dart';
import 'model/menuItem.dart';
import 'provider/MenuProvider.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Define the path for Hive storage
    var path = '';
    if (Platform.isAndroid || Platform.isIOS) {
      // Use path_provider for mobile platforms
      final directory = await getApplicationDocumentsDirectory();
      path = '${directory.path}/dinepos_db2';
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Use the current directory for desktop platforms
      path = Directory.current.path + '/dinepos_db2';
    }

    // Create the directory if it doesn't exist
    await Directory(path).create(recursive: true);
    Hive.init(path);

    // Register adapters before opening boxes
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(InvoiceItemAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(InvoiceAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MenuItemAdapter());
    }
    // Open the boxes after registering the adapters
    await Hive.openBox<InvoiceItem>('invoice_items');
    await Hive.openBox<Invoice>('invoices');
    await Hive.openBox<MenuItem>('menu_items');

  } catch (e) {
    print("Error initializing Hive: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MenuItemsProvider>(create: (_) => MenuItemsProvider()..loadMenuItems()),
        ChangeNotifierProvider<InvoiceProvider>(create: (_) => InvoiceProvider()..loadInvoices()),
        ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
      ],
      child: GetMaterialApp(
        title: 'DINEPOS',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: bgColor,
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
              .apply(bodyColor: Colors.white),
          canvasColor: secondaryColor,
        ),
        debugShowCheckedModeBanner: false,
        home: SideMenu(),
      ),
    );
  }
}
