import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  static const String companyName = 'Thameeha Designs';
  static const String slogan = 'Where Creativity Meets Innovation';
  static const String phoneNumber = '+123 456 7890';
  static const String logoUrl = 'assets/logo.png'; // Main logo
  static const String email = 'info@thameeha.com';
  static const String address = '123 Design Street, Creative City';
  static const String website = 'www.thameeha.com';

  // Social Media Links
  static const String facebookUrl = 'https://www.facebook.com/thameeha';
  static const String instagramUrl = 'https://www.instagram.com/thameeha';
  static const String twitterUrl = 'https://www.twitter.com/thameeha';
  static const String linkedinUrl = 'https://www.linkedin.com/company/thameeha';

  // App Specific Constants
  static const String appName = 'Thameeha';
  static const String appVersion = '1.0.0';

  static String get apiUrl {
    if (kReleaseMode) {
      // In production, use the same origin as the web app
      // Remove trailing slash if present to avoid double slashes when appending paths
      final origin = Uri.base.origin;
      return origin; 
    }
    return 'http://localhost:3000'; // Backend base URL for dev
  }

  static const String cashfreeEnvironment = 'SANDBOX'; // Change to 'PRODUCTION' when live

  // Design related constants
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;
  static const double defaultBorderRadius = 8.0;

  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  // Onboarding Dot Indicator Constants
  static const double dotIndicatorSize = 6.0;
  static const double dotIndicatorSelectedWidth = 20.0;
  static const double dotIndicatorSpacing = 5.0;
}
