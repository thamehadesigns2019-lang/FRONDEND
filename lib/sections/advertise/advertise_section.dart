import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/widgets/product_card.dart';

class AdvertiseSection extends StatelessWidget {
  const AdvertiseSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final products = appState.advertisedProducts;

        if (products.isEmpty) {
          return const SizedBox.shrink(); // Don't show if empty
        }

        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        final isSmallMobile = screenWidth < 400; // Check for small screens

        // Dynamic Sizing
        double cardWidth;
        double cardHeight;
        if (isMobile) {
          cardWidth = screenWidth * 0.45; 
          cardHeight = cardWidth * 1.3; 
        } else if (screenWidth < 900) {
          cardWidth = 200;
          cardHeight = 280;
        } else {
          cardWidth = 240;
          cardHeight = 320;
        }

        return Container(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 32 : 64),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
                child: Row(
                  children: [
                    Icon(Icons.stars_rounded, color: Colors.indigo, size: isSmallMobile ? 24 : (isMobile ? 28 : 32)),
                    const SizedBox(width: 12),
                    Text(
                      'Featured Products', // "Advertise" sounds internal. "Featured" is better for users.
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallMobile ? 22 : (isMobile ? 24 : 32),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: cardWidth,
                      child: ProductCard(product: products[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
