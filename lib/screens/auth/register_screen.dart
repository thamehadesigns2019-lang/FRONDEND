import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/theme/themes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOtpSent = false;

  // Controllers
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _countryController = TextEditingController(); // User types country name
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  
  String? _selectedGender;
  String? _matchedCountryCode; // Stores the detected ISO code (e.g., 'IN')

  // Form Keys for validation per step
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();
  final _step4Key = GlobalKey<FormState>();
  final _step5Key = GlobalKey<FormState>(); // OTP Step

  // Country Data (Name -> Code)
  // Included a comprehensive list for "smart matching"
  final Map<String, String> _countryMap = {
    'india': 'IN', 'united states': 'US', 'usa': 'US', 'united kingdom': 'GB', 'uk': 'GB',
    'united arab emirates': 'AE', 'uae': 'AE', 'canada': 'CA', 'australia': 'AU',
    'germany': 'DE', 'france': 'FR', 'italy': 'IT', 'spain': 'ES', 'china': 'CN',
    'japan': 'JP', 'south korea': 'KR', 'brazil': 'BR', 'russia': 'RU',
    'saudi arabia': 'SA', 'singapore': 'SG', 'malaysia': 'MY', 'thailand': 'TH',
    'indonesia': 'ID', 'vietnam': 'VN', 'philippines': 'PH', 'egypt': 'EG',
    'south africa': 'ZA', 'nigeria': 'NG', 'kenya': 'KE', 'mexico': 'MX',
    'argentina': 'AR', 'chile': 'CL', 'colombia': 'CO', 'peru': 'PE',
    'turkey': 'TR', 'pakistan': 'PK', 'bangladesh': 'BD', 'sri lanka': 'LK',
    'nepal': 'NP', 'qatar': 'QA', 'oman': 'OM', 'kuwait': 'KW', 'bahrain': 'BH',
    // Add more as needed
  };

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _countryController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validate current step before moving
    bool isValid = false;
    switch (_currentStep) {
      case 0:
        isValid = _step1Key.currentState!.validate();
        break;
      case 1:
        isValid = _step2Key.currentState!.validate();
        break;
      case 2:
        isValid = _step3Key.currentState!.validate();
        break;
      case 3:
        isValid = _step4Key.currentState!.validate();
        // If password step is valid, trigger OTP send
        if (isValid) _initiateRegistration(); 
        return; // Don't manually move page, _initiateRegistration handles it
      case 4:
         // Final OTP step handled by verify button
         break;
    }

    if (isValid && _currentStep < 4) {
      setState(() => _errorMessage = null);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _errorMessage = null);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  String? _findCountryCode(String input) {
    if (input.isEmpty) return null;
    final normalized = input.trim().toLowerCase();
    
    // Direct match
    if (_countryMap.containsKey(normalized)) return _countryMap[normalized];
    
    // Partial Match logic (optional, for better UX)
    for (var key in _countryMap.keys) {
      if (key.startsWith(normalized)) return _countryMap[key];
    }
    return null;
  }

  Future<void> _initiateRegistration() async {
     setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      // We send OTP first to verify email.
      // Note: Backend usually handles checking if email exists.
      await appState.sendOtp(_emailController.text);
      
      setState(() {
        _isOtpSent = true;
        _isLoading = false;
        // Move to OTP step
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        _currentStep = 4;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to your email!')),
        );
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _completeRegistration() async {
    if (!_step5Key.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Since Username is required by backend but not in our new flow, 
      // we auto-generate it from email or name.
      String generatedUsername = _emailController.text.split('@')[0];
      
      await appState.register(
        generatedUsername,
        _emailController.text,
        _passwordController.text,
        _otpController.text,
        fullName: _fullNameController.text,
        age: int.tryParse(_ageController.text),
        gender: _selectedGender,
        countryCode: _matchedCountryCode ?? 'IN', // Fallback to IN if match fails eventually
      );

      if (appState.isAuthenticated) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      } else {
         throw Exception("Registration failed.");
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome", style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text("Let's get to know you.", style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 40),
          
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(labelText: 'Full Name'),
            validator: (v) => v!.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email Address'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v!.isEmpty || !v.contains('@')) ? 'Valid email required' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone Number (Optional)'),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("About You", style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text("Help us personalize your experience.", style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 40),

          TextFormField(
            controller: _ageController,
            decoration: const InputDecoration(labelText: 'Age'),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Age is required';
              final n = int.tryParse(v);
              if (n == null || n < 13) return 'Must be at least 13';
              return null;
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: ['Male', 'Female', 'Other'].map((g) => 
              DropdownMenuItem(value: g.toLowerCase(), child: Text(g))
            ).toList(),
            onChanged: (v) => setState(() => _selectedGender = v),
            validator: (v) => v == null ? 'Please select gender' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Form(
      key: _step3Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text("Your Location", style: Theme.of(context).textTheme.displayMedium),
           const SizedBox(height: 8),
           Text("Where are you shopping from?", style: Theme.of(context).textTheme.bodyLarge),
           const SizedBox(height: 40),

           TextFormField(
             controller: _countryController,
             decoration: const InputDecoration(
               labelText: 'Country Name',
               hintText: 'e.g. United States, India',
             ),
             onChanged: (val) {
               // Real-time matching logic
               setState(() {
                 _matchedCountryCode = _findCountryCode(val);
               });
             },
             validator: (val) {
               if (val == null || val.isEmpty) return 'Please enter your country';
               if (_matchedCountryCode == null) return 'We couldn\'t identify this country. Try standard spelling.';
               return null;
             },
           ),
           const SizedBox(height: 10),
           if (_countryController.text.isNotEmpty)
             AnimatedSwitcher(
               duration: const Duration(milliseconds: 300),
               child: _matchedCountryCode != null
                   ? Row(
                       key: ValueKey(_matchedCountryCode),
                       children: [
                         const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 20),
                         const SizedBox(width: 8),
                         Text(
                           "Code identified: $_matchedCountryCode",
                           style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold),
                         ),
                       ],
                     )
                   : const Row(
                       children: [
                          Icon(Icons.error_outline, color: AppTheme.warningOrange, size: 20),
                          SizedBox(width: 8),
                          Text("Searching...", style: TextStyle(color: Colors.grey)),
                       ],
                   ),
             ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return Form(
      key: _step4Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Security", style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text("Create a strong password.", style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 40),

          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirm Password'),
            validator: (v) {
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return Form(
      key: _step5Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Verification", style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text("Enter the OTP sent to ${_emailController.text}", style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 40),

          TextFormField(
            controller: _otpController,
            decoration: const InputDecoration(
              labelText: '6-Digit One Time Password',
              // letterSpacing is not a valid property of InputDecoration directly 
              // To change letter spacing of the INPUT text, use style property of TextFormField
            ),
            style: const TextStyle(letterSpacing: 2.0), // MOVED HERE
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (v) => (v == null || v.length != 6) ? 'Invalid OTP' : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine button text based on step
    String buttonText = "Continue";
    if (_currentStep == 3) buttonText = "Send OTP"; 
    
    return Scaffold(
      appBar: AppBar(
         leading: IconButton(
           icon: const Icon(Icons.arrow_back),
           onPressed: _previousStep,
         ),
         elevation: 0,
         backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
             // Progress Indicator
             LinearProgressIndicator(
               value: (_currentStep + 1) / 5,
               backgroundColor: Colors.grey.shade200,
               valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
               minHeight: 4,
             ),
             
             Expanded(
               child: PageView(
                 controller: _pageController,
                 physics: const NeverScrollableScrollPhysics(), // Disable swipe
                 children: [
                    Padding(padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: _buildStep1())),
                    Padding(padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: _buildStep2())),
                    Padding(padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: _buildStep3())),
                    Padding(padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: _buildStep4())),
                    Padding(padding: const EdgeInsets.all(24), child: SingleChildScrollView(child: _buildStep5())),
                 ],
               ),
             ),
             
             // Error Message Area
             if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Text(
                    _errorMessage!, 
                    style: const TextStyle(color: AppTheme.errorRed),
                    textAlign: TextAlign.center,
                  ),
                ),

             // Bottom Buttons
             Padding(
               padding: const EdgeInsets.all(24.0),
               child: Row(
                 children: [
                   if (_currentStep == 4) 
                     Expanded(
                       child: OutlinedButton(
                         onPressed: _isLoading ? null : () {
                            // Resend Logic
                            _initiateRegistration();
                         },
                         child: const Text("Resend OTP"),
                       ),
                     ),
                    
                    if (_currentStep == 4)  const SizedBox(width: 16),

                   Expanded(
                     flex: 2,
                     child: ElevatedButton(
                       onPressed: _isLoading ? null : (_currentStep == 4 ? _completeRegistration : _nextStep),
                       child: _isLoading 
                         ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                         : Text(_currentStep == 4 ? "Verify & Finish" : buttonText),
                     ),
                   ),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }
}
