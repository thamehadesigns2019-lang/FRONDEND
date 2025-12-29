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
                child: Stack(
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

                    // Variant Overlay (Slides Up)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      left: 0, right: 0,
                      bottom: _showVariants ? 0 : -300,
                      height: 200,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: const Border(top: BorderSide(color: Colors.black, width: 3)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                             Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                               Text("Select ${_capitalize(currentVariantName)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                               GestureDetector(onTap: _cancelVariantSelection, child: const Icon(Icons.close, size: 18))
                             ]),
                             const SizedBox(height: 8),
                             Expanded(
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 4, runSpacing: 4,
                                  children: currentOptions.map((opt) {
                                    return GestureDetector(
                                      onTap: () => _selectOption(currentVariantName, opt),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(border: Border.all(color: Colors.black)),
                                        child: Text(opt.toString(), style: const TextStyle(fontSize: 10)),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                             ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
