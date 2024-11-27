import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart'; // Import provider package
import 'utils/const.dart';
import 'widget/side_menu.dart';
import 'model/menuItem.dart';
import 'provider/menu_items.dart'; // Import your MenuProvider
import 'package:path_provider/path_provider.dart'; // For cross-platform paths
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Set a custom path for Hive data storage
  try {
    // Cross-platform storage path
    var path = Directory.current.path + '/dinepos_data';
    await Directory(path).create(recursive: true); // Ensure the directory exists
    Hive.init(path);
    Hive.registerAdapter(MenuItemAdapter());
    await Hive.openBox<MenuItem>('menu_items');
  } catch (e) {
    print("Error initializing Hive: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MenuItemsProvider>(
      create: (_) => MenuItemsProvider()..loadMenuItems(), // Load items on startup,  // Provide MenuProvider to the widget tree
      child: GetMaterialApp(
        title: 'DINEPOS',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: bgColor,
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
              .apply(bodyColor: Colors.white),
          canvasColor: secondaryColor,
        ),
        debugShowCheckedModeBanner: true,
        home: SideMenu(),
      ),
    );
  }
}
