import 'dart:io';
import 'package:image/image.dart';

void main() {
  // Create an image
  final image = Image(width: 512, height: 512);

  // Fill it with a solid color
  fill(image, color: ColorRgb8(7, 25, 82));

  // Draw some text
  drawString(image, 'ShopFlow', font: arial48, x: 130, y: 220);

  // Save it to a file
  File('assets/splash.png').writeAsBytesSync(encodePng(image));
}
