import 'dart:io';
import 'package:image/image.dart';

void main() {
  // Create an image
  final image = Image(width: 100, height: 40); // Adjusted size for a logo

  // Fill it with a solid color
  fill(image, color: ColorRgb8(0, 0, 0)); // Black background

  // Draw some text for the logo
  drawString(image, 'SF', font: arial24, x: 30, y: 10, color: ColorRgb8(255, 255, 255)); // White text

  // Save it to a file
  File('assets/logo.png').writeAsBytesSync(encodePng(image));
}
