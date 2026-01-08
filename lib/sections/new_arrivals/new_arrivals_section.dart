import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/models/product.dart';
import 'package:thameeha/theme/themes.dart';
import 'package:thameeha/widgets/product_card.dart';
import 'package:thameeha/widgets/skeleton_loader.dart';

class NewArrivalsSection extends StatefulWidget {
  const NewArrivalsSection({super.key});

  @override
  State<NewArrivalsSection> createState() => _NewArrivalsSectionState();
}

class _NewArrivalsSectionState extends State<NewArrivalsSection> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 1000), 
        vsync: this
    );
    // Start animation immediately when widget builds (or use VisibilityDetector if available, but not here)
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;
    
    // Calculate card width based on screen size
    double cardWidth;
    double cardHeight;
    double horizontalPadding;
    
    if (isMobile) {
      // Mobile: smaller cards that fit perfectly on all devices
      cardWidth = screenWidth * 0.45; // Reduced from 60% to 45%
      cardHeight = cardWidth * 1.3; // Better aspect ratio (reduced from 1.5)
      horizontalPadding = 12;
    } else if (screenWidth < 900) {
      // Tablet
      cardWidth = 200;
      cardHeight = 280;
      horizontalPadding = 16;
    } else {
      // Desktop
      cardWidth = 240;
      cardHeight = 320;
      horizontalPadding = 24;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 80, // More vertical space
      ),
      color: AppTheme.lightBg,
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
                             CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
                          ),
                          child: Text(
                            'New Arrivals',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallMobile ? 22 : (isMobile ? 28 : 32), // Larger font
                                  letterSpacing: 1.0,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ScaleTransition(
                        scale: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.8, curve: Curves.elasticOut)),
                        ),
                        child: Container(
                          width: isSmallMobile ? 60 : 80, // Longer line
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black, // Solid black
                            borderRadius: BorderRadius.zero, // Sharp
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                FadeTransition(
                   opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
                    ),
                  child: TextButton(
                    onPressed: () {
                      Provider.of<AppState>(context, listen: false).setSelectedTab(1);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                    child: Row(
                      children: [
                         Text(
                          'View All',
                          style: TextStyle(
                            fontSize: isSmallMobile ? 12 : (isMobile ? 14 : 16), 
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0
                          ),
                        ),
                        const SizedBox(width: 8),
                         Icon(Icons.arrow_forward, size: isSmallMobile ? 14 : 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: isMobile ? 24 : 40),
          
          // List
          SizedBox(
            height: cardHeight,
            child: Consumer<AppState>(
              builder: (context, appState, child) {
                if (appState.isProductsLoading) {
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
                    itemCount: 4,
                    itemBuilder: (context, index) => Container(
                      width: cardWidth,
                      margin: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader(width: cardWidth, height: cardHeight * 0.7, borderRadius: 16),
                          const SizedBox(height: 12),
                          SkeletonLoader(width: cardWidth * 0.8, height: 20),
                          const SizedBox(height: 8),
                          SkeletonLoader(width: cardWidth * 0.4, height: 16),
                        ],
                      ),
                    ),
                  );
                }

                // Filter products marked as new arrivals or explicitly advertised
                final newArrivalProducts = appState.products
                    .where((p) => p.isNewArrival == true || p.isAdvertised == true)
                    .toList();
                
                // Prioritize advertised products in the new arrivals list
                newArrivalProducts.sort((a,b) {
                  if (a.isAdvertised && !b.isAdvertised) return -1;
                  if (!a.isAdvertised && b.isAdvertised) return 1;
                  return 0;
                });

                final displayList = newArrivalProducts.take(10).toList();
                
                if (displayList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.new_releases_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No new arrivals yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
                  scrollDirection: Axis.horizontal,
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    
                    // Staggered Animation for each card
                    final double startTime = 0.2 + (index * 0.1);
                    final double endTime = startTime + 0.4;
                    
                    final Animation<double> fade = Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _controller,
                         curve: Interval(
                           startTime.clamp(0.0, 1.0), 
                           endTime.clamp(0.0, 1.0), 
                           curve: Curves.easeOut
                         ),
                      ),
                    );
 
                    final Animation<Offset> slide = Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: Interval(
                           startTime.clamp(0.0, 1.0), 
                           endTime.clamp(0.0, 1.0), 
                           curve: Curves.easeOut
                         ),
                      ),
                    );
 
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: fade,
                          child: SlideTransition(
                            position: slide,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: cardWidth,
                        margin: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
                        child: ProductCard(product: displayList[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
