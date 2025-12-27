import 'order_item.dart';

class Order {
  final int id;
  final List<OrderItem> items;
  final double totalPrice;
  final DateTime createdAt;
  final String status;
  
  // New Fields for Enhanced Detail View
  final String shippingName;
  final String shippingPhone;
  final String shippingAddressLine1;
  final String? shippingAddressLine2;
  final String shippingDistrict;
  final String shippingState;
  final String shippingPincode;
  final String shippingCountry;
  final String paymentMethod;
  final String paymentStatus;
  final String? returnTrackingNumber;
  final String? returnLabelUrl;
  final String? cancelReason;
  final String? cancelNotes;
  final String? trackingNumber;
  final String? carrier;
  final String? labelUrl;

  Order({
    required this.id,
    required this.items,
    required this.totalPrice,
    required this.createdAt,
    required this.status,
    required this.shippingName,
    required this.shippingPhone,
    required this.shippingAddressLine1,
    this.shippingAddressLine2,
    required this.shippingDistrict,
    required this.shippingState,
    required this.shippingPincode,
    required this.shippingCountry,
    required this.paymentMethod,
    required this.paymentStatus,
    this.returnTrackingNumber,
    this.returnLabelUrl,
    this.cancelReason,
    this.cancelNotes,
    this.trackingNumber,
    this.carrier,
    this.labelUrl,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> orderItems = [];
    
    if (json['items'] != null && json['items'] is List) {
      var itemsList = json['items'] as List;
      orderItems = itemsList.map((i) => OrderItem.fromJson(i)).toList();
    }

    DateTime parsedDate;
    try {
      if (json['created_at'] != null) {
        parsedDate = DateTime.parse(json['created_at']);
      } else {
        parsedDate = DateTime.now();
      }
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return Order(
      id: int.tryParse(json['id'].toString()) ?? 0,
      items: orderItems,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0.0,
      createdAt: parsedDate,
      status: json['status'] as String? ?? 'Pending',
      shippingName: json['shipping_name'] as String? ?? 'N/A',
      shippingPhone: json['shipping_phone'] as String? ?? '',
      shippingAddressLine1: json['shipping_address_line1'] as String? ?? '',
      shippingAddressLine2: json['shipping_address_line2'] as String?,
      shippingDistrict: json['shipping_district'] as String? ?? '',
      shippingState: json['shipping_state'] as String? ?? '',
      shippingPincode: json['shipping_pincode'] as String? ?? '',
      shippingCountry: json['shipping_country'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? 'Online',
      paymentStatus: json['payment_status'] as String? ?? 'Pending',
      returnTrackingNumber: json['return_tracking_number'] as String?,
      returnLabelUrl: json['return_label_url'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      cancelNotes: json['cancel_notes'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      carrier: json['carrier'] as String?,
      labelUrl: json['label_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((i) => i.toJson()).toList(),
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'shipping_name': shippingName,
      'shipping_phone': shippingPhone,
      'shipping_address_line1': shippingAddressLine1,
      'shipping_address_line2': shippingAddressLine2,
      'shipping_district': shippingDistrict,
      'shipping_state': shippingState,
      'shipping_pincode': shippingPincode,
      'shipping_country': shippingCountry,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'return_tracking_number': returnTrackingNumber,
      'return_label_url': returnLabelUrl,
      'cancel_reason': cancelReason,
      'cancel_notes': cancelNotes,
      'tracking_number': trackingNumber,
      'carrier': carrier,
      'label_url': labelUrl,
    };
  }
}
