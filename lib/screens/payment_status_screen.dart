import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/theme/themes.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentStatusScreen extends StatefulWidget {
  final String orderId;
  const PaymentStatusScreen({super.key, required this.orderId});

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  bool _isLoading = true;
  bool _isSuccess = false;
  String? _errorMessage;
  String? _statusMessage; // Added new status message variable

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _verifyPaymentStatus(); // Call the renamed method
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  int _retryCount = 0;
  final int _maxRetries = 60; // Increased to 60 attempts (approx 2 mins)

  Future<void> _verifyPaymentStatus() async {
    if (_retryCount >= _maxRetries) {
      if (mounted) {
        setState(() {
          _isSuccess = false;
          _isLoading = false;
          _errorMessage = "Verification timed out. Payment might still be processing.";
          _statusMessage = "Timeout";
        });
      }
      return;
    }

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final response = await http.post(
        Uri.parse('${appState.apiService.baseUrl}/api/orders/verify-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'orderId': widget.orderId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];
        final message = data['message'] ?? '';

        if (status == 'Success') {
          if (mounted) {
            setState(() {
              _isSuccess = true;
              _isLoading = false;
              _statusMessage = "Order Placed!";
            });
            _confettiController.play(); 
            appState.clearCartLocally(); 
            appState.fetchAllData(); 

            // Auto navigate after success
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/orders', (route) => false);
              }
            });
          }
        } else if (status == 'Pending') {
          // Status is Pending, retry
          if (mounted) {
             setState(() {
               _statusMessage = "Verifying... (Attempt ${_retryCount + 1}/$_maxRetries)\n$message";
             });
          }
          await Future.delayed(const Duration(seconds: 2));
          _retryCount++;
          if (mounted) _verifyPaymentStatus();
        } else {
          // Hard Failure (e.g. 'Failed')
          if (mounted) {
            setState(() {
              _isSuccess = false;
              _isLoading = false;
              _errorMessage = message.isNotEmpty ? message : "Payment failed.";
              _statusMessage = "Payment Failed";
            });
          }
        }
      } else if (response.statusCode == 429) {
        // Rate limit exceeded - Wait longer and retry
        if (_retryCount < _maxRetries) {
           if (mounted) {
             setState(() {
               _statusMessage = "Server busy, retrying... (Attempt ${_retryCount + 1})";
             });
           }
           await Future.delayed(const Duration(seconds: 4));
           _retryCount++;
           if (mounted) _verifyPaymentStatus();
        } else {
            if (mounted) {
              setState(() {
                _isSuccess = false;
                _isLoading = false;
                _errorMessage = "Server is busy. Please check again.";
                _statusMessage = "Too Many Requests";
              });
            }
        }
      } else {
        // Server returned 400/500
        Map<String, dynamic> data = {}; 
        try {
          data = jsonDecode(response.body);
        } catch (_) {}

        if (mounted) {
          setState(() {
            _isSuccess = false;
            _isLoading = false;
            _errorMessage = data['message'] ?? "Server validation failed (Error ${response.statusCode}).";
            _statusMessage = "Server Error";
          });
        }
      }
    } catch (e) {
      // Network Error - Retry
      if (_retryCount < _maxRetries) {
          await Future.delayed(const Duration(seconds: 2));
          _retryCount++;
          if (mounted) _verifyPaymentStatus();
      } else {
          if (mounted) {
            setState(() {
              _isSuccess = false;
              _isLoading = false;
              _errorMessage = "Network error: $e";
              _statusMessage = "Connection Error";
            });
          }
      }
    }
  }

  void _manualRetry() {
    setState(() {
      _isLoading = true;
      _isSuccess = false;
      _errorMessage = null;
      _retryCount = 0; // Reset retries on manual click
    });
    _verifyPaymentStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Confetti on success
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
          
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoading) ...[
                    const CircularProgressIndicator(color: AppTheme.primaryPurple),
                    const SizedBox(height: 24),
                    const Text(
                      "Verifying Payment...",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                     Text(
                      _statusMessage ?? "Please wait...",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ] else if (_isSuccess) ...[
                    const Icon(Icons.check_circle, color: Colors.green, size: 100),
                    const SizedBox(height: 24),
                    const Text(
                      "Payment Successful! 🎉",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ] else ...[
                    const Icon(Icons.error_outline, color: Colors.red, size: 80),
                    const SizedBox(height: 24),
                    const Text(
                      "Verification Failed",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage ?? "Something went wrong.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _manualRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Check Again"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/orders'),
                      child: const Text("Go to Orders"),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
