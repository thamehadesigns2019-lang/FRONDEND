import 'dart:convert';

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final double price;
  final String name; // From product details
  final String? image; // From product details
  final Map<String, dynamic>? selectedOptions;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.name,
    this.image,
    this.selectedOptions,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      orderId: int.tryParse(json['order_id'].toString()) ?? 0,
      productId: int.tryParse(json['product_id'].toString()) ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      name: json['name'] as String? ?? 'Unknown Product',
      image: json['image'] as String?,
      selectedOptions: json['selected_options'] != null
          ? Map<String, dynamic>.from(jsonDecode(json['selected_options']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'name': name,
      'image': image,
      'selected_options': selectedOptions != null ? jsonEncode(selectedOptions) : null,
    };
  }
}
