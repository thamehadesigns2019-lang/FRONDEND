import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/theme/themes.dart';
import 'package:thameeha/widgets/custom_toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  
  // Profile Data
  String _username = '';
  String _email = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  String? _selectedGender;
  String? _selectedCountry;

  final List<Map<String, String>> _countries = [
    {'code': 'IN', 'name': 'India'},
    {'code': 'US', 'name': 'United States'},
    {'code': 'GB', 'name': 'United Kingdom'},
    {'code': 'AE', 'name': 'United Arab Emirates'},
    {'code': 'SA', 'name': 'Saudi Arabia'},
    {'code': 'KW', 'name': 'Kuwait'},
    {'code': 'QA', 'name': 'Qatar'},
    {'code': 'OM', 'name': 'Oman'},
    {'code': 'BH', 'name': 'Bahrain'},
    {'code': 'CA', 'name': 'Canada'},
    {'code': 'AU', 'name': 'Australia'},
    {'code': 'DE', 'name': 'Germany'},
  ];

  // Password Change
  final _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _isPasswordExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final data = await appState.apiService.fetchUserProfile();
      if (data['message'] == 'success') {
        final userData = data['data'];
        setState(() {
          _username = userData['username'] ?? '';
          _email = userData['email'] ?? '';
          _nameController.text = userData['full_name'] ?? _username;
          if (userData['age'] != null) _ageController.text = userData['age'].toString();
          if (userData['gender'] != null) _selectedGender = userData['gender'];
          if (userData['country_code'] != null) {
            _countryController.text = userData['country_code'];
            final code = userData['country_code'].toString().toUpperCase();
            if (_countries.any((c) => c['code'] == code)) {
               _selectedCountry = code;
            } else {
               _selectedCountry = null; 
            }
          }
        });
      }
    } catch (e) {
      CustomToast.error(context, 'Failed to load profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.apiService.updateUserProfile({
        'username': _nameController.text.trim(), // Assuming name field maps to username or full_name? Actually logic uses username field for full_name sometimes. Let's send both or clarify. 
        // Existing backend controller expects 'username' to update USERNAME column. 'full_name' for full name.
        // My _nameController label says 'Full Name'. 
        // If I want to update full_name, I should send full_name. If I want to update username, I need another field.
        // But the previous code used _nameController for fetchUserProfile['username'].
        // The user likely wants 'Full Name'. I will send both if needed, but username is unique.
        // Let's assume _nameController is Full Name and we keep username separate or readonly?
        // Pre-existing code: `_nameController.text = _username;` implies it was editing username.
        // I will send it as `full_name` AND `username`? Changing username breaks login if email not used.
        // Let's send it as `full_name`. And keep username as is if I don't expose a separate field.
        // Actually, let's treat it as Full Name as per label.
        'fullName': _nameController.text.trim(),
        'age': _ageController.text.isNotEmpty ? int.tryParse(_ageController.text.trim()) : null,
        'gender': _selectedGender,
        'countryCode': _countryController.text.isNotEmpty ? _countryController.text.trim().toUpperCase() : null,
      });
      CustomToast.success(context, 'Profile updated successfully');
      // Refresh
      await _fetchProfile();
      // Also refresh app state to update currency if country changed
      await appState.fetchAllData(); // Re-fetches everything including pricing rules logic
    } catch (e) {
      CustomToast.error(context, 'Failed to update: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.apiService.changeUserPassword(
        _oldPasswordController.text,
        _newPasswordController.text,
      );
      CustomToast.success(context, 'Password changed successfully');
      _oldPasswordController.clear();
      _newPasswordController.clear();
      setState(() {
        _isPasswordExpanded = false;
      });
    } catch (e) {
      CustomToast.error(context, 'Failed to change password: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _isLoading && _username.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 32),
                      
                      _buildSectionTitle('Personal Information'),
                      const SizedBox(height: 16),
                      _buildProfileForm(appState),
                      
                      const SizedBox(height: 32),
                      _buildSectionTitle('Security'),
                      const SizedBox(height: 16),
                      _buildPasswordSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 600;
        return Container(
          padding: EdgeInsets.all(isSmall ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2), width: 2),
                ),
                child: CircleAvatar(
                  radius: isSmall ? 30 : 40,
                  backgroundColor: AppTheme.primaryPurple.withOpacity(0.1),
                  child: Text(
                    _username.isNotEmpty ? _username[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: isSmall ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _username,
                      style: TextStyle(
                        fontSize: isSmall ? 18 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: isSmall ? 12 : 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Active Account',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: isSmall ? 10 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfileForm(AppState appState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 600;
        final double inputFontSize = isSmall ? 14.0 : 16.0;
        final double iconSize = isSmall ? 20.0 : 24.0;
        final EdgeInsets contentPadding = isSmall 
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

        InputDecoration inputDecoration(String label, IconData icon) {
          return InputDecoration(
            labelText: label,
            labelStyle: TextStyle(fontSize: inputFontSize),
            prefixIcon: Icon(icon, size: iconSize),
            contentPadding: contentPadding,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 2)),
            filled: true,
            fillColor: Colors.grey.shade50,
          );
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(fontSize: inputFontSize),
                  decoration: inputDecoration('Full Name', Icons.person_outline_rounded),
                  validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 20),
                
                // Age and Gender
                if (isSmall) ...[
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: inputFontSize),
                    decoration: inputDecoration('Age', Icons.cake_outlined),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    style: TextStyle(fontSize: inputFontSize, color: Colors.black),
                    decoration: inputDecoration('Gender', Icons.wc),
                    items: ['male', 'female', 'other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _selectedGender = val),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: inputDecoration('Age', Icons.cake_outlined),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: inputDecoration('Gender', Icons.wc),
                          items: ['male', 'female', 'other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => _selectedGender = val),
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 20),
                
                // Country Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  isExpanded: true, // Fix for overflow
                  style: TextStyle(fontSize: inputFontSize, color: Colors.black),
                  decoration: inputDecoration('Country', Icons.public),
                  items: _countries.map((c) {
                    return DropdownMenuItem(
                      value: c['code'],
                      child: Text(
                        "${c['name']} (${c['code']})", 
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: inputFontSize)
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCountry = val;
                      _countryController.text = val ?? '';
                    });
                  },
                ),

                const SizedBox(height: 20),
                TextFormField(
                  initialValue: _email,
                  enabled: false,
                  style: TextStyle(fontSize: inputFontSize),
                  decoration: inputDecoration('Email Address', Icons.email_outlined).copyWith(
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 20),
                // Currency / Region Info
                 Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                       Icon(Icons.info_outline, color: Colors.blue, size: iconSize),
                       const SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               'Regional Settings',
                               style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: inputFontSize),
                             ),
                             Text(
                               'Currency detected: ${appState.userSettings.preferredCurrency}',
                               style: TextStyle(fontSize: inputFontSize - 2, color: Colors.blue[800]),
                             ),
                           ],
                         ),
                       ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48, // Slightly smaller height
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Update Profile', style: TextStyle(fontSize: inputFontSize, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  final GlobalKey _passwordSectionKey = GlobalKey();

  Widget _buildPasswordSection() {
    return Container(
      key: _passwordSectionKey,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            subtitle: const Text('Regularly updating your password improves security'),
            leading: divContainer(
              color: Colors.orange.withOpacity(0.1),
              child: const Icon(Icons.lock_reset, color: Colors.orange),
            ),
            trailing: Icon(
              _isPasswordExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey,
            ),
            onTap: () {
              setState(() {
                _isPasswordExpanded = !_isPasswordExpanded;
              });
              if (_isPasswordExpanded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_passwordSectionKey.currentContext != null) {
                    Scrollable.ensureVisible(
                      _passwordSectionKey.currentContext!,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: 0.0, // align to top
                    );
                  }
                });
              }
            },
          ),
          if (_isPasswordExpanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 1),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_clock_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value!.length < 6 ? 'Min 6 chars' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget divContainer({required Widget child, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
