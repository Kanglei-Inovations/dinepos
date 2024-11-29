import 'package:flutter/material.dart';

class PaperCutClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    double zigzagHeight = 10; // Height of each "V"
    double zigzagWidth = 10;  // Width of each "V"

    // Start at the top-left corner
    path.moveTo(0, 0);

    // Create the zigzag pattern
    for (double x = 0; x < size.width; x += zigzagWidth) {
      path.lineTo(x + zigzagWidth / 2, zigzagHeight); // Move up to form the peak
      path.lineTo(x + zigzagWidth, 0); // Move back down
    }

    // Close the path on the other sides
    path.lineTo(size.width, size.height); // Right edge
    path.lineTo(0, size.height); // Bottom edge
    path.close(); // Complete the path
    // Complete path
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}