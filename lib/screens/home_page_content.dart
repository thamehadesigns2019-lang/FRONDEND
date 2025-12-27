import 'package:flutter/material.dart';
import 'package:thameeha/sections/header/header_section.dart';
import 'package:thameeha/sections/hero/hero_section.dart';
import 'package:thameeha/sections/categories/categories_section.dart';
import 'package:thameeha/sections/trending/trending_section.dart';
import 'package:thameeha/sections/new_arrivals/new_arrivals_section.dart';
import 'package:thameeha/sections/features/features_section.dart';
import 'package:thameeha/sections/footer/footer_section.dart';

import 'package:thameeha/sections/advertise/advertise_section.dart';

import 'package:thameeha/widgets/product_search_bar.dart';
import 'package:thameeha/widgets/responsive_layout.dart';

class HomePageContent extends StatelessWidget {
  final bool disableHeader;
  const HomePageContent({super.key, this.disableHeader = false});

  @override
  Widget build(BuildContext context) {
    // Header Logic:
    // 1. If disableHeader is true (Desktop Layout), NEVER show header.
    // 2. If disableHeader is false, check ResponsiveLayout.
    //    If isDesktop is true, we usually hide header (handled by DesktopLayout).
    //    So showHeader = !disableHeader && !isDesktop.
    final bool isDesktop = ResponsiveLayout.isDesktop(context);
    final bool showHeader = !disableHeader && !isDesktop;

    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            if (showHeader) const HeaderSection(),

             // Mobile Search Bar (Only valid if NOT desktop)
            if (!isDesktop) 
               Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const ProductSearchBar(isMobile: true),
               ),

            const HeroSection(),
            AdvertiseSection(),
            CategoriesSection(),
            TrendingSection(),
            NewArrivalsSection(),
            FeaturesSection(),
            FooterSection(),
          ],
        ),
      ),
    );
  }
}