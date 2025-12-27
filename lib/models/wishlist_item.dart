import 'product.dart';

class WishlistItem {
  final int wishlistId;
  final Product product;

  WishlistItem({
    required this.wishlistId,
    required this.product,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      wishlistId: json['wishlist_id'] as int,
      product: Product.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wishlist_id': wishlistId,
      ...product.toJson(),
    };
  }
}
