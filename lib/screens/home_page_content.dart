import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thameeha/sections/header/header_section.dart';
import 'package:thameeha/sections/hero/hero_section.dart';
import 'package:thameeha/sections/categories/categories_section.dart';
import 'package:thameeha/sections/trending/trending_section.dart';
import 'package:thameeha/sections/new_arrivals/new_arrivals_section.dart';
import 'package:thameeha/sections/features/features_section.dart';
import 'package:thameeha/sections/footer/footer_section.dart';

import 'package:thameeha/sections/advertise/advertise_section.dart';

import 'package:thameeha/widgets/product_search_bar.dart';
import 'package:thameeha/widgets/responsive_layout.dart';

import 'package:provider/provider.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/theme/themes.dart';

class HomePageContent extends StatefulWidget {
  final bool disableHeader;
  const HomePageContent({super.key, this.disableHeader = false});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfile();
    });
  }

  void _checkProfile() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.isAuthenticated && appState.isProfileIncomplete && !_dialogShown) {
      _dialogShown = true;
      _showCompletionDialog();
    }
  }

  // --- Profile Completion Logic ---
  final List<Map<String, String>> _countries = const [
    {'code': 'IN', 'name': 'India', 'flag': '🇮🇳'},
    {'code': 'AE', 'name': 'United Arab Emirates', 'flag': '🇦🇪'},
    {'code': 'US', 'name': 'United States', 'flag': '🇺🇸'},
    {'code': 'GB', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦'},
    {'code': 'AU', 'name': 'Australia', 'flag': '🇦🇺'},
    {'code': 'SA', 'name': 'Saudi Arabia', 'flag': '🇸🇦'},
    {'code': 'QA', 'name': 'Qatar', 'flag': '🇶🇦'},
    {'code': 'KW', 'name': 'Kuwait', 'flag': '🇰🇼'},
    {'code': 'OM', 'name': 'Oman', 'flag': '🇴🇲'},
    {'code': 'BH', 'name': 'Bahrain', 'flag': '🇧🇭'},
    {'code': 'DE', 'name': 'Germany', 'flag': '🇩🇪'},
    {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
    {'code': 'IT', 'name': 'Italy', 'flag': '🇮🇹'},
    {'code': 'ES', 'name': 'Spain', 'flag': '🇪🇸'},
    {'code': 'CN', 'name': 'China', 'flag': '🇨🇳'},
    {'code': 'JP', 'name': 'Japan', 'flag': '🇯🇵'},
  ];

  // Replaced with specific Page Route below
  void _showCompletionDialog() {
       Navigator.of(context).push(
         MaterialPageRoute(
           fullscreenDialog: true,
           builder: (context) => _ProfileCompletionPage(countries: _countries),
         ),
       );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes to re-check if needed, but avoid infinite loops
    // We used checking in initState. If auth state changes later (e.g. log in), widget might rebuild or not (if kept in stack).
    // Main main.dart rebuilds ResponsiveLayout -> HomePageContent.
    // So initState will run again if widget is recreated.
    // Better to use Consumer or check in build?
    // Checking in build can cause issue during build phase (showing dialog).
    // PostFrameCallback is safer.
    
    // Header Logic:
    final bool isDesktop = ResponsiveLayout.isDesktop(context);
    final bool showHeader = !widget.disableHeader && !isDesktop;

    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            if (showHeader) const HeaderSection(),

             // Mobile Search Bar (Only valid if NOT desktop)
            if (!isDesktop) 
               Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const ProductSearchBar(isMobile: true),
               ),

            const HeroSection(),
            AdvertiseSection(),
            CategoriesSection(),
            TrendingSection(),
            NewArrivalsSection(),
            FeaturesSection(),
            FooterSection(),
          ],
        ),
      ),
    );
  }
}

class _ProfileCompletionPage extends StatefulWidget {
  final List<Map<String, String>> countries;

  const _ProfileCompletionPage({required this.countries});

  @override
  State<_ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<_ProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  
  String? _selectedCountryCode;
  String? _selectedCountryName;
  String? _selectedFlag;
  
  String? _gender;
  bool _isLoading = false;
  bool _submitted = false;

