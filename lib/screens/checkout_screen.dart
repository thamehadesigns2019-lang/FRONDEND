
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/theme/themes.dart';
import 'package:thameeha/services/api_service.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';

import 'package:thameeha/screens/order_success_screen.dart';

import 'package:thameeha/constants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:js' as js; 

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  var cfPaymentGatewayService = CFPaymentGatewayService(); 

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();

  // State Variables
  String _selectedCountry = 'IN'; // Default India code
  String? _selectedCountryName = 'India'; // Default Name
  bool _isLoading = false;
  bool _isDetectingLocation = false;
  double _shippingCost = 0.0;
  List<Map<String, dynamic>> _countries = [];
  String _paymentMethod = 'COD';
  bool _saveForNextTime = false;
  Map<String, dynamic>? _selectedRate;
  bool _isShippingCalculated = false;

  // Address Management
  List<dynamic> _savedAddresses = [];
  int? _selectedAddressId; // If null, means "New Address" or manually entered

  @override
  void initState() {
    super.initState();
    try {
      cfPaymentGatewayService.setCallback(verifyPayment, onError);
    } catch (e) {
      print("Error setting Cashfree callback: $e");
    }
    _loadInitialData();
  }

  void verifyPayment(String orderId) async {
    print("Verify Payment for $orderId");
    // Ensure we show loading while verifying
    setState(() => _isLoading = true);
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      // Construct API call to verify payment on backend
       final res = await http.post(
         Uri.parse('${appState.apiService.baseUrl}/api/orders/verify-payment'),
         headers: {'Content-Type': 'application/json'},
         body: jsonEncode({'orderId': orderId})
       );
       
       if (res.statusCode == 200) {
         final data = jsonDecode(res.body);
         if (data['status'] == 'Success') {
            await appState.fetchCartItems();
            await appState.fetchOrders();
            setState(() => _isLoading = false); // Stop loading
            _showSuccessDialog(orderId);
         } else if (data['status'] == 'Pending') {
             // If still pending after modal close, maybe retry once or tell user?
             // Ideally we loop here or show a manual check?
             // For now, let's stop loading and show message
             setState(() => _isLoading = false);
             _showSnack("Payment Pending/Processing... Please check orders later.");
             Navigator.of(context).pushReplacementNamed('/orders');
         } else {
            setState(() => _isLoading = false);
            _showSnack("Payment verification failed: ${data['message']}");
         }
       } else {
         setState(() => _isLoading = false);
         _showSnack("Payment verification failed on server.");
       }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Error verifying payment: $e");
    }
  }

  Future<void> _loadInitialData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Fetch Countries
    try {
      final countriesData = await appState.apiService.fetchCountries();
      if (countriesData.isNotEmpty) {
        setState(() {
          _countries = countriesData.map((e) => Map<String, dynamic>.from(e)).toList();
          // Try to find name for default 'IN' if list loaded
          final india = _countries.firstWhere((c) => c['code'] == 'IN', orElse: () => {});
          if (india.isNotEmpty) {
             _selectedCountryName = india['name'];
             _countryController.text = india['name']; // Set initial text
          }
        });
      }
    } catch (e) {
      print("Error fetching countries: $e");
    }

    // Fetch Saved Addresses
    try {
      final addresses = await appState.apiService.fetchUserAddresses();
      if (mounted && addresses.isNotEmpty) {
        setState(() {
          _savedAddresses = addresses;
        });
      }
    } catch (e) {
      print("Error fetching addresses: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pincodeController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Logic ---

  Future<void> _onPincodeChanged(String value) async {
    if (value.length == 6 && _selectedCountry == 'IN') {
      setState(() => _isDetectingLocation = true);
      try {
        final response = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$value'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is List && data.isNotEmpty && data[0]['Status'] == 'Success') {
            final postOffices = data[0]['PostOffice'] as List;
            if (postOffices.isNotEmpty) {
               final place = postOffices[0];
               setState(() {
                 _stateController.text = place['State'] ?? '';
                 _cityController.text = place['District'] ?? place['Block'] ?? '';
               });
               
               _calculateShipping();
            }
          }
        }
      } catch (e) {
        print("Pincode lookup failed: $e");
      } finally {
        setState(() => _isDetectingLocation = false);
      }
    }
  }

  Future<void> _calculateShipping() async {
     if (_selectedCountry.isEmpty || _stateController.text.isEmpty || _pincodeController.text.isEmpty) return;
     
     setState(() {
       _isDetectingLocation = true; 
       _shippingCost = 0.0;
       _selectedRate = null;
       _isShippingCalculated = false;
     });

     try {
        final appState = Provider.of<AppState>(context, listen: false);
        
        // Calculate subtotal in local currency for threshold check
        final cartTotal = appState.cartItems.fold(0.0, (sum, item) => sum + (appState.getPrice(item.price) * item.quantity));
        
        // 1. Get Static Rule from AppState (Market Specific)
        final staticShippingLocal = appState.getShippingCost(cartTotal);
        
        // 2. Fetch Dynamic Rates from Envia
        final addressData = {
           'country': _selectedCountry,
           'state': _stateController.text,
           'pincode': _pincodeController.text,
           'city': _cityController.text,
           'district': _cityController.text,
        };
        
        final result = await appState.apiService.fetchShippingRates(addressData);
        
        if (mounted) {
           final List rates = result['data'] ?? [];
           
           if (rates.isNotEmpty) {
              // Sort by price ascending
              rates.sort((a, b) {
                final priceA = double.tryParse(a['totalPrice']?.toString() ?? '') ?? 999999.0;
                final priceB = double.tryParse(b['totalPrice']?.toString() ?? '') ?? 999999.0;
                return priceA.compareTo(priceB);
              });

              final cheapestRate = rates.first;
              final cheapestPriceInr = double.tryParse(cheapestRate['totalPrice']?.toString() ?? '0') ?? 0.0;
              final cheapestPriceLocal = appState.getPrice(cheapestPriceInr);

              // Decide between static rule and dynamic cheapest rate
              // If static rule is cheaper or free (due to threshold), we can use it.
              // However, typically Envia is the real real price. 
              // We pick the absolute minimum available.
              if (staticShippingLocal < cheapestPriceLocal) {
                 setState(() {
                   _shippingCost = staticShippingLocal / appState.getPrice(1.0); // reverse to "base" if getPrice is used in build
                   // Wait, if _shippingCost is treated as INR in build (getPrice(_shippingCost)), 
                   // then we should store it as INR.
                   // But staticShippingLocal is already local.
                   // Let's store it such that appState.getPrice(_shippingCost) == staticShippingLocal.
                   _shippingCost = staticShippingLocal == 0 ? 0.0 : staticShippingLocal / (appState.getPrice(100) / 100); 
                   _selectedRate = null;
                 });
              } else {
                 setState(() {
                   _shippingCost = cheapestPriceInr;
                   _selectedRate = cheapestRate;
                 });
              }
           } else {
              // Fallback to static rule if no Envia rates
              setState(() {
                _shippingCost = staticShippingLocal == 0 ? 0.0 : staticShippingLocal / (appState.getPrice(100) / 100);
                _selectedRate = null;
              });
           }
           
           setState(() {
             _isDetectingLocation = false;
             _isShippingCalculated = true;
           });
        }
     } catch (e) {
        print("Shipping Calc Error: $e");
        if (mounted) {
           final appState = Provider.of<AppState>(context, listen: false);
           final cartTotal = appState.cartItems.fold(0.0, (sum, item) => sum + (appState.getPrice(item.price) * item.quantity));
           setState(() {
              final localCost = appState.getShippingCost(cartTotal);
              _shippingCost = localCost == 0 ? 0.0 : localCost / (appState.getPrice(100) / 100);
              _isDetectingLocation = false;
              _isShippingCalculated = true;
           });
        }
     }
  }


  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
       _showSnack("Please fill all required fields correctly.");
       return;
    }
    
    if (_selectedCountry.isEmpty) {
       _showSnack("Please select a valid country from the list.");
       return;
    }
    
    if (!_isShippingCalculated) {
       _showSnack("Please enter a valid shipping address to calculate costs.");
       return;
    }

    setState(() => _isLoading = true);
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      final orderData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'address_line1': _addressController.text,
        'city': _cityController.text,
        'district': _cityController.text,
        'state': _stateController.text,
        'country': _selectedCountry,
        'pincode': _pincodeController.text,
        'payment_method': _paymentMethod,
        'shipping_cost': _shippingCost,
        'shipping_rate_data': _selectedRate,
        'currency_symbol': appState.currencySymbol,
        'currency_code': appState.currencyCode,
        'return_url': "${Uri.base.toString().split('#')[0]}#/payment-status?order_id={order_id}",
      };

      final result = await appState.createOrderWithShipping(orderData);

      if (mounted) {
         if (result['message'] != null && result['data'] != null) {
             
             // Auto-save address
             if (_selectedAddressId == null && _saveForNextTime) {
               try {
                 await appState.apiService.saveUserAddress(orderData);
               } catch (e) { }
             }

             if (_paymentMethod == 'COD') {
                _showSuccessDialog(result['data']['orderId'] ?? 'New');
             } else if (_paymentMethod == 'Prepaid') {
                // Handle Cashfree
                    final data = result['data'];
                    if (data['paymentInitiationFailed'] == true) {
                       _showSnack("Payment Gateway Error: ${data['error']}");
                       setState(() => _isLoading = false);
                       return;
                    }

                    // Check if session ID exists
                    final sessionId = data['payment_session_id'];
                    final orderId = data['cf_order_id'];
                    
                    if (sessionId != null && orderId != null) {
                       _initiateCashfreePayment(sessionId, orderId);
                    } else {
                       print("Payment Session Missing in Data: $data");
                       _showSnack("Error: Payment initialization failed (Missing Session).");
                       setState(() => _isLoading = false);
                    }
             }
         } else {
            throw Exception(result['message'] ?? 'Order creation failed');
         }
      }

    } catch (e) {
      if (mounted) _showSnack('Error placing order: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initiateCashfreePayment(String sessionId, String orderId) {
    try {
      // 1. Handle Web
      if (kIsWeb) {
        print("Launching Cashfree Web Checkout...");
        
        // Define the callback function that index.html will call
        js.context['onCashfreePaymentComplete'] = (String jsonResult) {
            print("Flutter received Cashfree result: $jsonResult");
            try {
              final result = jsonDecode(jsonResult);
              if (result['paymentDetails'] != null) {
                  // Payment likely successful, verify it
                  verifyPayment(orderId);
              } else if (result['error'] != null) {
                   setState(() => _isLoading = false);
                   _showSnack("Payment Failed: ${result['error']['message'] ?? 'Unknown Error'}");
              } else {
                  // Redirect or other state users closed modal
                  setState(() => _isLoading = false);
                  _showSnack("Payment Closed.");
              }
            } catch (e) {
               print("Error parsing JS result: $e");
               setState(() => _isLoading = false);
            }
        };

        js.context.callMethod('launchCashfreeCheckout', [sessionId]);
        return;
      }
      
      // 2. Handle Windows (Mock since SDK doesn't support it)
      if (Platform.isWindows) {
        _showSnack("Cashfree SDK not supported on Windows. Using Mock Success.");
        verifyPayment(orderId); 
        return;
      }

      // 3. Handle Mobile (Android/iOS)
      // Callbacks for mobile are set in initState via cfPaymentGatewayService.setCallback
      var session = CFSessionBuilder()
          .setEnvironment(AppConstants.cashfreeEnvironment == 'PRODUCTION' ? CFEnvironment.PRODUCTION : CFEnvironment.SANDBOX) 
          .setOrderId(orderId)
          .setPaymentSessionId(sessionId)
          .build();
      
      var cfDropCheckoutPayment = CFDropCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      cfPaymentGatewayService.doPayment(cfDropCheckoutPayment);

    } catch (e) {
        print("Cashfree Launch Error: $e");
        _showSnack("Failed to launch payment gateway: $e");
        setState(() => _isLoading = false);
    }
  }

  void onError(CFErrorResponse errorResponse, String orderId) {
    print("Payment Error for $orderId: ${errorResponse.getMessage()}");
    _showSnack("Payment Error: ${errorResponse.getMessage()}");
    setState(() => _isLoading = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccessDialog(dynamic orderId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OrderSuccessScreen(orderId: orderId.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final cartTotal = appState.cartItems.fold(0.0, (sum, item) => sum + (appState.getPrice(item.price) * item.quantity));
    final shippingDisplay = appState.getPrice(_shippingCost);
    final grandTotal = cartTotal + shippingDisplay;
    
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: const Text("Checkout Securely", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_savedAddresses.isNotEmpty) ...[
                      _buildSectionTitle("Saved Addresses"),
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _savedAddresses.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                             if (index == _savedAddresses.length) {
                               return _buildAddAddressCard();
                             }
                             return _buildAddressCard(_savedAddresses[index]);
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                  ],

                  _buildSectionTitle("Contact Information"),
                  _buildCardLayout([
                     _buildTextField("Full Name", _nameController, Icons.person, (v) => v!.isEmpty ? "Required" : null),
                     const SizedBox(height: 16),
                     Row(
                       children: [
                         Expanded(child: _buildTextField("Phone Number", _phoneController, Icons.phone, (v) => v!.length < 10 ? "Invalid Phone" : null, inputType: TextInputType.phone)),
                         const SizedBox(width: 16),
                         Expanded(child: _buildTextField("Email (Optional)", _emailController, Icons.email, null, inputType: TextInputType.emailAddress)),
                       ],
                     ),
                  ]),
                  
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle("Shipping Address"),
                  _buildCardLayout([
                      // Country Input Field
                      TextFormField(
                        controller: _countryController,
                        autofillHints: const [AutofillHints.countryName],
                        decoration: InputDecoration(
                           labelText: "Country",
                           prefixIcon: const Icon(Icons.public, color: Colors.grey, size: 20),
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                           enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                           focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2)),
                           filled: true,
                           fillColor: Colors.grey.shade50,
                           suffixIcon: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               if (_countryController.text.isNotEmpty)
                                 IconButton(
                                   icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                                   onPressed: () {
                                     _countryController.clear();
                                     setState(() => _selectedCountry = '');
                                     _calculateShipping();
                                   },
                                 ),
                               if (_selectedCountry.isNotEmpty)
                                 const Padding(
                                   padding: EdgeInsets.only(right: 12.0),
                                   child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                                 ),
                             ],
                           ),
                           helperText: _countries.isEmpty ? "Loading countries..." : "Type to search (e.g. India, UAE)",
                        ),
                        validator: (v) => _selectedCountry.isEmpty ? "Please enter a valid country" : null,
                        onChanged: (value) {
                           // Smart Match Logic
                           final input = value.trim().toLowerCase();
                           if (input.isEmpty) {
                             setState(() => _selectedCountry = '');
                             return;
                           }
                           
                           // Priority 1: Exact Match
                           var match = _countries.firstWhere(
                             (c) => (c['name'] ?? '').toString().toLowerCase() == input, 
                             orElse: () => {}
                           );
                           
                           // Priority 2: Starts With
                           if (match.isEmpty) {
                              try {
                                match = _countries.firstWhere(
                                  (c) => (c['name'] ?? '').toString().toLowerCase().startsWith(input),
                                );
                              } catch (_) {}
                           }
  
                           // Priority 3: Contains (if length > 3 to avoid noise)
                           if (match.isEmpty && input.length > 3) {
                              try {
                                match = _countries.firstWhere(
                                  (c) => (c['name'] ?? '').toString().toLowerCase().contains(input),
                                );
                              } catch (_) {}
                           }
                           
                           if (match.isNotEmpty) {
                              setState(() {
                                 _selectedCountry = match['code'];
                              });
                           } else {
                              setState(() => _selectedCountry = '');
                           }
                        },
                      ),
                      if (_selectedCountry.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              "Matched: ${_countries.firstWhere((c) => c['code'] == _selectedCountry, orElse: () => {'name': 'Unknown'})['name']}", 
                              style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)
                            ),
                          ),
                     const SizedBox(height: 16),
                     
                     // Pincode with Loader
                     Stack(
                       children: [
                         _buildTextField("Pincode / Zip Code", _pincodeController, Icons.pin_drop, (v) => v!.length < 4 ? "Invalid Pincode" : null, 
                           inputType: TextInputType.number,
                           onChanged: _onPincodeChanged
                         ),
                         if (_isDetectingLocation)
                            const Positioned(right: 16, top: 16, child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                       ],
                     ),
                     if (_selectedCountry == 'IN')
                       const Padding(
                         padding: EdgeInsets.only(left: 4.0, top: 4.0),
                         child: Text("Enter Pincode to auto-detect State & City", style: TextStyle(fontSize: 12, color: AppTheme.primaryPurple)),
                       ),
                     const SizedBox(height: 16),
                     
                     Row(
                       children: [
                         Expanded(child: _buildTextField("State", _stateController, Icons.map, (v) => v!.isEmpty ? "Required" : null)),
                         const SizedBox(width: 16),
                         Expanded(child: _buildTextField("City / District", _cityController, Icons.location_city, (v) => v!.isEmpty ? "Required" : null)),
                       ],
                     ),
                     const SizedBox(height: 16),
                     
                     _buildTextField("Address (House No, Building, Street)", _addressController, Icons.home, (v) => v!.isEmpty ? "Required" : null, maxLines: 2),
                      
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: _saveForNextTime, 
                        onChanged: (v) => setState(() => _saveForNextTime = v!),
                        title: const Text("Save this address for future orders"),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppTheme.primaryPurple,
                      ),
                  ]),

                  const SizedBox(height: 32),

                  _buildSectionTitle("Payment Method"),
                  _buildCardLayout([
                    RadioListTile<String>(
                      value: 'COD',
                      groupValue: _paymentMethod,
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                      title: const Text("Cash on Delivery (COD)", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Pay when you receive your order"),
                      activeColor: AppTheme.primaryPurple,
                      secondary: const Icon(Icons.money, color: Colors.green),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    RadioListTile<String>(
                      value: 'Prepaid',
                      groupValue: _paymentMethod,
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                      title: const Text("Online Payment", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("UPI, Cards, Netbanking (Secure)"),
                      activeColor: AppTheme.primaryPurple,
                      secondary: const Icon(Icons.credit_card, color: Colors.blue),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ]),
                  
                  const SizedBox(height: 40),
                  
                  // Summary & Button
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: Colors.grey.shade200),
                       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                     ),
                     child: Column(
                       children: [
                         _buildSummaryRow("Subtotal", "${appState.currencySymbol}${cartTotal.toStringAsFixed(2)}"),
                         const SizedBox(height: 12),
                          // Only show shipping if calculated, else show "Calculating..." or "Enter Address"
                          _buildSummaryRow("Shipping", 
                             _isDetectingLocation 
                                 ? "Calculating..." 
                                 : (_shippingCost == 0 && _stateController.text.isNotEmpty) 
                                     ? "Free" 
                                     : "${appState.currencySymbol}${shippingDisplay.toStringAsFixed(2)}"
                          ), // Fixed to use shippingDisplay for localized price
                         const Divider(height: 32),
                         _buildSummaryRow("Total", "${appState.currencySymbol}${grandTotal.toStringAsFixed(2)}", isTotal: true),
                         const SizedBox(height: 24),
                         SizedBox(
                           width: double.infinity,
                           child: ElevatedButton(
                             onPressed: _isLoading || _isDetectingLocation ? null : _placeOrder,
                             style: ElevatedButton.styleFrom(
                               backgroundColor: AppTheme.primaryPurple,
                               foregroundColor: Colors.white,
                               padding: const EdgeInsets.symmetric(vertical: 20),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                             child: _isLoading 
                               ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                               : const Text("PLACE ORDER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                           ),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> addr) {
    final isSelected = _selectedAddressId == addr['id'];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _fillAddressForm(addr),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryPurple.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppTheme.primaryPurple : Colors.grey.shade300, width: isSelected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Icon(Icons.location_on, size: 16, color: isSelected ? AppTheme.primaryPurple : Colors.grey),
                   const SizedBox(width: 8),
                   Expanded(child: Text(addr['name'] ?? 'Home', style: const TextStyle(fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis))),
                   if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryPurple, size: 16)
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  "${addr['address_line1']}\n${addr['city'] ?? ''}, ${addr['state']}\n${addr['pincode']}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.fade,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                addr['phone'] ?? '',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAddAddressCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _clearForm,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 140, // Smaller width for "Add"
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.grey.shade400, size: 32),
                const SizedBox(height: 8),
                Text("Add New", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _fillAddressForm(Map<String, dynamic> addr) {
    setState(() {
       _selectedAddressId = addr['id'];
       _nameController.text = addr['name'] ?? '';
       _phoneController.text = addr['phone'] ?? '';
       _addressController.text = addr['address_line1'] ?? '';
       if (addr['address_line2'] != null && addr['address_line2'].toString().isNotEmpty) {
          _addressController.text += ", ${addr['address_line2']}";
       }
       _cityController.text = addr['city'] ?? addr['district'] ?? '';
       _stateController.text = addr['state'] ?? '';
       _pincodeController.text = addr['pincode'] ?? '';
       
       String c = addr['country'] ?? 'IN';
       _selectedCountry = c;
       // Try to find name map
       try {
         final cObj = _countries.firstWhere((e) => e['code'] == c || e['name'] == c, orElse: () => {});
         if (cObj.isNotEmpty) {
           _selectedCountry = cObj['code'];
           _countryController.text = cObj['name'];
         } else {
           _countryController.text = c;
         }
       } catch (_) {
          _countryController.text = c;
       }
       
       // Trigger calculation on fill
       _calculateShipping();
    });
  }

  void _clearForm() {
    setState(() {
       _selectedAddressId = null;
       _nameController.clear();
       _phoneController.clear();
       _addressController.clear();
       _cityController.clear();
       _stateController.clear();
       _pincodeController.clear();
    });
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildCardLayout(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
  
  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String? Function(String?)? validator, {TextInputType inputType = TextInputType.text, int maxLines = 1, Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2)),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      keyboardType: inputType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: isTotal ? 18 : 16, 
          fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          color: isTotal ? Colors.black : Colors.grey.shade600
        )),
        Text(value, style: TextStyle(
          fontSize: isTotal ? 20 : 16, 
          fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          color: isTotal ? AppTheme.primaryPurple : Colors.black87
        )),
      ],
    );
  }
}
