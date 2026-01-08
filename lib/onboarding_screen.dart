import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thameeha/constants.dart';
import 'package:thameeha/theme/themes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "icon": Icons.shopping_bag_rounded,
      "gradient": const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      ),
      "title": "Welcome to Thameeha",
      "description": "Discover amazing products and deals tailored just for you. Your perfect shopping experience starts here."
    },
    {
      "icon": Icons.search_rounded,
      "gradient": const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
      ),
      "title": "Shop Smarter, Not Harder",
      "description": "Browse, compare, and purchase with ease from anywhere. Find exactly what you need in seconds."
    },
    {
      "icon": Icons.lock_rounded,
      "gradient": const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
      ),
      "title": "Fast and Secure Checkout",
      "description": "Enjoy a seamless and secure shopping experience every time with our encrypted payment system."
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.lightBg,
              Colors.grey.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: onboardingData.length,
                  itemBuilder: (context, index) => FadeTransition(
                    opacity: _fadeAnimation,
                    child: OnboardingPage(
                      icon: onboardingData[index]["icon"],
                      gradient: onboardingData[index]["gradient"],
                      title: onboardingData[index]["title"],
                      description: onboardingData[index]["description"],
                    ),
                  ),
                ),
              ),
              
              // Bottom section with dots and button
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        onboardingData.length,
                        (index) => _buildDot(index),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _currentPage == onboardingData.length - 1
                            ? _completeOnboarding
                            : () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: AppTheme.primaryPurple.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == onboardingData.length - 1
                                  ? "Get Started"
                                  : "Next",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == onboardingData.length - 1
                                  ? Icons.arrow_forward_rounded
                                  : Icons.arrow_forward_ios_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 32 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppTheme.primaryPurple
            : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(4),
        boxShadow: _currentPage == index
            ? [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.icon,
    required this.gradient,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive sizing logic
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 700; // Adjust breakpoint as needed

    final double containerSize = isCompact ? 140 : 200;
    final double iconSize = isCompact ? 70 : 100;
    final double titleSize = isCompact ? 22 : 28;
    final double descSize = isCompact ? 14 : 16;
    final double gap = isCompact ? 24 : 48;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon card with gradient
              Container(
                width: containerSize,
                height: containerSize,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(isCompact ? 24 : 32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: isCompact ? 20 : 30,
                      spreadRadius: isCompact ? 3 : 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: gap),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: descSize,
                  color: Colors.grey.shade700,
                  height: 1.6,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
