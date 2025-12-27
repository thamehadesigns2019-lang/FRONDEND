import 'dart:io';
import 'package:image/image.dart';

void main() {
  // Define colors for each image
  final List<ColorRgb8> colors = [
    ColorRgb8(66, 135, 245), // Blue
    ColorRgb8(245, 170, 66), // Orange
    ColorRgb8(66, 245, 135), // Green
  ];

  final List<String> texts = [
    'Welcome',
    'Shop',
    'Secure',
  ];

  for (int i = 0; i < 3; i++) {
    // Create an image
    final image = Image(width: 512, height: 512);

    // Fill it with a solid color
    fill(image, color: colors[i]);

    // Draw some text
    drawString(image, texts[i], font: arial48, x: 170, y: 220);

    // Save it to a file
    File('assets/onboarding${i + 1}.png').writeAsBytesSync(encodePng(image));
  }
}
