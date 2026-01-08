import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thameeha/models/product.dart';
import 'package:thameeha/models/cart_item.dart';
import 'package:thameeha/models/order.dart';
import 'package:thameeha/models/user_settings.dart';
import 'package:thameeha/constants.dart';

class ApiService {
  final String baseUrl = AppConstants.apiUrl;
  String? _token;

  ApiService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
  }

  Future<void> _setToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('jwt_token', token);
    } else {
      await prefs.remove('jwt_token');
    }
    _token = token;
  }

  // Ensure token is loaded before making authorized requests
  Future<Map<String, String>> _getHeaders({bool authorized = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authorized) {
      // Always reload from prefs to ensure we have the latest token
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('jwt_token');
      if (_token != null) {
        headers['Authorization'] = 'Bearer $_token';
      }
    }
    return headers;
  }

  // Synchronous version for non-critical requests
  Map<String, String> _setHeaders({bool authorized = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authorized && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // AUTH
  Future<Map<String, dynamic>> register(String username, String email, String password, String otp, {
    String? fullName,
    int? age,
    String? gender,
    String? countryCode,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _setHeaders(),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'otp': otp,
        'fullName': fullName,
        'age': age,
        'gender': gender,
        'countryCode': countryCode,
      }),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _setHeaders(),
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = _processResponse(res);
    if (data['message'] == 'success' && data['token'] != null) {
      await _setToken(data['token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> sendOtp(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/send-otp'),
      headers: _setHeaders(),
      body: jsonEncode({'email': email}),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> loginWithOtp(String email, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login-with-otp'),
      headers: _setHeaders(),
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    final data = _processResponse(res);
    if (data['message'] == 'success' && data['token'] != null) {
      await _setToken(data['token']);
    }
    return data;
  }

  Future<void> logout() async => _setToken(null);

  // Sync version - might be stale on first run
  bool isAuthenticatedSync() => _token != null;
  
  // Async version - always checks SharedPreferences for accuracy
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    return _token != null;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/forgot-password'),
      headers: _setHeaders(),
      body: jsonEncode({'email': email}),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> resetPassword(String token, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/reset-password'),
      headers: _setHeaders(),
      body: jsonEncode({'token': token, 'password': password}),
    );
    return _processResponse(res);
  }

  // PRODUCTS
  Future<List<Product>> fetchProducts() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/products'),
      headers: _setHeaders(),
    );
    final data = _processResponse(res);
    if (data['message'] == 'success' && data['data'] is List) {
      return (data['data'] as List).map((e) => Product.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<Product>> fetchAdvertisedProducts() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/products/search?isAdvertised=true&limit=10'),
      headers: _setHeaders(),
    );
    final data = _processResponse(res);
    if (data['message'] == 'success' && data['data'] is List) {
      return (data['data'] as List).map((e) => Product.fromJson(e)).toList();
    }
    // Search might return { data: [], count: ... } or just list or { data: { data: [] } }
    // Based on controller it usually returns { message: "success", data: [...], count: ... } 
    // or if paginated via search.
    // Let's inspect searchProducts in controller... it returns { message: "success", ...result }.
    // result from service is { data: products, count: ... }.
    // So response body is { message: "success", data: [...], count: ... }.
    
    return [];
  }

  Future<Product> fetchProductDetail(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/products/$id'),
      headers: _setHeaders(),
    );
    final data = _processResponse(res);
    if (data['message'] == 'success' && data['data'] != null) {
      return Product.fromJson(data['data']);
    }
    throw Exception('Failed to load product details');
  }

  Future<void> trackProductMetric(int productId, String metric) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/api/products/$productId/track/$metric'),
        headers: _setHeaders(),
      );
    } catch (e) {
      print('Metric tracking failed: $e');
    }
  }

  // CATEGORIES
  Future<List<dynamic>> fetchCategories() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/categories'),
      headers: _setHeaders(),
    );
    // Directly decode list since backend returns simple list currently
    // Or update backend. I will update backend to be consistent.
    // Assuming backend returns { data: [...] }
    final data = _processResponse(res);
    if (data['data'] is List) {
      return data['data'];
    }
    return [];
  }

  // CART
  Future<List<CartItem>> fetchCartItems() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/cart'),
      headers: _setHeaders(authorized: true),
    );
    final data = _processResponse(res);
    if (data['message'] == 'success' && data['data'] is List) {
      return (data['data'] as List).map((e) => CartItem.fromJson(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> addToCart(int productId, double quantity, {Map<String, dynamic>? selectedOptions, double? price}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/cart'),
      headers: _setHeaders(authorized: true),
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
        'selectedOptions': selectedOptions,
        'price': price,
      }),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateCartItem(int cartId, double quantity) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/cart/$cartId'),
      headers: _setHeaders(authorized: true),
      body: jsonEncode({'quantity': quantity}),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> removeFromCart(int cartId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/cart/$cartId'),
      headers: _setHeaders(authorized: true),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> clearCart() async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/cart'),
      headers: _setHeaders(authorized: true),
    );
    return _processResponse(res);
  }

  // ORDERS
  Future<Map<String, dynamic>> createOrder() async {
    final headers = await _getHeaders(authorized: true);
    final res = await http.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: headers,
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createOrderWithShipping(Map<String, dynamic> shippingDetails) async {
    final headers = await _getHeaders(authorized: true);
    final res = await http.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: headers,
      body: jsonEncode(shippingDetails),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> fetchOrders({int page = 1, int limit = 20, int? month, int? year}) async {
    final headers = await _getHeaders(authorized: true);
    final uri = Uri.parse('$baseUrl/api/orders').replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
      if (month != null) 'month': month.toString(),
      if (year != null) 'year': year.toString(),
    });

    final res = await http.get(uri, headers: headers);
    final data = _processResponse(res);
    
    if (data['message'] == 'success') {
      List<Order> orders = [];
      if (data['data'] is List) {
        orders = (data['data'] as List).map((e) => Order.fromJson(e)).toList();
      }
      return {
        'orders': orders,
        'pagination': data['pagination'] ?? {}
      };
    }
    return {'orders': <Order>[], 'pagination': {}};
  }

  Future<Order> fetchOrderDetail(int id) async {
    final headers = await _getHeaders(authorized: true);
    final res = await http.get(
      Uri.parse('$baseUrl/api/orders/$id'),
      headers: headers,
    );
    final data = _processResponse(res);
    if (data['message'] == 'success' && data['data'] != null) {
      return Order.fromJson(data['data']);
    }
    throw Exception('Failed to load order details');
  }

  Future<Map<String, dynamic>> fetchShipmentTracking(int orderId) async {
    final headers = await _getHeaders(authorized: true);
    final res = await http.get(
      Uri.parse('$baseUrl/api/orders/$orderId/tracking'),
      headers: headers,
    );
    final data = _processResponse(res);
    if (data['message'] == 'success') {
      return data['data'] ?? {};
    }
    return {};
  }

  Future<Map<String, dynamic>> cancelOrder(int orderId, {String? reason, String? notes}) async {
    final headers = await _getHeaders(authorized: true);
    final res = await http.put(
      Uri.parse('$baseUrl/api/orders/$orderId/cancel'),
      headers: headers,
      body: jsonEncode({
        'reason': reason,
        'notes': notes,
      }),
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> returnOrder(int orderId) async {
    final headers = await _getHeaders(authorized: true);
    final res = await http.post(
      Uri.parse('$baseUrl/api/orders/$orderId/return'),
      headers: headers,
    );
    return _processResponse(res);
  }

  Future<Map<String, dynamic>> createReturnRequest(int orderId, int orderItemId, String type, String reason, String description) async {
    final headers = await _getHeaders(authorized: true);
    final res = await http.post(
      Uri.parse('$baseUrl/api/returns'),
      headers: headers,
      body: jsonEncode({
        'order_id': orderId,
        'order_item_id': orderItemId,
        'type': type,
        'reason': reason,
        'description': description,
      }),
    );
    return _processResponse(res);
  }

  // SETTINGS
  Future<UserSettings> fetchUserSettings() async {
    return UserSettings();
  }

  // USER PROFILE
  Future<Map<String, dynamic>> fetchUserProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/user/profile'),
      headers: await _getHeaders(authorized: true),
    );
     return _processResponse(res);
  }

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> updates) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/user/profile'),
      headers: await _getHeaders(authorized: true),
      body: jsonEncode(updates),
    );
    return _processResponse(res, ignoreUsername: true);
  }

  Future<Map<String, dynamic>> changeUserPassword(String oldPassword, String newPassword) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/user/change-password'),
      headers: await _getHeaders(authorized: true),
      body: jsonEncode({'oldPassword': oldPassword, 'newPassword': newPassword}),
    );
    return _processResponse(res);
  }

  // REVIEWS
  Future<List<dynamic>> getReviews(int productId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/reviews/$productId'),
      headers: _setHeaders(),
    );
    final data = _processResponse(res);
    if (data['message'] == 'success' && data['data'] is List) {
      return data['data'];
    }
    return [];
  }

  Future<Map<String, dynamic>> createReview(int productId, int rating, String comment) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/reviews'),
      headers: _setHeaders(authorized: true),
      body: jsonEncode({
        'product_id': productId,
        'rating': rating,
        'comment': comment,
      }),
    );
    return _processResponse(res);
  }

  Future<bool> checkReviewEligibility(int productId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/reviews/eligibility/$productId'),
        headers: await _getHeaders(authorized: true),
      );
      final data = _processResponse(res);
      return data['canReview'] == true;
    } catch (e) {
      return false;
    }
  }

  // USER ADDRESSES
  Future<List<dynamic>> fetchUserAddresses() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/user/addresses'),
      headers: _setHeaders(authorized: true),
    );
     final data = _processResponse(res);
     if (data['message'] == 'success' && data['data'] is List) {
       return data['data'];
     }
     return [];
  }

  Future<Map<String, dynamic>> saveUserAddress(Map<String, dynamic> address) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/user/addresses'),
      headers: _setHeaders(authorized: true),
      body: jsonEncode(address),
    );
    return _processResponse(res);
  }

  // UI SECTIONS
  Future<List<dynamic>> fetchCountries() async {
    final res = await http.get(Uri.parse('$baseUrl/api/shipping/countries'));
    final data = _processResponse(res);
    return data['data'] ?? [];
  }

  Future<List<dynamic>> fetchStates(String countryCode) async {
    final res = await http.get(Uri.parse('$baseUrl/api/shipping/states?country_code=$countryCode'));
    final data = _processResponse(res);
    return data['data'] ?? [];
  }

  Future<List<dynamic>> fetchCities(String countryCode, String stateCode) async {
    final res = await http.get(Uri.parse('$baseUrl/api/shipping/cities?country_code=$countryCode&state_code=$stateCode'));
    final data = _processResponse(res);
    return data['data'] ?? [];
  }

  Future<List<dynamic>> locateCity(String countryCode, String cityName) async {
    final res = await http.get(Uri.parse('$baseUrl/api/shipping/locate?country_code=$countryCode&city=$cityName'));
    final data = _processResponse(res);
    return data['data'] ?? [];
  }

  Future<Map<String, dynamic>?> fetchLocalization({String? countryCode}) async {
    try {
      Uri uri = Uri.parse('$baseUrl/api/localization');
      if (countryCode != null && countryCode.isNotEmpty) {
        uri = uri.replace(queryParameters: {'countryCode': countryCode});
      }
      final res = await http.get(uri);
      final data = _processResponse(res);
      if (data['message'] == 'success') {
        return data['data'];
      }
    } catch (e) {
      print('Fetch localization error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> fetchShippingRates(Map<String, dynamic> addressData) async {
    final headers = await _getHeaders(authorized: true);
    // Backend expects flat structure: name, phone, address_line1, etc.
    // Use the new secure endpoint
    final res = await http.post(
      Uri.parse('$baseUrl/api/orders/shipping-quote'),
      headers: headers,
      body: jsonEncode(addressData), 
    );
     return _processResponse(res);
  }

  Future<Map<String, dynamic>?> fetchUiSection(String key) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/ui/$key'),
        headers: _setHeaders(),
      );
      final data = _processResponse(res);
      if (data['success'] == true) {
        return data['data'];
      }
    } catch (e) {
      print('Error fetching UI section $key: $e');
    }
    return null;
  }

  // SUPPORT
  Future<List<dynamic>> fetchSupportMessages() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/support/messages'),
      headers: await _getHeaders(authorized: true),
    );
     final data = _processResponse(res);
     if (data['message'] == 'success' && data['data'] is List) {
       return data['data'];
     }
     return [];
  }

  Future<Map<String, dynamic>> sendSupportMessage(String message) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/support/messages'),
      headers: await _getHeaders(authorized: true),
      body: jsonEncode({'message': message}),
    );
    return _processResponse(res);
  }

  Future<List<dynamic>> fetchFAQs() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/support/faqs'),
      headers: await _getHeaders(),
    );
     final data = _processResponse(res);
     if (data['message'] == 'success' && data['data'] is List) {
       return data['data'];
     }
     return [];
  }

  // NOTIFICATIONS
  Future<Map<String, dynamic>> updateFcmToken(String fcmToken) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/user/fcm-token'),
      headers: await _getHeaders(authorized: true),
      body: jsonEncode({'fcmToken': fcmToken}),
    );
    return _processResponse(res);
  }

  Future<List<dynamic>> fetchPendingNotifications() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/notifications/pending'),
      headers: await _getHeaders(authorized: true),
    );
    final data = _processResponse(res);
    if (data['success'] == true && data['data'] is List) {
      return data['data'];
    }
    return [];
  }

  Future<Map<String, dynamic>> trackNotification(int notificationId, String action) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/notifications/track'),
      headers: await _getHeaders(authorized: true),
      body: jsonEncode({
        'notificationId': notificationId,
        'action': action
      }),
    );
    return _processResponse(res);
  }

  Map<String, dynamic> _processResponse(http.Response res, {bool ignoreUsername = false}) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return {};
      try {
        return json.decode(res.body);
      } catch (e) {
        return {'message': 'success'}; // successful status code but no json (e.g 204)
      }
    }
    
    // Attempt to decode error message
    String errorMessage = 'Error ${res.statusCode}';
    try {
      final errorData = json.decode(res.body);
      if (errorData['message'] != null) {
        errorMessage = errorData['message'];
      } else if (errorData['error'] != null) {
        errorMessage = errorData['error'];
      }
    } catch (_) {
      // Use raw body if short, else default
      if (res.body.length < 100) errorMessage = res.body; 
    }

    if (res.statusCode == 401) {
      _setToken(null);
      throw Exception('Unauthorized: $errorMessage');
    }
    if (res.statusCode == 403) {
      throw Exception('Forbidden: $errorMessage');
    }
    if (res.statusCode == 404) {
      // Sometimes 404 is valid (empty list), but if it's an error endpoint:
      throw Exception(errorMessage);
    }
    
    // Ignore specific irrelevant errors
    final lowerError = errorMessage.toLowerCase();
    // Check if we should ignore username errors explicitly OR if it matches known patterns
    if (ignoreUsername && lowerError.contains("username")) {
       return {'message': 'success', 'warning': errorMessage};
    }
    // Fallback for global ignores if any
    if (lowerError.contains("username") && (lowerError.contains("required") || lowerError.contains("not given") || lowerError.contains("require"))) {
       return {'message': 'success', 'warning': errorMessage};
    }
    
    throw Exception(errorMessage);
  }
}
