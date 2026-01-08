import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/theme/themes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isOtpLogin = false; // Toggle between Password and OTP login
  bool _isOtpSent = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
    
    // Pre-fill test credentials for easy testing
    _usernameController.text = '4lfasbadar@gmail.com';
    _passwordController.text = 'btcinr100k';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleLoginMode() {
    setState(() {
      _isOtpLogin = !_isOtpLogin;
      _isOtpSent = false;
      _errorMessage = null;
      _otpController.clear();
      _passwordController.clear();
    });
  }

  Future<void> _sendOtp() async {
    if (_usernameController.text.isEmpty || !_usernameController.text.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid email address.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.sendOtp(_usernameController.text);
      setState(() {
        _isOtpSent = true;
        _errorMessage = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent! Check server console.')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      // OTP Mode Logic
      if (_isOtpLogin) {
        if (!_isOtpSent) {
          await _sendOtp();
          return;
        }
        if (_otpController.text.isEmpty) {
          setState(() {
            _errorMessage = 'Please enter the OTP.';
          });
          return;
        }
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final appState = Provider.of<AppState>(context, listen: false);
        if (_isOtpLogin) {
          await appState.loginWithOtp(_usernameController.text, _otpController.text);
        } else {
          await appState.login(_usernameController.text, _passwordController.text);
        }
        
        if (appState.isAuthenticated) {
          if (mounted) Navigator.of(context).pushReplacementNamed('/home');
        } else {
          setState(() {
            _errorMessage = 'Login failed. Please check your credentials.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo and title
                    const Center(
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 60,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Text(
                      "WELCOME BACK",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isOtpLogin ? "Sign in with OTP" : "Sign in to continue shopping",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Username/Email field
                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.black),
                            enabled: !(_isOtpLogin && _isOtpSent),
                            decoration: InputDecoration(
                              labelText: _isOtpLogin ? 'EMAIL ADDRESS' : 'USERNAME OR EMAIL',
                              prefixIcon: Icon(
                                _isOtpLogin ? Icons.email_outlined : Icons.person_outline, 
                                color: Colors.black
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return _isOtpLogin ? 'Please enter your email' : 'Please enter your username or email';
                              }
                              if (_isOtpLogin && !value.contains('@')) {
                                return 'Please enter a valid email for OTP login';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Password field (Only if NOT OTP login)
                          if (!_isOtpLogin) ...[
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                labelText: 'PASSWORD',
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.black),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            
                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/forgot-password');
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // OTP Field (Only if OTP login AND sent)
                          if (_isOtpLogin && _isOtpSent) ...[
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.black),
                              decoration: const InputDecoration(
                                labelText: 'ENTER 6-DIGIT OTP',
                                prefixIcon: Icon(Icons.lock_clock_outlined, color: Colors.black),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the OTP';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          const SizedBox(height: 20),

                          // Error message
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                border: Border.all(color: Colors.red.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _isOtpLogin 
                                        ? (_isOtpSent ? 'VERIFY & LOGIN' : 'SEND OTP') 
                                        : 'SIGN IN',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                            ),
                          ),

                          // Toggle Login Mode Button
                          Padding(
                            padding: const EdgeInsets.only(top: 24.0),
                            child: Center(
                              child: TextButton(
                                onPressed: _isLoading ? null : _toggleLoginMode,
                                child: Text(
                                  _isOtpLogin ? 'Login with Password' : 'Login with OTP',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          
                           // Register link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "New user? ",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushNamed('/register');
                                },
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
