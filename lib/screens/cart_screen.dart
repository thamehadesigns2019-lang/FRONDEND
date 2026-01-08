import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/models/cart_item.dart';
import 'package:thameeha/models/product.dart';
import 'package:thameeha/theme/themes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thameeha/widgets/product_card.dart';
import 'package:thameeha/screens/product_detail_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          if (appState.cartItems.isEmpty) {
            return _buildEmptyCart(context, appState);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1100) {
                return _buildDesktopLayout(context, appState);
              }
              // Improved Mobile + Tablet handling
              return Center(
                child: ConstrainedBox(
                   constraints: const BoxConstraints(maxWidth: 700), // Max width for tablet readability
                   child: _buildMobileLayout(context, appState),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, AppState appState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Center(
              child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shopping_bag_outlined, size: 80, color: AppTheme.primaryPurple),
                ),
                const SizedBox(height: 32),
                Text(
                  'Your cart is empty',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Looks like you haven\'t added anything yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey.shade600
                      ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                     Navigator.of(context).pushReplacementNamed('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: const Text('START SHOPPING', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ],
            ),
          )),
          const SizedBox(height: 60),
          
          if (appState.recentlyViewed.isNotEmpty)
             Padding(
               padding: const EdgeInsets.only(left: 24.0, bottom: 40),
               child: _buildProductListSection("Recently Viewed", appState.recentlyViewed.take(10).toList(), context),
             ),

          if (appState.wishlistProducts.isNotEmpty)
             Padding(
               padding: const EdgeInsets.only(left: 24.0, bottom: 40),
               child: _buildProductListSection("Your Wishlist", appState.wishlistProducts, context),
             ),
             
          // Fallback if both empty
          if (appState.recentlyViewed.isEmpty && appState.wishlistProducts.isEmpty)
             Padding(
               padding: const EdgeInsets.only(left: 24.0, bottom: 40),
               child: _buildProductListSection("Recommended for You", appState.products.take(5).toList(), context),
             ),
             
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProductListSection(String title, List<Product> products, BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Padding(
           padding: const EdgeInsets.only(bottom: 16),
           child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
         ),
         SizedBox(
           height: 280,
           child: ListView.separated(
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
                      Navigator.of(context).push(
                         MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: products[index].id))
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

  Widget _buildDesktopLayout(BuildContext context, AppState appState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Cart Items
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 28, color: Theme.of(context).iconTheme.color),
                          const SizedBox(width: 12),
                          Text('Your Cart (${appState.cartItems.length} items)', 
                             style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: appState.cartItems.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 24),
                        itemBuilder: (context, index) {
                          return _CartItemCard(
                            item: appState.cartItems[index],
                            currencySymbol: appState.currencySymbol,
                            appState: appState,
                            isDesktop: true,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 60),
                // Right: Summary
                SizedBox(
                  width: 400,
                  child: Column(
                    children: [
                       _buildOrderSummary(context, appState),
                       const SizedBox(height: 40),
                       _buildProtectionBadge(context),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            _RecentlyPurchasedSection(appState: appState),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppState appState) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text('Cart (${appState.cartItems.length})', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          centerTitle: false,
          pinned: true,
          automaticallyImplyLeading: false, // Hide back button if it's a tab
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                 return Padding(
                   padding: const EdgeInsets.only(bottom: 16),
                   child: _CartItemCard(
                      item: appState.cartItems[index],
                      currencySymbol: appState.currencySymbol,
                      appState: appState,
                      isDesktop: false,
                   ),
                 );
              },
              childCount: appState.cartItems.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                 _buildOrderSummary(context, appState),
                 const SizedBox(height: 24),
                 _buildProtectionBadge(context),
                 const SizedBox(height: 48),
                 _RecentlyPurchasedSection(appState: appState),
                 const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(BuildContext context, AppState appState) {
    final subtotal = appState.cartItems.fold(0.0, (sum, item) {
       final product = appState.getProductById(item.productId);
       final priceWithTax = product != null ? product.getPriceWithTax(item.price) : item.price;
       return sum + (appState.getPrice(priceWithTax) * item.quantity);
    });
    final total = subtotal;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _SummaryRow(label: 'Subtotal', value: '${appState.currencySymbol}${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Shipping', value: 'Calculated at checkout', isFaded: true), // Placeholder text
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text("Total", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${appState.currencySymbol}${total.toStringAsFixed(2)}', 
                   style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryPurple)),
            ],
          ),
          const SizedBox(height: 8),
           Text("Tax included.", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: appState.isAuthenticated
                  ? () {
                      Navigator.of(context).pushNamed('/checkout');
                    }
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Please login to checkout')),
                      );
                      Navigator.of(context).pushNamed('/login');
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                shadowColor: AppTheme.primaryPurple.withOpacity(0.3),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text('CHECKOUT', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                   SizedBox(width: 8),
                   Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionBadge(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
           color: isDark ? AppTheme.primaryPurple.withOpacity(0.1) : Colors.blue.withOpacity(0.05),
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: isDark ? AppTheme.primaryPurple.withOpacity(0.2) : Colors.blue.withOpacity(0.1)),
        ),
        child: Row(
          children: [
             Icon(Icons.security_rounded, color: isDark ? AppTheme.primaryPurple : Colors.blue[700], size: 20),
             const SizedBox(width: 12),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text("Secure Checkout", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.blue[900], fontSize: 13)),
                    const SizedBox(height: 2),
                    Text("Your data is protected by 256-bit encryption.", style: TextStyle(color: isDark ? Colors.white70 : Colors.blue[800], fontSize: 11)),
                 ],
               ),
             )
          ],
        ),
      );
  }
}