  void _autoDetectCountry() {
       try {
         final locale = View.of(context).platformDispatcher.locale;
         final countryCode = locale.countryCode?.toUpperCase();
         if (countryCode != null) {
           final country = widget.countries.firstWhere(
             (c) => c['code'] == countryCode,
             orElse: () => {'code': countryCode, 'name': 'Detected ($countryCode)', 'flag': '🏳️'},
           );
           setState(() {
             _selectedCountryCode = country['code'];
             _selectedCountryName = country['name'];
             _selectedFlag = country['flag'];
           });
         }
       } catch (e) {
         print("Auto detect error: $e");
       }
  }

  void _showCountryPicker(BuildContext context, Function(Map<String, String>) onSelect) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return _CountryPickerSheet(countries: widget.countries, onSelect: onSelect);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Complete Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(onPressed: ()=>Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.black)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_pin_rounded, size: 48, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Help us personalize your experience.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 32),

                // Country Selector
                const Text("Country", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                     _showCountryPicker(context, (selected) {
                       setState(() {
                          _selectedCountryCode = selected['code'];
                          _selectedCountryName = selected['name'];
                          _selectedFlag = selected['flag'];
                       });
                     });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        if (_selectedFlag != null) ...[
                          Text(_selectedFlag!, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            _selectedCountryName ?? "Select your country",
                            style: TextStyle(
                              color: _selectedCountryName == null ? Colors.grey[500] : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                if (_submitted && _selectedCountryCode == null)
                   Padding(
                     padding: const EdgeInsets.only(top: 6, left: 4),
                     child: Text("Please select a country", style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                   ),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _autoDetectCountry,
                    icon: const Icon(Icons.my_location, size: 16),
                    label: const Text("Auto Detect", style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Age Field
                const Text("Age", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "Ex. 24",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  autovalidateMode: _submitted ? AutovalidateMode.always : AutovalidateMode.disabled,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "Required";
                    if (int.tryParse(v.trim()) == null) return "Invalid";
                    return null; 
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Gender Field
                const Text("Gender", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _gender,
                  items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e.toLowerCase(), child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _gender = v),
                  decoration: InputDecoration(
                    hintText: "Select",
                    filled: true,
                    fillColor: Colors.grey[50], 
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                  ),
                  validator: (v) => v == null ? "Required" : null,
                ),

                const SizedBox(height: 48),

                // Action Button
                if (_isLoading)
                   const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                else
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                       onPressed: () async {
                         setState(() => _submitted = true);

                         if (_formKey.currentState!.validate() && _selectedCountryCode != null) {
                           setState(() => _isLoading = true);
                           try {
                             final appState = Provider.of<AppState>(context, listen: false);
                             await appState.apiService.updateUserProfile({
                               'countryCode': _selectedCountryCode,
                               'age': int.tryParse(_ageController.text.trim()),
                               'gender': _gender
                             });
                             await appState.fetchAllData(); 
                             if (context.mounted) {
                               Navigator.pop(context);
                             }
                           } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                           } finally {
                             if (context.mounted) setState(() => _isLoading = false);
                           }
                         }
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.black,
                         foregroundColor: Colors.white,
                         elevation: 0,
                         padding: const EdgeInsets.symmetric(vertical: 18),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                       ),
                       child: const Text("Save & Continue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                     ),
                   ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final List<Map<String, String>> countries;
  final Function(Map<String, String>) onSelect;

  const _CountryPickerSheet({required this.countries, required this.onSelect});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filteredCountries = [];

  @override
  void initState() {
    super.initState();
    _filteredCountries = widget.countries;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCountries = widget.countries.where((c) {
        return c['name']!.toLowerCase().contains(query) || c['code']!.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Select Country",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    hintText: "Search country...",
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _filteredCountries.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final country = _filteredCountries[index];
                    return ListTile(
                      onTap: () {
                        widget.onSelect(country);
                        Navigator.pop(context);
                      },
                      leading: Text(country['flag']!, style: const TextStyle(fontSize: 30)), // Increased for visibility
                      title: Text(country['name']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Text(country['code']!, style: TextStyle(color: Colors.grey[400])),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}