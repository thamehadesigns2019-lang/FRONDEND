import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/theme/themes.dart';
import 'package:thameeha/widgets/skeleton_loader.dart';
import 'package:thameeha/constants.dart';
import 'dart:convert';

class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  // Category icon mapping
  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('electronic') || categoryLower.contains('tech')) {
      return Icons.devices_rounded;
    } else if (categoryLower.contains('fashion') || categoryLower.contains('cloth')) {
      return Icons.checkroom_rounded;
    } else if (categoryLower.contains('home') || categoryLower.contains('furniture')) {
      return Icons.home_rounded;
    } else if (categoryLower.contains('book')) {
      return Icons.menu_book_rounded;
    } else if (categoryLower.contains('sport') || categoryLower.contains('fitness')) {
      return Icons.fitness_center_rounded;
    } else if (categoryLower.contains('beauty') || categoryLower.contains('cosmetic')) {
      return Icons.face_rounded;
    } else if (categoryLower.contains('toy') || categoryLower.contains('game')) {
      return Icons.toys_rounded;
    } else if (categoryLower.contains('food') || categoryLower.contains('grocery')) {
      return Icons.restaurant_rounded;
    } else if (categoryLower.contains('jewelry') || categoryLower.contains('accessory')) {
      return Icons.diamond_rounded;
    } else if (categoryLower.contains('pet')) {
      return Icons.pets_rounded;
    } else {
      return Icons.category_rounded;
    }
  }

  // Category color mapping
  List<Color> _getCategoryGradient(int index) {
    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)], // Purple
      [const Color(0xFFf093fb), const Color(0xFFf5576c)], // Pink
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // Cyan
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)], // Green
      [const Color(0xFFfa709a), const Color(0xFFfee140)], // Orange
      [const Color(0xFF30cfd0), const Color(0xFF330867)], // Teal
      [const Color(0xFFa8edea), const Color(0xFFfed6e3)], // Light
      [const Color(0xFFff9a9e), const Color(0xFFfecfef)], // Rose
    ];
    return gradients[index % gradients.length];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400; // Check for small screens
    
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 80,
        horizontal: isMobile ? 12 : 24,
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shop by Category',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallMobile ? 22 : (isMobile ? 28 : 32),
                            letterSpacing: 1.0,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 60,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Explore our diverse collection',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: isMobile ? 24 : 40),
          
          // Categories Grid
          Consumer<AppState>(
            builder: (context, appState, child) {
              if (appState.isProductsLoading) {
                 return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : (screenWidth < 900 ? 3 : 5),
                      crossAxisSpacing: isMobile ? 12 : 24,
                      mainAxisSpacing: isMobile ? 12 : 24,
                      childAspectRatio: isMobile ? 0.9 : 1.0,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => SkeletonLoader(width: 100, height: 100, borderRadius: 0),
                  );
              }

              // Use API categories if available (contains images), otherwise fallback to product tags
              List<dynamic> categoriesToDisplay = [];
              if (appState.categories.isNotEmpty) {
                categoriesToDisplay = appState.categories;
              } else {
                // Fallback: derive from products
                 categoriesToDisplay = appState.products
                  .map((p) => {'name': p.category, 'image': null})
                  .toSet() // This might not work well for Maps, but let's assume unique names
                  .toList();
                  // actually dedupe by name manually if needed, but for now relies on backend
              }

              if (categoriesToDisplay.isEmpty) {
                return const Center(child: Text("No categories"));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount;
                  double childAspectRatio;
                  
                  if (constraints.maxWidth < 600) {
                    crossAxisCount = 2;
                    childAspectRatio = 0.9; 
                  } else if (constraints.maxWidth < 900) {
                    crossAxisCount = 3;
                    childAspectRatio = 1.0;
                  } else if (constraints.maxWidth < 1200) {
                    crossAxisCount = 4;
                    childAspectRatio = 1.0;
                  } else {
                    crossAxisCount = 5;
                    childAspectRatio = 1.0;
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: isMobile ? 12 : 24,
                      mainAxisSpacing: isMobile ? 12 : 24,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: categoriesToDisplay.length,
                    itemBuilder: (context, index) {
                      final catData = categoriesToDisplay[index];
                      // Normalize data (handle both Map from API and String fallback if any)
                      String name = '';
                      String? image;
                      
                      if (catData is Map) {
                         name = catData['name'] ?? 'Unknown';
                         image = catData['image'];
                      } else if (catData is String) { // Fallback if list was mixed
                         name = catData;
                      }

                      final productCount = appState.products
                          .where((p) => p.category.toLowerCase() == name.toLowerCase())
                          .length;
                      
                      return _CategoryCard(
                        category: name,
                         imageUrl: image,
                        productCount: productCount,
                        icon: _getCategoryIcon(name),
                        gradient: index % 2 == 0 
                            ? [Colors.black, const Color(0xFF333333)] 
                            : [const Color(0xFF222222), const Color(0xFF444444)],
                        isMobile: isMobile,
                        index: index,
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String category;
  final String? imageUrl;
  final int productCount;
  final IconData icon;
  final List<Color> gradient;
  final bool isMobile;
  final int index;

  const _CategoryCard({
    required this.category,
    this.imageUrl,
    required this.productCount,
    required this.icon,
    required this.gradient,
    required this.isMobile,
    required this.index,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller; // For entrance
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Simple hover animation logic could happen here, 
    // but we want entrance animation too.
    // However, for this snippet let's keep it simple and just do hover scaling
    // effectively, assuming list is already visible or using a simple delay.
    // Actually, let's just do hover here.
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            final appState = Provider.of<AppState>(context, listen: false);
            appState.setSelectedTab(1, category: widget.category);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..translate(0, _isHovered ? -5 : 0),
            decoration: BoxDecoration(
              color: Colors.black, // Default bg
              image: widget.imageUrl != null ? DecorationImage(
                image: widget.imageUrl!.startsWith('data:') 
                  ? MemoryImage(base64Decode(widget.imageUrl!.split(',').last)) as ImageProvider
                  : NetworkImage(widget.imageUrl!.startsWith('http') 
                     ? widget.imageUrl! 
                     : "${AppConstants.apiUrl.endsWith('/api') ? AppConstants.apiUrl.substring(0, AppConstants.apiUrl.length-4) : AppConstants.apiUrl}${widget.imageUrl!.startsWith('/') ? '' : '/'}${widget.imageUrl}"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken),
              ) : null,
              gradient: widget.imageUrl == null ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.gradient,
              ) : null,
              borderRadius: BorderRadius.zero, // Sharp edges
              boxShadow: [
                 if (_isHovered)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  )
              ],
            ),
            child: Stack(
              children: [
                // Icon huge in background (only if no image, or make subtle)
                if (widget.imageUrl == null)
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    widget.icon,
                    size: 120,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: widget.isMobile ? 24 : 28,
                          ),
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.isMobile ? 16 : 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.productCount} Items',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