class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isFaded;

  const _SummaryRow({required this.label, required this.value, this.isFaded = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: 15, 
          color: isDark ? Colors.grey[400] : Colors.grey.shade600,
        )),
        Text(value, style: TextStyle(
          fontSize: 15, 
          fontWeight: FontWeight.w600,
          color: isFaded ? (isDark ? Colors.grey[500] : Colors.grey.shade500) : (isDark ? Colors.white : Colors.black87),
        )),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final String currencySymbol;
  final AppState appState;
  final bool isDesktop;

  const _CartItemCard({
    required this.item,
    required this.currencySymbol,
    required this.appState,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final product = appState.getProductById(item.productId);
    final priceWithTax = product != null ? product.getPriceWithTax(item.price) : item.price;
    final unitPrice = appState.getPrice(priceWithTax);
    final totalPrice = unitPrice * item.quantity;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade100),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0,2))
        ]
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Center align image usually looks cleaner
        children: [
           // Image
           Container(
             width: isDesktop ? 120 : 90,
             height: isDesktop ? 120 : 90,
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(12),
               color: isDark ? Colors.grey[900] : Colors.grey.shade50,
             ),
             child: ClipRRect(
               borderRadius: BorderRadius.circular(12),
               child: item.image != null 
                 ? CachedNetworkImage(
                     imageUrl: item.image!, 
                     fit: BoxFit.cover, 
                     placeholder: (context, url) => Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[300])),
                     errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                   )
                 : const Icon(Icons.image, color: Colors.grey),
             ),
           ),
           SizedBox(width: isDesktop ? 24 : 16),
           
           // Details
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             item.name, 
                             style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: isDesktop ? 18 : 16),
                             maxLines: 2,
                             overflow: TextOverflow.ellipsis,
                           ),
                           if (isDesktop && item.quantity > 10) // Example badge
                               Container(
                                 margin: const EdgeInsets.only(top: 8),
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                 decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(4)),
                                 child: Text("Discount Eligible", style: TextStyle(fontSize: 10, color: Colors.orange[800])),
                               )
                         ],
                       ),
                     ),
                     const SizedBox(width: 8),
                     Text(
                       '$currencySymbol${totalPrice.toStringAsFixed(2)}',
                       style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryPurple),
                     ),
                   ],
                 ),
                 
                 const SizedBox(height: 8),
                 Text(
                   '$currencySymbol${unitPrice.toStringAsFixed(2)} / unit', 
                   style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
                 ),
                  if (item.selectedOptions != null && item.selectedOptions!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: item.selectedOptions!.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                            ),
                            child: Text(
                              '${e.key}: ${e.value}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                 const SizedBox(height: 16),
                 
                 // Controls
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade200)
                        ),
                        child: Row(
                          children: [
                             _QtyBtn(icon: Icons.remove, onTap: () =>  _updateQty(item.quantity - 1)),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 12.0),
                               constraints: const BoxConstraints(minWidth: 32),
                               alignment: Alignment.center,
                               child: Text(item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                             ),
                             _QtyBtn(icon: Icons.add, onTap: () =>  _updateQty(item.quantity + 1)),
                          ],
                        ),
                      ),
                      
                      if (isDesktop)
                        TextButton.icon(
                          onPressed: () => appState.removeFromCart(item.cartId),
                          icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[300]),
                          label: Text("Remove", style: TextStyle(color: Colors.red[300], fontSize: 13)),
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                        )
                      else
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => appState.removeFromCart(item.cartId),
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          ),
                        ),
                   ],
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }

  void _updateQty(double newQty) {
    if (newQty <= 0) return;
    appState.updateCartItemQuantity(item.cartId, newQty);
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      hoverColor: isDark ? Colors.grey[800] : Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, size: 16, color: Theme.of(context).iconTheme.color),
      ),
    );
  }
}

