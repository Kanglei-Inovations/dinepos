import 'dart:ui';
import 'package:dinepos/pages/billing.dart';
import 'package:dinepos/pages/dashboard.dart';
import 'package:dinepos/pages/inventory.dart';
import 'package:dinepos/pages/menu_items.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/const.dart';
import '../pages/reports.dart';
import '../pages/settings.dart';
import '../pages/user_management.dart';

// Basic responsive utility to detect desktop screens
class Responsive {
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 1024;
}

class SideMenu extends StatefulWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  _SideMenuState createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  int _currentIndex = 0;

  // List of pages corresponding to each menu item
  final List<Widget> _pages = [
    Dashboard(),
    Billing(),
    Inventory(),
    MenuItemsScreen(),
    Reports(),
    UserManagement(),
    Settings(),
  ];

  void _onSelectPage(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (!Responsive.isDesktop(context)) {
      Navigator.pop(context); // Close the drawer on mobile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Responsive.isMobile(context)
          ? AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Opens the drawer
              },
            );
          },
        ),
        title: Text('DinePOS'),
      )
          : null, // No app bar on desktop, since we use a permanent drawer

      body: Row(

        children: [

          // Show Drawer as a permanent sidebar on desktop
          if (Responsive.isDesktop(context))
            Container(
              width: 250, // Fixed width for the side menu
              child: Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(color: primaryColor),
                      child: Column(
                        children: [
                          Text(
                            'DinePOS',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Billing and Management System',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                          Text(
                            'By- KANGLEI INOVATIONS',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    _buildMenuItem(Icons.home, 'Dashboard', 0),
                    _buildMenuItem(Icons.shopping_cart, 'Sale', 1),
                    _buildMenuItem(Icons.shopping_bag, 'Inventory', 2),
                    _buildMenuItem(Icons.local_dining, 'Items/Menu', 3),
                    _buildMenuItem(Icons.report, 'Report', 4),
                    _buildMenuItem(Icons.supervised_user_circle, 'UserManagement', 5),
                    _buildMenuItem(Icons.settings, 'Settings', 6),
                  ],
                ),
              ),
            ),
          // Main content area
          _pages[_currentIndex],
        ],
      ),
      // Show drawer as a collapsible menu only on mobile
      drawer: Responsive.isDesktop(context)
          ? null
          : Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              child: Column(
                children: [
                  Text(
                    'DinePOS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Billing and Management System',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Text(
                    'By- KANGLEI INOVATIONS',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
            _buildMenuItem(Icons.home, 'Dashboard', 0),
            _buildMenuItem(Icons.shopping_cart, 'Sale', 1),
            _buildMenuItem(Icons.shopping_bag, 'Inventory', 2),
            _buildMenuItem(Icons.local_dining, 'Items/Menu', 3),
            _buildMenuItem(Icons.report, 'Report', 4),
            _buildMenuItem(Icons.supervised_user_circle, 'UserManagement', 5),
            _buildMenuItem(Icons.settings, 'Settings', 6),
          ],
        ),
      ),
    );
  }

  // Reusable method to build menu items with hover and active state decoration
  Widget _buildMenuItem(IconData icon, String title, int index) {
    return InkWell(
      onTap: () => _onSelectPage(index),
      child: MouseRegion(
        onEnter: (_) => setState(() {}),
        onExit: (_) => setState(() {}),
        child: Container(
          decoration: BoxDecoration(
            color: _currentIndex == index
                ? Colors.greenAccent.withOpacity(0.8) // Active color
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Icon(icon, color:_currentIndex == index ? Colors.white : Colors.greenAccent ,),
            title: Text(
              title,
              style: TextStyle(
                color: _currentIndex == index ? Colors.white : Colors.white,
                fontWeight: _currentIndex == index
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
