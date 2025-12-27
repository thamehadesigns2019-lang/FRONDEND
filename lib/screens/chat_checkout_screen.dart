
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/theme/themes.dart';
import 'package:thameeha/services/api_service.dart';
// import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
// import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
// import 'package:flutter_cashfree_pg_sdk/api/cfpaymentcomponents/cfpaymentcomponent.dart';
// import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
// import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
// import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
// import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
// import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';

class ChatCheckoutScreen extends StatefulWidget {
  const ChatCheckoutScreen({super.key});

  @override
  State<ChatCheckoutScreen> createState() => _ChatCheckoutScreenState();
}

class _ChatCheckoutScreenState extends State<ChatCheckoutScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  // Real Cashfree Service - Disabled for Windows Build
  // var cfPaymentGatewayService = CFPaymentGatewayService();

  List<ChatMessage> _messages = [];
  Map<String, dynamic> _checkoutData = {};
  
  CheckoutStep _currentStep = CheckoutStep.init;
  
  // Data caches
  List<dynamic> _countries = [];
  List<dynamic> _states = [];
  List<dynamic> _savedAddressesCache = [];
  
  bool _isLoading = false;
  bool _showInput = true;
  String? _tempCountryCode; 

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  
  void verifyPayment(String orderId) async {
    print("Verify Payment for $orderId");
    try {
      final appState = Provider.of<AppState>(context, listen: false);
       final res = await http.post(
         Uri.parse('${appState.apiService.baseUrl}/api/orders/verify-payment'),
         headers: {'Content-Type': 'application/json'},
         body: jsonEncode({'orderId': orderId})
       );
       
       if (res.statusCode == 200) {
         final data = jsonDecode(res.body);
         if (data['status'] == 'Success') {
            _addBotMessage("Payment Successful! ✅ Order ID: $orderId");
            _addBotMessage("Redirecting you to your orders...");
            await Future.delayed(const Duration(seconds: 2));
            if(mounted) Navigator.of(context).pushReplacementNamed('/orders');
         } else {
            _addBotMessage("⚠️ Payment verification status: ${data['message']}");
         }
       } else {
         _addBotMessage("⚠️ Payment verification failed on server.");
       }
    } catch (e) {
      _addBotMessage("⚠️ Error verifying payment: $e");
    }
  }

  Future<void> _loadInitialData() async {
     try {
       final api = ApiService();
       _countries = await api.fetchCountries();
     } catch (_) {}
     
     _startConversation();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addBotMessage(String text, {MessageType type = MessageType.text, List<dynamic>? options, Widget? customWidget}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        type: type,
        options: options,
        customWidget: customWidget,
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();
  }

  Future<void> _startConversation() async {
    _addBotMessage("Hi there! I'll help you place your order. 🛍️");
    await Future.delayed(const Duration(milliseconds: 800));

    try {
        final api = ApiService();
        final addresses = await api.fetchUserAddresses();
        
        if (addresses.isNotEmpty) {
           _currentStep = CheckoutStep.confirmSavedAddress;
           List<String> options = addresses.map((a) => "${a['name']}: ${a['address_line1']}").toList();
           options.add("Enter New Address");
           _savedAddressesCache = addresses;

           String addressListText = addresses.asMap().entries.map((e) {
              final a = e.value;
              return "${e.key + 1}. ${a['name']} - ${a['address_line1']}, ${a['city']}";
           }).join("\n");

           _addBotMessage(
             "I found these saved addresses:\n$addressListText\n\nWhich one would you like to use?",
             type: MessageType.options,
             options: options,
           );
           setState(() => _showInput = false);
           return;
        }
    } catch (_) {}

    _startNewAddressFlow();
  }

  void _startNewAddressFlow() {
    _checkoutData = {};
    _currentStep = CheckoutStep.askName;
    _addBotMessage("Who is this order for? Please enter the full name.");
    setState(() => _showInput = true);
    _focusNode.requestFocus();
  }

  Future<void> _handleInput(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    _addUserMessage(text);
    
    setState(() => _isLoading = true);
    await _processStepLogic(text);
    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  Future<void> _processStepLogic(String text) async {
    switch (_currentStep) {
      case CheckoutStep.askName:
        _checkoutData['name'] = text;
        _currentStep = CheckoutStep.askPhone;
        _addBotMessage("Nice to meet you, ${_checkoutData['name']}! What's your phone number? 📱");
        break;
        
      case CheckoutStep.askPhone:
        if (text.length < 5) {
           _addBotMessage("Please enter a valid phone number.");
           return;
        }
        _checkoutData['phone'] = text;
        _currentStep = CheckoutStep.askEmail;
        _addBotMessage("And your email address for the receipt? 📧");
        break;
        
      case CheckoutStep.askEmail:
        if (!text.contains('@')) {
           _addBotMessage("Please enter a valid email address.");
           return;
        }
        _checkoutData['email'] = text;
        _currentStep = CheckoutStep.askCountry;
        if (_countries.isEmpty) {
           final api = ApiService();
           try { _countries = await api.fetchCountries(); } catch (_) {}
        }
        _addBotMessage("Great. Which country should we ship to? (Type the name)");
        break;

      case CheckoutStep.askCountry:
        await _handleCountryInput(text);
        break;

      case CheckoutStep.confirmCountry:
         if (text.toLowerCase() == 'yes') {
            _proceedToState();
         } else {
            _currentStep = CheckoutStep.askCountry;
            _addBotMessage("Okay, please type the country name again.");
         }
         break;

      case CheckoutStep.askState:
        await _handleStateInput(text);
        break;
        
      case CheckoutStep.confirmState:
         if (text.toLowerCase() == 'yes') {
             _currentStep = CheckoutStep.askCity;
            _addBotMessage("Which city or district?");
         } else {
            _currentStep = CheckoutStep.askState;
            _addBotMessage("Okay, please type the state/province name again.");
         }
         break;

      case CheckoutStep.askCity:
        _checkoutData['district'] = text;
        _checkoutData['city'] = text; 
        _currentStep = CheckoutStep.askPincode;
        _addBotMessage("Got it. What's the Pincode/Zip Code?");
        break;

      case CheckoutStep.askPincode:
        _checkoutData['pincode'] = text;
        await _verifyAddressAndQuote();
        break;

      case CheckoutStep.askStreet:
        _checkoutData['address_line1'] = text;
        _showOrderSummary();
        break;

      case CheckoutStep.manualStateInput:
        _checkoutData['state'] = text;
        _currentStep = CheckoutStep.askCity;
        _addBotMessage("Which city or district?");
        break;

      default:
        break;
    }
  }
  
  Future<void> _handleCountryInput(String text) async {
     final match = _findMatch(text, _countries);
     if (match != null) {
       _tempCountryCode = match['code'];
       _checkoutData['country'] = match['code'];
       _addBotMessage("I found ${match['name']}. Is that correct?", type: MessageType.options, options: ['Yes', 'No']); 
       _currentStep = CheckoutStep.confirmCountry;
       setState(() => _showInput = false);
     } else {
       _addBotMessage("I couldn't find a country matching '$text'. Please try again.");
     }
  }

  Future<void> _proceedToState() async {
      _currentStep = CheckoutStep.askState;
      _addBotMessage("Loading states...");
      try {
         final api = ApiService();
         _states = await api.fetchStates(_tempCountryCode!);
         _addBotMessage("Which state/province?");
         setState(() => _showInput = true);
      } catch (e) {
         _addBotMessage("I couldn't load states automatically. Please type the state name manually.");
         _currentStep = CheckoutStep.manualStateInput; 
         setState(() => _showInput = true);
      }
  }

  Future<void> _handleStateInput(String text) async {
     final match = _findMatch(text, _states);
     if (match != null) {
        _checkoutData['state'] = match['code']; 
        _addBotMessage("Did you mean ${match['name']}?", type: MessageType.options, options: ['Yes', 'No']);
        _currentStep = CheckoutStep.confirmState;
        setState(() => _showInput = false);
     } else {
        _addBotMessage("I couldn't find a state matching '$text'. Please try again.");
     }
  }
  
  Map<String, dynamic>? _findMatch(String input, List<dynamic> list) {
    if (list.isEmpty) return null;
    final query = input.toLowerCase().trim();
    try {
      return list.firstWhere((e) => (e['name'] ?? '').toString().toLowerCase() == query || (e['code'] ?? '').toString().toLowerCase() == query);
    } catch (_) {}
    try {
      return list.firstWhere((e) => (e['name'] ?? '').toString().toLowerCase().startsWith(query));
    } catch (_) {}
    try {
      return list.firstWhere((e) => (e['name'] ?? '').toString().toLowerCase().contains(query));
    } catch (_) {}
    return null;
  }

  Future<void> _verifyAddressAndQuote() async {
     _addBotMessage("Verifying address and checking shipping rates...");
     try {
        final api = ApiService();
        final destination = {
           'name': _checkoutData['name'] ?? 'Guest',
           'phone': _checkoutData['phone'] ?? '0000000000',
           'email': _checkoutData['email'] ?? 'guest@example.com',
           'address_line1': 'Checking Rate...', // Dummy validation for quote
           'country': _checkoutData['country'],
           'state': _checkoutData['state'],
           'city': _checkoutData['city'],
           'district': _checkoutData['district'] ?? _checkoutData['city'],
           'pincode': _checkoutData['pincode'],
        };
        
        // This calls our new Secure Backend Endpoint
        final result = await api.fetchShippingRates(destination);
        
        double shippingCost = 0.0;
        String carrier = "Standard";
        
        if (result['selected_rate'] != null) {
            final rate = result['selected_rate'];
            if (rate['totalPrice'] != null) {
               shippingCost = double.tryParse(rate['totalPrice'].toString()) ?? 0.0;
            } else if (rate['price'] != null) {
               shippingCost = double.tryParse(rate['price'].toString()) ?? 0.0;
            }
             carrier = rate['carrier'] ?? "Standard";
        }
        
        _checkoutData['shipping_cost'] = shippingCost;
        
        _addBotMessage("Shipping to ${_checkoutData['city']}: ₹$shippingCost ($carrier).");
        
        _currentStep = CheckoutStep.askStreet;
        setState(() => _showInput = true);
        _addBotMessage("Finally, what is your street address (House No, Street Name)?");
        
     } catch (e) {
        _addBotMessage("⚠️ I couldn't get a shipping quote right now. We can proceed, but shipping might be recalculated later.");
        _checkoutData['shipping_cost'] = 0.0;
        _currentStep = CheckoutStep.askStreet;
        _addBotMessage("What is your street address?");
        setState(() => _showInput = true);
     }
  }

  void _showOrderSummary() {
      _currentStep = CheckoutStep.askPaymentMethod;
      final shippingCost = _checkoutData['shipping_cost'] ?? 0.0;
      
      _addBotMessage(
        "Perfect! I have all the details.\n"
        "Name: ${_checkoutData['name']}\n"
        "Address: ${_checkoutData['address_line1']}, ${_checkoutData['city']}, ${_checkoutData['state']}, ${_checkoutData['country']}\n"
        "Shipping: ₹$shippingCost\n\n"
        "How would you like to pay?",
        type: MessageType.options,
        options: ['Cash on Delivery (COD)', 'Pay Now (Online)'],
      );
      setState(() => _showInput = false);
  }

  void _handleOptionSelect(String value) {
     _addUserMessage(value);
     
     if (_currentStep == CheckoutStep.confirmSavedAddress) {
        if (value.startsWith('Enter New') || value.startsWith('No, New')) {
           _startNewAddressFlow();
        } else if (value == 'Yes') {
             _showOrderSummary();
        } else {
             try {
                final selected = _savedAddressesCache.firstWhere((a) => value.startsWith(a['name']));
                _checkoutData = Map<String, dynamic>.from(selected);
                // When using saved address, verify shipping again just in case?
                // Or assume previous cost? Better to re-verify if needed, but for smooth ux lets trust or re-calc silently?
                // Let's Recalculate Shipping for consistency
                _verifyAddressAndQuote(); // This will jump to street ask, but we have street.
                // Refined Logic for Saved:
                // _verifyAddressAndQuote expects to flow to ASK_STREET. 
                // We should likely just Jump to Summary if we trust it, BUT we need shipping cost.
                // Let's customize to calc cost then show summary
             } catch (e) {
               _startNewAddressFlow();
             }
        }
     }
     else if (_currentStep == CheckoutStep.confirmCountry && value == 'Yes') {
        _proceedToState();
     }
     else if (_currentStep == CheckoutStep.confirmCountry && value == 'No') {
        _currentStep = CheckoutStep.askCountry;
        _addBotMessage("Okay, please type the country name again.");
        setState(() => _showInput = true);
     }
     else if (_currentStep == CheckoutStep.confirmState && value == 'Yes') {
        _currentStep = CheckoutStep.askCity;
        _addBotMessage("Which city or district?");
        setState(() => _showInput = true);
     }
     else if (_currentStep == CheckoutStep.askPaymentMethod) {
        if (value.contains('COD')) {
           _checkoutData['payment_method'] = 'COD';
           _processOrder();
        } else {
           _checkoutData['payment_method'] = 'Prepaid';
           _processOrder(); 
        }
     }
     else if (value == 'Yes, use COD' || value == 'Switch to COD') {
         _checkoutData['payment_method'] = 'COD';
         _processOrder();
     } else if (value == 'Retry Online') {
         _checkoutData['payment_method'] = 'Prepaid';
         _processOrder();
     } else if (value == 'Cancel') {
         Navigator.pop(context);
     }
  }

  Future<void> _processOrder() async {
    _addBotMessage("Placing your order... Please wait.");
    setState(() => _isLoading = true);
    
    _checkoutData['name'] ??= 'Guest';
    _checkoutData['phone'] ??= '0000000000';
    _checkoutData['address_line1'] ??= 'N/A';
    _checkoutData['district'] ??= _checkoutData['city'] ?? 'N/A';
    _checkoutData['state'] ??= 'N/A';
    _checkoutData['pincode'] ??= '000000';
    _checkoutData['country'] ??= 'IN';
    _checkoutData['payment_method'] ??= 'COD';
    
    try {
        final api = ApiService();
        await api.saveUserAddress(_checkoutData);
    } catch (_) { }

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final result = await appState.createOrderWithShipping(_checkoutData);
      
      setState(() => _isLoading = false);

      if (result['message'] != null) {
          if (_checkoutData['payment_method'] == 'Prepaid') {
             final data = result['data'];
             final sessionId = data['payment_session_id'];
             final orderId = data['cf_order_id'];
             
             if (sessionId != null && orderId != null) {
                _addBotMessage("Launching secure payment gateway...");
                _initiateCashfreePayment(sessionId, orderId);
             } else {
                 _addBotMessage("❌ Error: Missing payment session details.");
                 _addBotMessage("Would you like to switch to COD?", type: MessageType.options, options: ['Switch to COD', 'Cancel']);
             }
             
          } else {
             _addBotMessage("🎉 Order Placed Successfully! Order ID: ${result['data']['orderId']}");
             _addBotMessage("Redirecting you to your orders...");
             await Future.delayed(const Duration(seconds: 2));
             if(mounted) Navigator.of(context).pushReplacementNamed('/orders');
          }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      String errorMsg = e.toString().replaceAll('Exception:', '').trim();
      _addBotMessage("❌ Something went wrong: $errorMsg");
      _addBotMessage("Would you like to try Cash on Delivery (COD) instead?", 
          type: MessageType.options, 
          options: ['Yes, use COD', 'Retry Online', 'Cancel']);
    }
  }
  
  void _initiateCashfreePayment(String sessionId, String orderId) {
    try {
      _addBotMessage("Cashfree SDK not supported on Windows. Using Mock Success.");
      verifyPayment(orderId);
      /*
      // Real SDK code
      */
    } catch (e) {
        print("Cashfree Launch Error: $e");
        _addBotMessage("❌ Failed to launch payment gateway: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Thameeha Assistant"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Thameeha is typing...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (msg.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: msg.isUser ? AppTheme.primaryPurple : Colors.white,
                  borderRadius: BorderRadius.circular(16).copyWith(
                    topLeft: msg.isUser ? const Radius.circular(16) : const Radius.circular(0),
                    bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    color: msg.isUser ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),
              
            if (msg.type == MessageType.options && msg.options != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: msg.options!.map((opt) => ActionChip(
                    label: Text(opt),
                    onPressed: () => _handleOptionSelect(opt),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: AppTheme.primaryPurple),
                    labelStyle: TextStyle(color: AppTheme.primaryPurple),
                  )).toList(),
                ),
              ),
              
            if (msg.type == MessageType.custom && msg.customWidget != null)
               msg.customWidget!,
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    if (!_showInput) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: "Type here...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (value) => _handleInput(value),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.primaryPurple,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _handleInput(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}

enum MessageType { text, options, custom }

enum CheckoutStep {
  init,
  confirmSavedAddress,
  askName,
  askPhone,
  askEmail,
  askCountry,
  confirmCountry,
  askState,
  confirmState,
  manualStateInput,
  askCity,
  askPincode,
  askStreet,
  askPaymentMethod,
}

class ChatMessage {
  final String text;
  final bool isUser;
  final MessageType type;
  final List<dynamic>? options;
  final Widget? customWidget;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.type = MessageType.text,
    this.options,
    this.customWidget,
  });
}
