import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thameeha/models/cart_item.dart';
import 'package:thameeha/models/order.dart';
import 'package:thameeha/models/product.dart';
import 'package:thameeha/models/review.dart';
import 'package:thameeha/models/user_settings.dart';
import 'package:thameeha/services/api_service.dart';
import 'package:thameeha/services/notification_manager.dart';

class AppState with ChangeNotifier {
  final ApiService _apiService;
  late final NotificationManager _notificationManager;
  bool _isAuthenticated = false;
  bool _isProductsLoading = false;
  bool _isCategoriesLoading = false;
  String _currencySymbol = '\$';

  double _exchangeRate = 1.0;
  double _percentageIncrease = 0.0; // Pct (e.g. 20.0 for 20%)
  double _baseShippingCost = 0.0;
  double _freeShippingThreshold = 1000000.0;

  AppState({required ApiService apiService}) : _apiService = apiService {
    _notificationManager = NotificationManager(_apiService);
    _initializeLocalization();
    checkLoginStatus();
  }

  Future<void> _initializeLocalization() async {
    try {
      final data = await _apiService.fetchLocalization(); 
      if (data != null) {
        _currencySymbol = data['symbol'] ?? '\$';
        _exchangeRate = (data['exchange_rate'] ?? 1.0).toDouble();
        _percentageIncrease = (data['percentage_increase'] ?? 0.0).toDouble();
        _baseShippingCost = (data['base_shipping_cost'] ?? 0.0).toDouble();
        _freeShippingThreshold = (data['free_shipping_threshold'] ?? 1000000.0).toDouble();
        
        // Auto-update preferred currency based on detection
        if (data['currency'] != null) {
           String detectedCurrency = data['currency'];
           if (_userSettings.preferredCurrency != detectedCurrency) {
              _userSettings = UserSettings(
                enableNotifications: _userSettings.enableNotifications,
                darkMode: _userSettings.darkMode,
                preferredCurrency: detectedCurrency
              );
           }
        }
      } else {
        _fallbackCurrency();
      }
    } catch (e) {
      print("Localization failed: $e");
      _fallbackCurrency();
    }
    notifyListeners();
  }

  void _fallbackCurrency() {
      try {
        final locale = PlatformDispatcher.instance.locale;
        final country = locale.countryCode ?? 'US';
        String currencyCode = 'USD';
        
        if (country == 'IN') {
          _currencySymbol = '₹';
          currencyCode = 'INR';
        } else if (country == 'GB') {
          _currencySymbol = '£';
          currencyCode = 'GBP';
        } else if (['FR', 'DE', 'IT', 'ES', 'NL', 'EU'].contains(country)) {
          _currencySymbol = '€';
          currencyCode = 'EUR';
        } else if (country == 'JP') {
          _currencySymbol = '¥';
          currencyCode = 'JPY';
        } else {
          _currencySymbol = '\$';
          currencyCode = 'USD';
        }
        
        // Update user settings default if not set
        if (_userSettings.preferredCurrency == 'USD' && currencyCode != 'USD') {
             _userSettings = UserSettings(
                enableNotifications: _userSettings.enableNotifications,
                darkMode: _userSettings.darkMode,
                preferredCurrency: currencyCode
             );
        }
      } catch (e) {
        _currencySymbol = '\$';
      }
  }

  /// Calculates display price based on current localization settings.
  /// Standard Formula: BasePrice (INR) * ExRate * (1 + Markup/100)
  double getPrice(double basePrice) {
    if (_exchangeRate == 1.0 && _percentageIncrease == 0.0) return basePrice;
    
    double converted = basePrice * _exchangeRate;
    double markedUp = converted + (converted * (_percentageIncrease / 100));
    return double.parse(markedUp.toStringAsFixed(2));
  }

  /// Calculates shipping cost based on subtotal.
  double getShippingCost(double subtotal) {
    if (subtotal >= _freeShippingThreshold) return 0.0;
    return _baseShippingCost;
  }

  double get baseShippingCost => _baseShippingCost;
  double get freeShippingThreshold => _freeShippingThreshold;

