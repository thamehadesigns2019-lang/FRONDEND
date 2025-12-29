import 'dart:convert';

class CartItem {
  final int cartId;
  final int productId;
  final String name;
  final double price;
  double quantity;
  final String? image;
  final Map<String, dynamic>? selectedOptions;

  CartItem({
    required this.cartId,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.image,
    this.selectedOptions,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartId: json['cart_id'] as int,
      productId: json['product_id'] as int,
      name: json['name'] as String,
      price: json['price'].toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      image: json['image'] as String?,
      selectedOptions: json['selected_options'] != null
          ? Map<String, dynamic>.from(jsonDecode(json['selected_options']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cart_id': cartId,
      'product_id': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image,
      'selected_options': selectedOptions != null ? jsonEncode(selectedOptions) : null,
    };
  }
}
