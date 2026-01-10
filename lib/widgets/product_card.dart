import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/models/product.dart';
import 'package:thameeha/theme/themes.dart';
import 'package:thameeha/screens/product_detail_screen.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool showBadges;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showBadges = true,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  bool _isWishlisted = false;
  bool _isAddingToCart = false;
  bool _isAdded = false;
  
  // Variant Selection State
  bool _showVariants = false;
  int _currentVariantIndex = 0;
  final Map<String, dynamic> _selectedOptions = {};
  
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heartScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _toggleWishlist() {
    setState(() {
      _isWishlisted = !_isWishlisted;
    });
    
    if (_isWishlisted) {
      _heartController.forward().then((_) => _heartController.reverse());
    }
  }

  void _startAddToCart() {
    if (widget.product.variants.isNotEmpty) {
      setState(() {
        _showVariants = true;
         _currentVariantIndex = 0;
         _selectedOptions.clear();
      });
    } else {
      _executeAddToCart();
    }
  }

  void _selectOption(String variantName, dynamic option) {
    setState(() {
      _selectedOptions[variantName] = option;
    });

    if (_currentVariantIndex < widget.product.variants.length - 1) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if(mounted) setState(() => _currentVariantIndex++);
      });
    } else {
      _executeAddToCart();
    }
  }
  
  void _cancelVariantSelection() {
    setState(() {
      _showVariants = false;
      _currentVariantIndex = 0;
      _selectedOptions.clear();
    });
  }

  Future<void> _executeAddToCart() async {
    setState(() {
      _isAddingToCart = true;
      _showVariants = false; 
    });
    
    final appState = Provider.of<AppState>(context, listen: false);
    try {
      Map<String, dynamic>? finalOptions;
      if (widget.product.variants.isNotEmpty) {
         finalOptions = Map<String, dynamic>.from(_selectedOptions);
      }

      await appState.addToCart(widget.product.id, 1, selectedOptions: finalOptions);
      
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
          _isAdded = true;
        });
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isAdded = false);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppTheme.errorRed),
        );
        setState(() => _isAddingToCart = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currency = appState.currencySymbol;
    final isOutOfStock = widget.product.stockQuantity == 0;
    
    // Variant Info Extraction
    String currentVariantName = '';
    List<dynamic> currentOptions = [];
    
    if (widget.product.variants.isNotEmpty && _currentVariantIndex < widget.product.variants.length) {
      try {
        var rawV = widget.product.variants[_currentVariantIndex];
        // Simplified Logic for brevity (assuming same parsing logic as before)
        if (rawV is String) try { rawV = jsonDecode(rawV); } catch (_) {}
        if (rawV is Map) {
           final v = Map<String, dynamic>.from(rawV);
           currentVariantName = v['name']?.toString() ?? 'Option';
           final opts = v['values'] ?? v['options'];
           if (opts is List) currentOptions = List.from(opts);
           else if (opts is String) try { final d = jsonDecode(opts); if (d is List) currentOptions = List.from(d); } catch (_) {}
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: widget.onTap ?? () {
        if (widget.product.isAdvertised) {
           Provider.of<AppState>(context, listen: false).apiService.trackProductMetric(widget.product.id, 'clicks');
        }
        Navigator.of(context).pushNamed(
          '/shop/${widget.product.id}',
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Card Area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                   BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double overlayHeight = constraints.maxHeight;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image
                        widget.product.image != null && widget.product.image!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.product.image!,
                                fit: BoxFit.cover,
                                placeholder: (c, u) => Container(color: Colors.grey[100]),
                                errorWidget: (c, u, e) => const Icon(Icons.broken_image),
                              )
                            : Container(color: Colors.grey[100], child: const Icon(Icons.image)),
                        
                        // Gradient Overlay
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.name,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$currency${appState.getPrice(widget.product.displayPrice).toStringAsFixed(2)} / ${widget.product.formattedUnit}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                if (widget.product.reviewCount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Row(
                                      children: [
                                         const Icon(Icons.star, color: Colors.amber, size: 10),
                                         const SizedBox(width: 2),
                                         Text(
                                           "${widget.product.averageRating.toStringAsFixed(1)} (${widget.product.reviewCount})",
                                           style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                         )
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Badges
                        if (widget.showBadges)
                        Positioned(
                          top: 8, left: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isOutOfStock) _buildBadge('SOLD OUT', Colors.red),
                              if (widget.product.isNewArrival == true) _buildBadge('NEW', Colors.black),
                              if (widget.product.isTrending == true) _buildBadge('TRENDING', Colors.blueGrey),
                            ],
                          ),
                        ),

                        // Variant Overlay (Fixed Logic)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          left: 0, 
                          right: 0,
                          top: _showVariants ? 0 : overlayHeight,
                          height: overlayHeight,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                            ),
                            child: Column(
                              children: [
                                 // Header
                                 Container(
                                   padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                                   decoration: BoxDecoration(
                                     color: Theme.of(context).cardColor,
                                     border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
                                     boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                                     ]
                                   ),
                                   child: Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Expanded(
                                         child: Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                             Text(
                                               "Select ${_capitalize(currentVariantName)}", 
                                               style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                 fontWeight: FontWeight.bold,
                                                 fontSize: 14
                                               ),
                                               maxLines: 1, overflow: TextOverflow.ellipsis,
                                             ),
                                           ],
                                         ),
                                       ),
                                       Material(
                                         color: Colors.transparent,
                                         child: InkWell(
                                           onTap: _cancelVariantSelection,
                                           borderRadius: BorderRadius.circular(50),
                                           child: Container(
                                             padding: const EdgeInsets.all(6),
                                             decoration: BoxDecoration(
                                                color: Theme.of(context).dividerColor.withOpacity(0.1),
                                                shape: BoxShape.circle
                                             ),
                                             child: const Icon(Icons.close, size: 18),
                                           ),
                                         ),
                                       )
                                     ],
                                   ),
                                 ),
                                 
                                 // Content
                                 Expanded(
                                   child: SingleChildScrollView(
                                     physics: const BouncingScrollPhysics(),
                                     padding: const EdgeInsets.all(16),
                                     child: Center(
                                       child: Wrap(
                                         spacing: 8, runSpacing: 8,
                                         alignment: WrapAlignment.center,
                                         children: currentOptions.map((opt) {
                                           return Material(
                                             color: Colors.transparent,
                                             child: InkWell(
                                               onTap: () => _selectOption(currentVariantName, opt),
                                               borderRadius: BorderRadius.circular(10),
                                               child: AnimatedContainer(
                                                 duration: const Duration(milliseconds: 200),
                                                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                 decoration: BoxDecoration(
                                                   color: Theme.of(context).canvasColor,
                                                   borderRadius: BorderRadius.circular(10),
                                                   border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2), width: 1),
                                                   boxShadow: [
                                                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                                                   ]
                                                 ),
                                                 child: Text(
                                                   opt.toString(),
                                                   style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                 ),
                                               ),
                                             ),
                                           );
                                         }).toList(),
                                       ),
                                     ),
                                   ),
                                 )
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Outer Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.product.category.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _toggleWishlist,
                    child: ScaleTransition(
                      scale: _heartScale,
                      child: Icon(
                        _isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: _isWishlisted ? Colors.red : Colors.grey[800],
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: isOutOfStock || _isAddingToCart || _isAdded ? null : _startAddToCart,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isAddingToCart
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : _isAdded
                              ? const Icon(Icons.check, size: 20, color: Colors.green)
                              : const Icon(Icons.add_shopping_cart, size: 20, color: Colors.black),
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