  Future<bool> checkLoginStatus() async {
    _isAuthenticated = await _apiService.isAuthenticated();
    if (_isAuthenticated) {
      // Fetch data proactively on startup/refresh
      await fetchCartItems();
      await fetchOrders();
      // Init notifications
      _notificationManager.init();
    } else {
      await _loadLocalCart();
    }
    await _loadRecentlyViewed();
    await _loadWishlist();
    notifyListeners();
    return _isAuthenticated;
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isProductsLoading => _isProductsLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;
   String get currencySymbol => _currencySymbol;
   String get currencyCode => _userSettings.preferredCurrency;
  ApiService get apiService => _apiService;

  List<Product> _products = [];
  List<CartItem> _cartItems = [];
  List<Order> _orders = [];
  UserSettings _userSettings = UserSettings();

  // Navigation state for bottom bar
  int _selectedTabIndex = 0;
  String? _selectedCategory;

  List<Product> get products => _products;
  List<Product> get advertisedProducts => _advertisedProducts;
  List<CartItem> get cartItems => _cartItems;
  List<Order> get orders => _orders;
  List<Product> get recentlyViewed => _recentlyViewed; // Expose Recent
  UserSettings get userSettings => _userSettings;
  int get selectedTabIndex => _selectedTabIndex;
  String? get selectedCategory => _selectedCategory;

  List<Product> _advertisedProducts = [];

  List<Product> _recentlyViewed = [];

  Future<void> addToRecentlyViewed(Product product) async {
    // Remove if exists to push to top
    _recentlyViewed.removeWhere((p) => p.id == product.id);
    _recentlyViewed.insert(0, product);
    if (_recentlyViewed.length > 10) {
      _recentlyViewed = _recentlyViewed.sublist(0, 10);
    }
    notifyListeners();
    await _saveRecentlyViewed();
  }

  Future<void> _loadRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString('recently_viewed');
      if (jsonStr != null) {
        final List<dynamic> list = jsonDecode(jsonStr);
        _recentlyViewed = list.map((e) => Product.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error loading recently viewed: $e');
    }
  }

  Future<void> _saveRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = jsonEncode(_recentlyViewed.map((e) => e.toJson()).toList());
      await prefs.setString('recently_viewed', jsonStr);
    } catch (e) {
      print('Error saving recently viewed: $e');
    }
  }

  void setSelectedTab(int index, {String? category}) {
    _selectedTabIndex = index;
    _selectedCategory = category;
    notifyListeners();
  }

  void clearSelectedCategory() {
    _selectedCategory = null;
    notifyListeners();
  }

  Product? getProductById(int id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> fetchAllData() async {
    await fetchCategories();
    await fetchProducts();
    await fetchAdvertisedProducts();
    
    // Re-check auth status before fetching authenticated data
    _isAuthenticated = await _apiService.isAuthenticated();
    print('AppState: fetchAllData - isAuthenticated: $_isAuthenticated');
    
    if (_isAuthenticated) {
      await fetchCartItems();
      await fetchOrders();
    } else {
      await _loadLocalCart();
    }
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    _isProductsLoading = true;
    notifyListeners();
    try {
      _products = await _apiService.fetchProducts();
    } catch (e) {
      print('Error fetching products: $e');
      _products = [];
    } finally {
      _isProductsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdvertisedProducts() async {
    try {
      _advertisedProducts = await _apiService.fetchAdvertisedProducts();
    } catch (e) {
      print('Error fetching advertised products: $e');
      _advertisedProducts = [];
    }
    notifyListeners();
  }

  List<dynamic> _categories = [];
  List<dynamic> get categories => _categories;

  Future<void> fetchCategories() async {
    _isCategoriesLoading = true;
    notifyListeners();
    try {
      _categories = await _apiService.fetchCategories();
    } catch (e) {
      print('Error fetching categories: $e');
      _categories = [];
    } finally {
      _isCategoriesLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCartItems() async {
    if (!_isAuthenticated) {
      await _loadLocalCart();
      return;
    }
    try {
      _cartItems = await _apiService.fetchCartItems();
    } catch (e) {
      print('Error fetching cart items: $e');
      _cartItems = [];
    }
    notifyListeners();
  }

  Map<String, dynamic> _ordersPagination = {};
  Map<String, dynamic> get ordersPagination => _ordersPagination;

  Future<void> fetchOrders({int page = 1, int limit = 20, int? month, int? year}) async {
    if (!_isAuthenticated) {
      print('Cannot fetch orders: User not authenticated');
      return;
    }
    try {
      print('Fetching orders...');
      // Load local orders first for immediate display (only on first page)
      if (page == 1) {
         await _loadLocalOrders();
         if (_orders.isNotEmpty) notifyListeners();
      }

      final result = await _apiService.fetchOrders(page: page, limit: limit, month: month, year: year);
      _orders = result['orders'];
      _ordersPagination = result['pagination'];
      
      if (page == 1) {
        await _saveLocalOrders();
      }
      
      print('Orders fetched successfully: ${_orders.length} orders');
    } catch (e) {
      print('Error fetching orders: $e');
      print('Stack trace: ${StackTrace.current}');
      // If API fails, we keep the local orders
      if (_orders.isEmpty && page == 1) {
         await _loadLocalOrders();
      }
    }
    notifyListeners();
  }

  Future<void> fetchUserSettings() async {
    if (!_isAuthenticated) return;
    try {
      _userSettings = await _apiService.fetchUserSettings();
    } catch (e) {
      print('Error fetching user settings: $e');
      _userSettings = UserSettings();
    }
    notifyListeners();
  }

  // ===========================================
  // LOCAL CART PERSISTENCE
  // ===========================================

  Future<void> _loadLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartJson = prefs.getString('local_cart');
      if (cartJson != null) {
        final List<dynamic> decoded = jsonDecode(cartJson);
        _cartItems = decoded.map((item) => CartItem.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading local cart: $e');
    }
  }

  Future<void> _saveLocalCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cartJson = jsonEncode(_cartItems.map((item) => item.toJson()).toList());
      await prefs.setString('local_cart', cartJson);
    } catch (e) {
      print('Error saving local cart: $e');
    }
  }

  Future<void> clearCartLocally() async {
    _cartItems = [];
    await _saveLocalCart();
    notifyListeners();
  }

  // ===========================================
  // LOCAL ORDER PERSISTENCE
  // ===========================================

  Future<void> _loadLocalOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ordersJson = prefs.getString('local_orders');
      if (ordersJson != null) {
        final List<dynamic> decoded = jsonDecode(ordersJson);
        _orders = decoded.map((item) => Order.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading local orders: $e');
    }
  }

  Future<void> _saveLocalOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String ordersJson = jsonEncode(_orders.map((item) => item.toJson()).toList());
      await prefs.setString('local_orders', ordersJson);
    } catch (e) {
      print('Error saving local orders: $e');
    }
  }

  // ===========================================
  // AUTHENTICATION METHODS
  // ===========================================

  Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await _apiService.sendOtp(email);
      return response;
    } catch (e) {
      print('Send OTP error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> loginWithOtp(String email, String otp) async {
    try {
      final response = await _apiService.loginWithOtp(email, otp);
      if (response['message'] == 'success') {
        _isAuthenticated = true;
        await fetchAllData();
      }
      notifyListeners();
      return response;
    } catch (e) {
      print('Login with OTP error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(String username, String email, String password, String otp) async {
    try {
      final response = await _apiService.register(username, email, password, otp);
      if (response['message'] == 'success') {
        await login(username, password);
      }
      return response;
    } catch (e) {
      print('Register error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _apiService.login(username, password);
      if (response['message'] == 'success') {
        _isAuthenticated = true;
        await fetchAllData();
        _notificationManager.init();
      }
      notifyListeners();
      return response;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _isAuthenticated = false;
    _cartItems = [];
    _orders = [];
    // Optionally clear local cart or keep it empty
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('local_cart');
    await prefs.remove('local_orders');
    notifyListeners();
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _apiService.forgotPassword(email);
      return response;
    } catch (e) {
      print('Forgot password error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resetPassword(String token, String password) async {
    try {
      final response = await _apiService.resetPassword(token, password);
      return response;
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }

  // ===========================================
  // CART OPERATIONS
  // ===========================================

  Future<void> addToCart(int productId, int quantity, {Map<String, dynamic>? selectedOptions, double? price}) async {
    if (_isAuthenticated) {
      try {
        await _apiService.addToCart(productId, quantity, selectedOptions: selectedOptions, price: price);
        await fetchCartItems();
        // Track add to cart if notification was received
        _notificationManager.reportActionAfterNotification('added_to_cart');
      } catch (e) {
        print('Error adding to cart: $e');
        rethrow;
      }
    } else {
      // Local cart logic
      final product = getProductById(productId);
      if (product == null) return;

      // When checking for existing items, we must check both productId AND selectedOptions
      final existingIndex = _cartItems.indexWhere((item) {
        bool sameProduct = item.productId == productId;
        bool sameOptions = jsonEncode(item.selectedOptions) == jsonEncode(selectedOptions);
        return sameProduct && sameOptions;
      });

      if (existingIndex >= 0) {
        _cartItems[existingIndex].quantity += quantity;
      } else {
        _cartItems.add(CartItem(
          cartId: DateTime.now().millisecondsSinceEpoch, // Temporary ID
          productId: productId,
          name: product.name,
          price: price ?? product.price,
          quantity: quantity,
          image: product.image,
          selectedOptions: selectedOptions != null ? Map<String, dynamic>.from(selectedOptions) : null,
        ));
      }
      await _saveLocalCart();
      notifyListeners();
    }
  }

  Future<void> removeFromCart(int cartId) async {
    if (_isAuthenticated) {
      try {
        await _apiService.removeFromCart(cartId);
        await fetchCartItems();
      } catch (e) {
        print('Error removing from cart: $e');
        rethrow;
      }
    } else {
      _cartItems.removeWhere((item) => item.cartId == cartId);
      await _saveLocalCart();
      notifyListeners();
    }
  }

  Future<void> updateCartItemQuantity(int cartId, int quantity) async {
    if (quantity < 1) {
      await removeFromCart(cartId);
      return;
    }

    if (_isAuthenticated) {
      try {
        await _apiService.updateCartItem(cartId, quantity);
        await fetchCartItems();
      } catch (e) {
        print('Error updating cart item quantity: $e');
        rethrow;
      }
    } else {
      final index = _cartItems.indexWhere((item) => item.cartId == cartId);
      if (index >= 0) {
        _cartItems[index].quantity = quantity;
        await _saveLocalCart();
        notifyListeners();
      }
    }
  }

  Future<void> clearCart() async {
    if (_isAuthenticated) {
      try {
        await _apiService.clearCart();
        await fetchCartItems();
      } catch (e) {
        print('Error clearing cart: $e');
        rethrow;
      }
    } else {
      _cartItems.clear();
      await _saveLocalCart();
      notifyListeners();
    }
  }

  // ===========================================
  // ORDER OPERATIONS
  // ===========================================

  Future<Map<String, dynamic>> createOrder() async {
    if (!_isAuthenticated) throw Exception("Please log in to place an order.");
    try {
      final response = await _apiService.createOrder();
      await fetchCartItems();
      await fetchOrders();
      return response;
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createOrderWithShipping(Map<String, dynamic> shippingDetails) async {
    if (!_isAuthenticated) throw Exception("Please log in to place an order.");
    try {
      final response = await _apiService.createOrderWithShipping(shippingDetails);
      await fetchCartItems();
      await fetchOrders();
      // Track purchase if notification was received
      _notificationManager.reportActionAfterNotification('purchased');
      return response;
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  Future<void> cancelOrder(int orderId, {String? reason, String? notes}) async {
    if (!_isAuthenticated) throw Exception("Please log in.");
    try {
      await _apiService.cancelOrder(orderId, reason: reason, notes: notes);
      await fetchOrders(); // Refresh order status
    } catch (e) {
      print('Error cancelling order: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> returnOrder(int orderId) async {
    if (!_isAuthenticated) throw Exception("Please log in.");
    try {
      final res = await _apiService.returnOrder(orderId);
      await fetchOrders(); 
      return res;
    } catch (e) {
      print('Error returning order: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createReturnRequest(int orderId, int orderItemId, String type, String reason, String description) async {
    if (!_isAuthenticated) throw Exception("Please log in.");
    try {
      final res = await _apiService.createReturnRequest(orderId, orderItemId, type, reason, description);
      await fetchOrders(); 
      return res;
    } catch (e) {
      print('Error creating return request: $e');
      rethrow;
    }
  }

  // ===========================================
  // REVIEW OPERATIONS
  // ===========================================

  Future<List<Review>> fetchReviews(int productId) async {
    try {
      final data = await _apiService.getReviews(productId);
      return data.map((e) => Review.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  Future<void> addReview(int productId, int rating, String comment) async {
    if (!_isAuthenticated) throw Exception("Please log in to write a review.");
    try {
      await _apiService.createReview(productId, rating, comment);
      notifyListeners();
    } catch (e) {
      print('Error adding review: $e');
      rethrow;
    }
  }

  Future<bool> checkReviewEligibility(int productId) async {
    if (!_isAuthenticated) return false;
    return await _apiService.checkReviewEligibility(productId);
  }

  // Wishlist State
  Set<int> _wishlistIds = {};
  List<Product> get wishlistProducts => _products.where((p) => _wishlistIds.contains(p.id)).toList();

  Future<void> addToWishlist(int productId) async {
    if (!_wishlistIds.contains(productId)) {
      _wishlistIds.add(productId);
      notifyListeners();
      await _saveWishlist();
      _notificationManager.reportActionAfterNotification('wishlisted'); // Optional tracking
    }
  }

  Future<void> removeFromWishlist(int productId) async {
    if (_wishlistIds.contains(productId)) {
      _wishlistIds.remove(productId);
      notifyListeners();
      await _saveWishlist();
    }
  }

  void toggleWishlist(int productId) {
    if (_wishlistIds.contains(productId)) {
      removeFromWishlist(productId);
    } else {
      addToWishlist(productId);
    }
  }

  bool isWishlisted(int productId) => _wishlistIds.contains(productId);

  Future<void> _loadWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? list = prefs.getStringList('wishlist_ids');
      if (list != null) {
        _wishlistIds = list.map((e) => int.parse(e)).toSet();
      }
    } catch (e) {
      print('Error loading wishlist: $e');
    }
  }

  Future<void> _saveWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('wishlist_ids', _wishlistIds.map((e) => e.toString()).toList());
    } catch (e) {
      print('Error saving wishlist: $e');
    }
  }

  void updateUserSettings(UserSettings newSettings) {
    _userSettings = newSettings;
    notifyListeners();
  }
}
