import 'package:flutter/material.dart';

Widget getUnitIcon(String unitType) {
  switch (unitType) {
    case 'Full':
      return Text("F"); // Icon for Full
    case 'Half':
      return Text("H"); // Icon for Half
    case 'Kg':
      return Text("K"); // Icon for Kg
    case 'Piece':
      return Text("P"); // Icon for Piece
    default:
      return Icon(Icons.help_outline, color: Colors.grey); // Default icon for unknown unitType
  }
}