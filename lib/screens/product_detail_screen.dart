import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/models/product.dart';
import 'package:thameeha/models/review.dart';
import 'package:thameeha/theme/themes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thameeha/widgets/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;
  
  // State for variant selection:  {'Color': 'Red', 'Size': 'M'}
  final Map<String, String> _selectedOptions = {};
  
  // State for current images to display (defaults to null -> shows product default images)
  List<String>? _forcedImages;

  late PageController _pageController;
  List<Review> _reviews = [];
  bool _isLoadingReviews = true;
  PageController _reviewPageController = PageController();
  int _currentReviewPage = 0;
  bool _canReview = false;
  bool _isReviewExpanded = false;
  bool _showAllReviews = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _loadData();
    });
  }

  Future<void> _loadData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // 1. Fetch Reviews
    final reviews = await appState.fetchReviews(widget.productId);
    
    // 2. Check Verification
    bool canReview = await appState.checkReviewEligibility(widget.productId);

    if (mounted) {
      setState(() {
        _reviews = reviews;
        _canReview = canReview;
        _isLoadingReviews = false;
      });
      
      // Track visits
      final product = appState.getProductById(widget.productId);
      if (product != null) {
          appState.addToRecentlyViewed(product);
          if (product.isAdvertised) {
             appState.apiService.trackProductMetric(product.id, 'visits');
          }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) async {
    // Validate variant selection
    for (var variant in product.variants) {
      if (variant is Map) {
        final name = variant['name'] as String? ?? '';
        final values = variant['values'];
        
        // Only require selection if the variant has a name AND actual values to choose from
        if (name.isNotEmpty && values is List && values.isNotEmpty) {
          if (!_selectedOptions.containsKey(name)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please select a $name')),
            );
            return;
          }
        }
      }
    }

    // Validate stock availability
    final availableStock = _getCurrentStock(product);
    if (_quantity > availableStock) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only $availableStock units available'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    try {
      final price = _getCurrentPrice(product);
      // Pass a copy to prevent reference issues and null if empty to be consistent with backend nullable column
      final optionsToPass = _selectedOptions.isEmpty ? null : Map<String, dynamic>.from(_selectedOptions);
      
      await Provider.of<AppState>(context, listen: false).addToCart(
        product.id, 
        _quantity,
        selectedOptions: optionsToPass,
        price: price
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to cart successfully!'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _handleVariantSelection(Product product, String variantName, String value) {
    setState(() {
      // 1. Update Selection
      if (_selectedOptions[variantName] == value) {
        _selectedOptions.remove(variantName); // Deselect if tapped again
      } else {
        _selectedOptions[variantName] = value;
      }

      // 2. Update Images based on the specific value selected (e.g. "Red")
      // product.variantImages is Map<String, dynamic> where value is List<String>
      if (_selectedOptions.containsKey(variantName) && 
          product.variantImages.containsKey(value)) {
        
        final imgs = product.variantImages[value];
        if (imgs is List && imgs.isNotEmpty) {
           _forcedImages = List<String>.from(imgs);
           _currentImageIndex = 0;
           if (_pageController.hasClients) {
             _pageController.jumpToPage(0);
           }
        }
      } else {
        // If the newly selected option doesn't have specific images, 
        // we might want to keep current images OR revert if NO active selection has images.
        // For simplicity: If the *current* selection has no images, revert to default.
        // Check if ANY currently selected option has images? 
        // Usually, Color is the one with images.
        // Let's loop selected options:
        bool foundVariantImages = false;
        for (var val in _selectedOptions.values) {
           if (product.variantImages.containsKey(val)) {
              final imgs = product.variantImages[val];
              if (imgs is List && imgs.isNotEmpty) {
                 _forcedImages = List<String>.from(imgs);
                 _currentImageIndex = 0;
                 if (_pageController.hasClients) _pageController.jumpToPage(0);
                 foundVariantImages = true;
                 break; // Prioritize the first found one
              }
           }
        }
        
        if (!foundVariantImages) {
          _forcedImages = null; // Revert to default
        }
      }
    });
  }

  void _showAddReviewDialog() {
    final commentController = TextEditingController();
    int rating = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: AppTheme.warningOrange,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Share your thoughts...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await Provider.of<AppState>(context, listen: false)
                      .addReview(widget.productId, rating, commentController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadData(); // Refresh reviews
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review submitted successfully!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  double _getCurrentPrice(Product product) {
    if (product.variants.isEmpty) return product.price;

    List<String> keyParts = [];
    bool allSelected = true;

    for (var variant in product.variants) {
       if (variant is Map) {
          String name = variant['name'] ?? '';
          if (name.isNotEmpty) {
             if (_selectedOptions.containsKey(name)) {
                keyParts.add(_selectedOptions[name]!);
             } else {
                allSelected = false;
                break;
             }
          }
       }
    }

    if (allSelected) {
       String key = keyParts.join('-');
       if (product.variantPrices.containsKey(key)) {
          return product.variantPrices[key]!;
       }
    }
    
    return product.price;
  }

  int _getCurrentStock(Product product) {
    // If no variants, return global stock
    if (product.variants.isEmpty) return product.stockQuantity;

    // Build variant key from selections
    List<String> keyParts = [];
    bool allSelected = true;

    for (var variant in product.variants) {
       if (variant is Map) {
          String name = variant['name'] ?? '';
          if (name.isNotEmpty) {
             if (_selectedOptions.containsKey(name)) {
                keyParts.add(_selectedOptions[name]!);
             } else {
                allSelected = false;
                break;
             }
          }
       }
    }

    // If all variants selected, check variant-specific stock
    if (allSelected && keyParts.isNotEmpty) {
       String key = keyParts.join('-');
       if (product.variantStocks.containsKey(key)) {
          return product.variantStocks[key]!;
       }
    }
    
    // Fallback to global stock
    return product.stockQuantity;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final product = appState.getProductById(widget.productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Not Found')),
        body: const Center(child: Text('Product not found')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          return _buildDesktopLayout(context, product, appState);
        }
        return _buildMobileLayout(context, product, appState);
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Product product, AppState appState) {
    // Determine which images to show
    List<String> displayImages = _getDisplayImages(product);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Go Back", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Hide default back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Images
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      // Main Image
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                onPageChanged: (index) => setState(() => _currentImageIndex = index),
                                itemCount: displayImages.length,
                                itemBuilder: (context, index) {
                                  return CachedNetworkImage(
                                    imageUrl: displayImages[index],
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[300])),
                                    errorWidget: (context, url, error) => Image.asset('assets/placeholder.png', fit: BoxFit.contain),
                                  );
                                },
                              ),
                              if (displayImages.length > 1) ...[
                                Positioned(
                                  left: 8,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                                      ),
                                      onPressed: () {
                                        _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                                        child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                                      ),
                                      onPressed: () {
                                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Thumbnails
                      if (displayImages.length > 1)
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: displayImages.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final isSelected = _currentImageIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                },
                                child: Container(
                                  width: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: CachedNetworkImage(
                                      imageUrl: displayImages[index],
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[300])),
                                      errorWidget: (_, __, ___) => const Icon(Icons.image),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                // Right Column: Details
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // Title & Stock
                        Row(
                          children: [
                            Expanded(child: Text(product.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getCurrentStock(product) > 0 ? AppTheme.successGreen.withOpacity(0.1) : AppTheme.errorRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getCurrentStock(product) > 0 
                                   ? (_getCurrentStock(product) < 10 ? 'Only ${_getCurrentStock(product)} Left' : 'In Stock') 
                                   : 'Out of Stock',
                                style: TextStyle(
                                  color: _getCurrentStock(product) > 0 ? AppTheme.successGreen : AppTheme.errorRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (product.purchasesLastMonth > 0)
                           Padding(
                             padding: const EdgeInsets.only(top: 4),
                             child: Text("${product.purchasesLastMonth}+ bought in past month", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                           ),
                        const SizedBox(height: 8),
                        // Rating
                        Row(
                          children: [
                             const Icon(Icons.star, color: AppTheme.warningOrange, size: 20),
                             Text(
                                _reviews.isNotEmpty
                                    ? (_reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length).toStringAsFixed(1)
                                    : 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                             ),
                             const SizedBox(width: 8),
                             Text('(${_reviews.length} reviews)', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Price
                        Text(
                          '${appState.currencySymbol}${appState.getPrice(_getCurrentPrice(product)).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple),
                        ),
                        const SizedBox(height: 32),
                        
                        // Specs/Description
                        Text(product.description, style: TextStyle(fontSize: 16, height: 1.6, color: Colors.grey.shade700)),
                        const SizedBox(height: 32),

                        // Specs Grid
                         if (product.specifications.isNotEmpty) ...[
                             Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: product.specifications.entries.map((e) => 
                                     Padding(
                                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                       child: Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: [
                                           Text(e.key, style: const TextStyle(color: Colors.grey)), 
                                           Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.w600))
                                         ],
                                       ),
                                     )
                                  ).toList(),
                                ),
                             ),
                             const SizedBox(height: 32),
                         ],

                        // Options
                        if (product.variants.isNotEmpty) ...[
                          _buildVariantsSection(product),
                          const SizedBox(height: 32),
                        ],
                        
                        // Add to Cart Row
                        Row(
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(onPressed: () => _quantity > 1 ? setState(()=>_quantity--) : null, icon: const Icon(Icons.remove)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                    IconButton(onPressed: () => _quantity < _getCurrentStock(product) ? setState(()=>_quantity++) : null, icon: const Icon(Icons.add)),
                                  ],
                                ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _getCurrentStock(product) > 0 ? () => _addToCart(product) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 22),
                                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  elevation: 0,
                                ),
                                child: const Text('Add to Cart'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
             const SizedBox(height: 60),
             _buildReviewsSection(context, appState),
             const SizedBox(height: 60),
             _buildProductListSection("Similar Products", (() {
                   final list = appState.products.where((p) => p.category == product.category && p.id != product.id).toList();
                   list.sort((a,b) {
                     if (a.isAdvertised && !b.isAdvertised) return -1;
                     if (!a.isAdvertised && b.isAdvertised) return 1;
                     return 0;
                   });
                   return list.take(10).toList();
               })(), context),
             const SizedBox(height: 40),
             _buildProductListSection("Recently Viewed", appState.recentlyViewed.where((p) => p.id != product.id).take(10).toList(), context),
             const SizedBox(height: 40),
           ],
         ),
       ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, Product product, AppState appState) {
    List<String> displayImages = _getDisplayImages(product);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(product, displayImages, appState),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.lightBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ... (Existing Mobile Layout Content)
                   Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A2E),
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getCurrentStock(product) > 0
                                    ? AppTheme.successGreen.withOpacity(0.1)
                                    : AppTheme.errorRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getCurrentStock(product) > 0 
                                   ? (_getCurrentStock(product) < 10 ? '${_getCurrentStock(product)} Left' : 'In Stock') 
                                   : 'Out of Stock',
                                style: TextStyle(
                                  color: _getCurrentStock(product) > 0
                                      ? AppTheme.successGreen
                                      : AppTheme.errorRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (product.purchasesLastMonth > 0)
                           Padding(
                             padding: const EdgeInsets.only(top: 4, bottom: 4),
                             child: Text("${product.purchasesLastMonth}+ bought in past month", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                           ),
                        // ... (Rest of existing mobile UI logic, simplified for brevity in this replacement)
                        // I will inline the rest of the existing logic to ensure it works
                        const SizedBox(height: 8),
                         Row(
                          children: [
                            Text(
                              '${appState.currencySymbol}${appState.getPrice(_getCurrentPrice(product)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryPurple,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.star, color: AppTheme.warningOrange, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              _reviews.isNotEmpty
                                  ? (_reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length).toStringAsFixed(1)
                                  : 'N/A',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Text('(${_reviews.length} reviews)', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        if (product.variants.isNotEmpty) ...[
                          _buildVariantsSection(product),
                          const SizedBox(height: 12),
                        ],

                        const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text(product.description, style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.6)),
                         const SizedBox(height: 24),
                         
                         if (product.specifications.isNotEmpty) ...[
                          const Text('Specifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: product.specifications.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(width: 120, child: Text(entry.key, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade600))),
                                      Expanded(child: Text(entry.value.toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        _buildReviewsSection(context, appState),
                        const SizedBox(height: 48),
                        _buildProductListSection("Similar Products", (() {
                            final list = appState.products.where((p) => p.category == product.category && p.id != product.id).toList();
                            list.sort((a,b) {
                              if (a.isAdvertised && !b.isAdvertised) return -1;
                              if (!a.isAdvertised && b.isAdvertised) return 1;
                              return 0;
                            });
                            return list.take(10).toList();
                        })(), context),
                        const SizedBox(height: 32),
                        _buildProductListSection("Recently Viewed", appState.recentlyViewed.where((p) => p.id != product.id).take(10).toList(), context),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
        child: SafeArea(top: false, child: Row(
            children: [
              Container(
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                    IconButton(onPressed: () => _quantity > 1 ? setState(()=>_quantity--) : null, icon: const Icon(Icons.remove), color: AppTheme.primaryPurple),
                    Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => _quantity < _getCurrentStock(product) ? setState(()=>_quantity++) : null, icon: const Icon(Icons.add), color: AppTheme.primaryPurple),
                ]),
              ),
              const SizedBox(width: 16),
              Expanded(child: ElevatedButton(onPressed: _getCurrentStock(product) > 0 ? () => _addToCart(product) : null, 
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Add to Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
            ],
        )),
      ),
    );
  }

  // Refactored Helper for Variants with Larger UI
  Widget _buildVariantsSection(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          const Text('Select Configuration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...product.variants.map((v) {
            if (v is! Map) return const SizedBox();
            final variant = Map<String, dynamic>.from(v);
            final String name = variant['name'] ?? '';
            final List values = variant['values'] is List ? variant['values'] : [];
            if (name.isEmpty || values.isEmpty) return const SizedBox();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.2, fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: values.map((val) {
                    final String valueStr = val.toString();
                    final bool isSelected = _selectedOptions[name] == valueStr;
                    return GestureDetector(
                      onTap: () => _handleVariantSelection(product, name, valueStr),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Larger Padding
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryPurple : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade300, width: 2),
                          boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryPurple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                        ),
                        child: Text(
                          valueStr, 
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87, 
                            fontWeight: FontWeight.bold,
                            fontSize: 16 // Larger Font
                          )
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
      ],
    );
  }

  Widget _buildReviewsSection(BuildContext context, AppState appState) {
    if (_reviews.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             const Text("Ratings & Reviews", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             Container(
               padding: const EdgeInsets.all(32),
               width: double.infinity,
               decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
               child: Column(
                 children: [
                    const Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text("No reviews yet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Be the first to share your thoughts on this product!", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    if (appState.isAuthenticated && _canReview)
                      ElevatedButton(
                        onPressed: _showAddReviewDialog,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, foregroundColor: Colors.white),
                        child: const Text("Write a Review"),
                      ),
                    if (appState.isAuthenticated && !_canReview)
                       const Text("Only verified purchasers can write verification reviews.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                 ],
               ),
             )
          ],
        );
    }

    // Calculate Stats
    int total = _reviews.length;
    double average = total > 0 ? _reviews.map((r) => r.rating).reduce((a, b) => a + b) / total : 0.0;
    Map<int, int> ratingDist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    
    // Check for user review
    bool userHasReviewed = false; 
    // final userId = appState.currentUser?.id;
    // if (userId != null && _reviews.any((r) => r.userId == userId)) userHasReviewed = true; 

    for (var r in _reviews) {
      int rInt = r.rating.round();
      if (rInt > 5) rInt = 5; if (rInt < 1) rInt = 1;
      if (ratingDist.containsKey(rInt)) ratingDist[rInt] = ratingDist[rInt]! + 1;
    }

    // Filter Highlighted Reviews
    List<Review> highlightedReviews = [];
    if (!_showAllReviews) {
      final positive = _reviews.where((r) => r.rating >= 4).toList()
        ..sort((a, b) => b.rating.compareTo(a.rating)); // Highest first
      final critical = _reviews.where((r) => r.rating <= 3).toList()
        ..sort((a, b) => a.rating.compareTo(b.rating)); // Lowest first
      
      highlightedReviews.addAll(positive.take(3));
      if (critical.isNotEmpty) {
        highlightedReviews.add(critical.first);
      }
      
      // If we don't have enough positives/criticals to fill 4 slots, just fill with whatever is left (optional logic, but sticking to specific requirement first)
      // Actually, if total reviews > 4 but we have < 4 highlighted (e.g. all positive), we should probably show more positives.
      // But the requirement says "Top 3 positive and 1 critical".
      // Let's strictly follow "Top 3 positive and 1 critical" as the "Highlight" view.
      // If there are no critical reviews, we show up to 3 positives.
      // If there are no positive reviews, we show up to 1 critical? That seems meager.
      // Let's make it a bit smart: "Up to 3 positive" + "Up to 1 critical".
    }
    
    // Determine which list to show
    final reviewsToShow = _showAllReviews ? _reviews : highlightedReviews;
    if (reviewsToShow.isEmpty && !_showAllReviews && _reviews.isNotEmpty) {
        // Fallback if highlight logic yields nothing (e.g. all neutrals if we defined that way, but 3 is critical here)
        // If simply no matches for specific logic, just show first few.
        reviewsToShow.addAll(_reviews.take(3)); 
    }


    // Horizontal Review List
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ratings & Reviews", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        
        // Rating Statistics Card (Unchanged logic, just keeping it here for context if needed, but the replace mainly targets the list part)
        // ... (The passed context included the stats card, so I must include it or target below it. 
        // actually looking at lines 885-1074, it includes the header and stats. I should keep stats and replace the list part.)
        
        // Since I can't partially match easily with large blocks, I'll reconstruct the method to render the stats AND the new horizontal list.
        
        // Rating Statistics Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
               bool isSmall = constraints.maxWidth < 400;
               final barsColumn = Column(
                 children: [5, 4, 3, 2, 1].map((stars) {
                   int count = ratingDist[stars] ?? 0;
                   double percent = total > 0 ? count / total : 0.0;
                   Color color = stars >= 4 ? AppTheme.successGreen : (stars == 3 ? AppTheme.warningOrange : AppTheme.errorRed);
                   
                   return Padding(
                     padding: const EdgeInsets.symmetric(vertical: 4),
                     child: Row(
                       children: [
                         SizedBox(
                           width: 12,
                           child: Text("$stars", style: const TextStyle(fontWeight: FontWeight.bold)),
                         ),
                         const SizedBox(width: 4),
                         const Icon(Icons.star, size: 12, color: Colors.grey),
                         const SizedBox(width: 8),
                         Expanded(
                           child: ClipRRect(
                             borderRadius: BorderRadius.circular(4),
                             child: LinearProgressIndicator(
                               value: percent,
                               backgroundColor: Colors.grey.shade100,
                               color: color,
                               minHeight: 8,
                             ),
                           ),
                         ),
                         const SizedBox(width: 12),
                         SizedBox(
                           width: 24,
                           child: Text("$count", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                         ),
                       ],
                     ),
                   );
                 }).toList(),
               );

               return Flex(
                 direction: isSmall ? Axis.vertical : Axis.horizontal,
                 children: [
                    // Left: Big Number
                    Column(
                      children: [
                        Text(average.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (i) => Icon(i < average.round() ? Icons.star : Icons.star_border, color: AppTheme.warningOrange, size: 20))
                        ),
                        const SizedBox(height: 8),
                        Text("$total reviews", style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                    if (isSmall) const SizedBox(height: 24) else const SizedBox(width: 32),
                    // Right: Bars
                    if (isSmall) 
                       barsColumn 
                    else 
                       Expanded(child: barsColumn),
                 ],
               );
            }
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Write/Edit Review Button
        if (appState.isAuthenticated && _canReview)
          SizedBox(
             width: double.infinity,
             child: OutlinedButton.icon(
                onPressed: _showAddReviewDialog,
                icon: Icon(userHasReviewed ? Icons.edit : Icons.rate_review),
                label: Text(userHasReviewed ? "Edit Your Review" : "Write a Review"),
                style: OutlinedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   side: BorderSide(color: Colors.grey.shade300),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
             ),
          ),
        
        if (appState.isAuthenticated && !_canReview)
           Container(
             width: double.infinity,
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
             child: const Text("You can review this product after you purchase and receive it.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
           ),
          
        const SizedBox(height: 32),

        // Horizontal Review List
        if (reviewsToShow.isNotEmpty) ...[
          const Text("Customer Reviews", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 220, // Fixed height for the horizontal list
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: reviewsToShow.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final review = reviewsToShow[index];
                return Container(
                  width: 300, // Fixed width for each review card
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                         children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: _getAvatarColor(review.username),
                              child: Text(review.username.isNotEmpty ? review.username[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                     Text(review.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                     Row(
                                       children: [
                                         Icon(Icons.star, size: 14, color: AppTheme.warningOrange),
                                         const SizedBox(width: 4),
                                         Text("${review.rating}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                         const Spacer(),
                                         Text(
                                            "${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}", 
                                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)
                                         ),
                                       ],
                                     ),
                                 ],
                              )
                            )
                         ],
                       ),
                       const Divider(height: 24),
                       Expanded(
                         child: SingleChildScrollView( // Allow scrolling text inside the card if too long
                           child: Text(
                             review.comment ?? "", 
                             style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 14),
                           ),
                         ),
                       ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Color _getAvatarColor(String name) {
     if (name.isEmpty) return Colors.blue;
     final colors = [Colors.blue, Colors.green, Colors.purple, Colors.orange, Colors.teal, Colors.indigo];
     return colors[name.codeUnitAt(0) % colors.length];
  }

  // Helper to get image list
  List<String> _getDisplayImages(Product product) {
    List<String> displayImages = [];
    if (_forcedImages != null && _forcedImages!.isNotEmpty) {
      displayImages = _forcedImages!;
    } else {
      if (product.image != null && product.image!.isNotEmpty) displayImages.add(product.image!);
      displayImages.addAll(product.images);
    }
    if (displayImages.isEmpty && product.image != null) displayImages.add(product.image!);
    return displayImages;
  }
  
  Widget _buildCartIcon(BuildContext context, AppState appState) {
     final cartItemCount = appState.cartItems.length;
     return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                // Ensure reliable navigation
                Navigator.of(context).popUntil((route) => route.isFirst);
                Provider.of<AppState>(context, listen: false).setSelectedTab(2);
              },
            ),
            if (cartItemCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppTheme.errorRed, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text('$cartItemCount', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                ),
              ),
          ],
        );
  }

  Widget _buildSliverAppBar(Product product, List<String> images, AppState appState) {
    return SliverAppBar(
      expandedHeight: 400.0,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.primaryPurple,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        // Cart icon with badge - Using consistent navigation
        Consumer<AppState>( // Re-wrapping in consumer or using passed appState
           builder: (context, state, _) {
              // We can use the passed appState but Consumer ensures updates if state changes while viewing
              return Stack(
                children: [
                   IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_cart, color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      Provider.of<AppState>(context, listen: false).setSelectedTab(2);
                    },
                  ),
                  if (state.cartItems.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.errorRed,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          state.cartItems.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
           }
        ),
        Consumer<AppState>( // Reactive heart icon
           builder: (context, state, _) {
             final isWishlisted = state.isWishlisted(product.id);
             return IconButton(
               icon: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: Colors.black.withOpacity(0.3),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(
                   isWishlisted ? Icons.favorite : Icons.favorite_border, 
                   color: isWishlisted ? Colors.red : Colors.white
                 ),
               ),
               onPressed: () => state.toggleWishlist(product.id),
             );
           }
        ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.white), // Background for gaps
            images.isNotEmpty
                ? PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return index == 0 && _forcedImages == null // Only hero transition for default image
                          ? Hero(
                              tag: 'product-${product.id}',
                              child: CachedNetworkImage(
                                imageUrl: images[index],
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[300])),
                                errorWidget: (context, url, error) =>
                                    Image.asset('assets/placeholder.png', fit: BoxFit.contain),
                              ),
                            )
                          : CachedNetworkImage(
                                imageUrl: images[index],
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[300])),
                                errorWidget: (context, url, error) =>
                                    Image.asset('assets/placeholder.png', fit: BoxFit.contain),
                            );
                    },
                  )
                : Image.asset('assets/placeholder.png', fit: BoxFit.contain),
            
            if (images.length > 1) ...[
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    ),
                    onPressed: () {
                      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                    ),
                    onPressed: () {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                  ),
                ),
              ),
            ],
            
            // Image indicators
            if (images.length > 1)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (index) {
                    return Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    );
                  }),
                ),
              ),
              
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildProductListSection(String title, List<Product> products, BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final ScrollController scrollController = ScrollController();
    bool isDesktop = MediaQuery.of(context).size.width >= 1200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
               Row(
                 children: [
                   IconButton(
                     icon: const Icon(Icons.arrow_back_ios, size: 16),
                     onPressed: () {
                       scrollController.animateTo(
                         scrollController.offset - 300,
                         duration: const Duration(milliseconds: 300),
                         curve: Curves.easeOut,
                       );
                     },
                   ),
                   IconButton(
                     icon: const Icon(Icons.arrow_forward_ios, size: 16),
                     onPressed: () {
                       scrollController.animateTo(
                         scrollController.offset + 300,
                         duration: const Duration(milliseconds: 300),
                         curve: Curves.easeOut,
                       );
                     },
                   ),
                 ],
               ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text("Click arrows or swipe to see more", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        
        SizedBox(
          height: 280, 
          child: ListView.separated(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (ctx, i) => const SizedBox(width: 16),
            itemBuilder: (ctx, index) {
              return SizedBox(
                width: 180,
                child: ProductCard(
                  product: products[index],
                  showBadges: true,
                  onTap: () {
                     Navigator.of(context).pushNamed(
                        '/shop/${products[index].id}',
                     );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
