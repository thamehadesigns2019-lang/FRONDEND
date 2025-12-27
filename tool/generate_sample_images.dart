import 'dart:io';
import 'package:image/image.dart';

void main() {
  // Generate sample_logo.png
  final logoImage = Image(width: 100, height: 40);
  fill(logoImage, color: ColorRgb8(50, 50, 50)); // Dark grey background
  drawString(logoImage, 'LOGO', font: arial24, x: 20, y: 10, color: ColorRgb8(255, 255, 255));
  File('assets/sample_logo.png').writeAsBytesSync(encodePng(logoImage));

  // Generate sample_splash.png
  final splashImage = Image(width: 512, height: 512);
  fill(splashImage, color: ColorRgb8(7, 25, 82)); // Blue background
  drawString(splashImage, 'SPLASH', font: arial48, x: 140, y: 220, color: ColorRgb8(255, 255, 255));
  File('assets/sample_splash.png').writeAsBytesSync(encodePng(splashImage));

  // Generate sample_onboarding1.png, sample_onboarding2.png, sample_onboarding3.png
  final List<ColorRgb8> colors = [
    ColorRgb8(66, 135, 245), // Blue
    ColorRgb8(245, 170, 66), // Orange
    ColorRgb8(66, 245, 135), // Green
  ];

  final List<String> texts = [
    'ONBOARD1',
    'ONBOARD2',
    'ONBOARD3',
  ];

  for (int i = 0; i < 3; i++) {
    final onboardingImage = Image(width: 512, height: 512);
    fill(onboardingImage, color: colors[i]);
    drawString(onboardingImage, texts[i], font: arial48, x: 140, y: 220, color: ColorRgb8(255, 255, 255));
    File('assets/sample_onboarding${i + 1}.png').writeAsBytesSync(encodePng(onboardingImage));
  }
}
