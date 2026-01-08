import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/models/product.dart';
import 'package:thameeha/theme/themes.dart';
import 'package:thameeha/widgets/product_card.dart';
import 'package:thameeha/widgets/skeleton_loader.dart';

class TrendingSection extends StatefulWidget {
  const TrendingSection({super.key});

  @override
  State<TrendingSection> createState() => _TrendingSectionState();
}

class _TrendingSectionState extends State<TrendingSection> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 1000), 
        vsync: this
    );
    _controller.forward();
    _scrollController.addListener(_checkScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    setState(() {
      _canScrollLeft = currentScroll > 1.0;
      _canScrollRight = currentScroll < maxScroll - 1.0;
    });
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      (_scrollController.offset - 200).clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      (_scrollController.offset + 200).clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Trending Section
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400; // Check for small screens
    
    // Calculate card width based on screen size
    double cardWidth;
    double cardHeight;
    double horizontalPadding;
    
    if (isMobile) {
      // Mobile: smaller cards that fit perfectly on all devices (2 cards per row)
      // Total margins: Outer(12) + Gap(12) + Outer(12) = 36 approx usage space if we count carefully
      // Formula: (Width - TotalPaddingAndMargins) / 2
      horizontalPadding = 12;
      // List Padding (6 + 6) + Card Margins (6 + 6 per card means 12 gap between centers?)
      // Layout: [Pad 6] [Card 6..6] [Card 6..6] [Pad 6]
      // 6 + 6+Content+6 + 6+Content+6 + 6 = 36 + 2*Content = Width
      cardWidth = (screenWidth - 36) / 2;
      cardHeight = cardWidth * 1.35; 
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
        vertical: isMobile ? 40 : 80,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA), // Very light gray for subtle contrast
      ),
      child: Column(
        children: [
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
                      Row(
                        children: [
                          FadeTransition(
                            opacity: Tween<double>(begin: 0, end: 1).animate(_controller),
                            child: Icon(
                              Icons.trending_up_rounded,
                              color: Colors.black,
                              size: isSmallMobile ? 24 : (isMobile ? 28 : 32),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FadeTransition(
                            opacity: Tween<double>(begin: 0, end: 1).animate(
                              CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
                            ),
                            child: SlideTransition(
                              position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
                                CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
                              ),
                              child: Text(
                                'Trending Now',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallMobile ? 14 : (isMobile ? 16 : 32),
                                      letterSpacing: 1.0,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ScaleTransition(
                        scale: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.8, curve: Curves.elasticOut)),
                        ),
                        child: Container(
                          width: isSmallMobile ? 60 : 80,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Row(
                  children: [
                    if (isMobile) ...[
                      IconButton(
                        onPressed: _canScrollLeft ? _scrollLeft : null,
                        icon: Icon(Icons.arrow_back_ios, size: 16, color: _canScrollLeft ? Colors.black : Colors.grey.withOpacity(0.3)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: _canScrollRight ? _scrollRight : null,
                        icon: Icon(Icons.arrow_forward_ios, size: 16, color: _canScrollRight ? Colors.black : Colors.grey.withOpacity(0.3)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                    ],
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
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(
                              fontSize: isSmallMobile ? 12 : (isMobile ? 14 : 16),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                           Icon(Icons.arrow_forward, size: isSmallMobile ? 14 : 16),
                        ],
                      ),
                    ),
                  ),
                  ]
                ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 24 : 40),
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

                // Filter products marked as trending or explicitly advertised
                final trendingProducts = appState.products
                    .where((p) => p.isTrending == true || p.isAdvertised == true)
                    .toList();
                
                // Prioritize advertised products in the trending list
                trendingProducts.sort((a,b) {
                  if (a.isAdvertised && !b.isAdvertised) return -1;
                  if (!a.isAdvertised && b.isAdvertised) return 1;
                  return 0;
                });

                final displayList = trendingProducts.take(10).toList();
                
                if (displayList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No trending products yet',
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
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
                  scrollDirection: Axis.horizontal,
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    
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
