import 'package:flutter/material.dart';

import '../model/menuItem.dart';

class MenuProvider with ChangeNotifier {
  final List<MenuItem> _menuItems = [];

  List<MenuItem> get menuItems => [..._menuItems];

  void addMenuItem(MenuItem item) {
    _menuItems.add(item);
    notifyListeners();
  }
}