class _RecentlyPurchasedSection extends StatefulWidget {
  final AppState appState;
  const _RecentlyPurchasedSection({required this.appState});

  @override
  State<_RecentlyPurchasedSection> createState() => _RecentlyPurchasedSectionState();
}

class _RecentlyPurchasedSectionState extends State<_RecentlyPurchasedSection> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Tolerance of 1.0
    bool canLeft = currentScroll > 1.0;
    bool canRight = currentScroll < maxScroll - 1.0;
    
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
       setState(() {
         _canScrollLeft = canLeft;
         _canScrollRight = canRight;
       });
    }
  }

  List<Product> _getProducts() {
    if (widget.appState.orders.isNotEmpty) {
       final purchasedIds = widget.appState.orders.expand((o) => o.items).map((i) => i.productId).toSet();
       final purchased = widget.appState.products.where((p) => purchasedIds.contains(p.id)).take(10).toList();
       if (purchased.isNotEmpty) return purchased;
    }
    return widget.appState.products.where((p) => p.isTrending).take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _getProducts();
    if (products.isEmpty) return const SizedBox.shrink();

    final title = widget.appState.orders.isNotEmpty && products.any((p) => widget.appState.orders.expand((o)=>o.items).any((i)=>i.productId==p.id)) 
      ? 'Recently Purchased' 
      : 'You Might Also Like';

    // Responsive Logic
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    double cardWidth = 180;
    double cardHeight = 280;

    if (isMobile) {
      // Mobile: 2 cards per row.
      // Padding: 16 (left) + 16 (right) = 32
      // Gap: 16
      // Formula: (ScreenWidth - 32 - 16) / 2
      final availableWidth = screenWidth - 32; 
      cardWidth = (availableWidth - 16) / 2;
      cardHeight = cardWidth * 1.55; // Aspect ratio to ensure content fits
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Padding(
           padding: const EdgeInsets.only(left: 4, bottom: 16, right: 4),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
               Row(
                 children: [
                   IconButton(
                     icon: const Icon(Icons.arrow_back_ios, size: 16),
                     color: _canScrollLeft ? Theme.of(context).iconTheme.color : Colors.grey.withOpacity(0.3),
                     onPressed: _canScrollLeft ? () {
                        _scrollController.animateTo(
                          (_scrollController.offset - (cardWidth + 16)).clamp(0.0, _scrollController.position.maxScrollExtent),
                          duration: const Duration(milliseconds: 300), 
                          curve: Curves.easeOut
                        );
                     } : null,
                   ),
                   IconButton(
                     icon: const Icon(Icons.arrow_forward_ios, size: 16),
                     color: _canScrollRight ? Theme.of(context).iconTheme.color : Colors.grey.withOpacity(0.3),
                     onPressed: _canScrollRight ? () {
                         _scrollController.animateTo(
                          (_scrollController.offset + (cardWidth + 16)).clamp(0.0, _scrollController.position.maxScrollExtent),
                          duration: const Duration(milliseconds: 300), 
                          curve: Curves.easeOut
                        );
                     } : null,
                   ),
                 ],
               )
             ],
           ),
         ),
         SizedBox(
           height: cardHeight,
           child: ListView.separated(
             controller: _scrollController,
             scrollDirection: Axis.horizontal,
             itemCount: products.length,
             separatorBuilder: (ctx, i) => const SizedBox(width: 16),
             itemBuilder: (ctx, index) {
               return SizedBox(
                 width: cardWidth,
                 child: ProductCard(
                   product: products[index],
                   showBadges: true,
                   onTap: () {
                      Navigator.of(context).push(
                         MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: products[index].id))
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
