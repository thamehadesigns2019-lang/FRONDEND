import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:workmanager/workmanager.dart';
import 'package:thameeha/onboarding_screen.dart';
import 'package:thameeha/constants.dart';
import 'theme/themes.dart';
import 'widgets/responsive_layout.dart';
import 'sections/header/header_section.dart';
import 'sections/hero/hero_section.dart';
import 'sections/new_arrivals/new_arrivals_section.dart';
import 'sections/features/features_section.dart';
import 'sections/footer/footer_section.dart';
import 'widgets/mobile_bottom_bar.dart';
import 'widgets/desktop_sidebar.dart';
import 'package:thameeha/screens/shop_screen.dart';
import 'package:thameeha/screens/product_detail_screen.dart';
import 'package:thameeha/screens/cart_screen.dart';
import 'package:thameeha/screens/orders_screen.dart';
import 'package:thameeha/screens/settings_screen.dart';
import 'package:thameeha/screens/help_support_screen.dart';
import 'package:thameeha/screens/checkout_screen.dart'; // Reformatted
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/screens/home_page_content.dart';
import 'package:thameeha/screens/payment_status_screen.dart';

import 'package:thameeha/screens/auth/login_screen.dart';
import 'package:thameeha/screens/auth/register_screen.dart';
import 'package:thameeha/screens/auth/forgot_password_screen.dart';
import 'package:thameeha/screens/auth/reset_password_screen.dart';
import 'package:thameeha/services/api_service.dart';
import 'package:thameeha/services/notification_manager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Native background task running: $task");
    final apiService = ApiService();
    if (await apiService.isAuthenticated()) {
      try {
        await apiService.fetchOrders();
        await apiService.fetchCartItems();
        print("Background data sync successful");
        
        // Poll for new notifications
        final notificationManager = NotificationManager(apiService);
        await notificationManager.init();
      } catch (e) {
        print("Background sync or poll failed: $e");
      }
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    await Workmanager().registerPeriodicTask(
      "1",
      "background_fetch_task",
      frequency: const Duration(minutes: 60),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
  
  final ApiService apiService = ApiService();
  final AppState appState = AppState(apiService: apiService);

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const MyPortfolioApp(),
    ),
  );

  // Fetch data in background without blocking initial build
  appState.fetchAllData();
}

class MyPortfolioApp extends StatefulWidget {
  const MyPortfolioApp({super.key});

  @override
  State<MyPortfolioApp> createState() => _MyPortfolioAppState();
}

class _MyPortfolioAppState extends State<MyPortfolioApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appState.userSettings.darkMode ? ThemeMode.dark : ThemeMode.light,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/home': (context) => const ResponsiveHomePage(initialIndex: 0),
            '/shop': (context) => const ResponsiveHomePage(initialIndex: 1),
            '/cart': (context) => const ResponsiveHomePage(initialIndex: 2),
            '/orders': (context) => const ResponsiveHomePage(initialIndex: 3),
            '/settings': (context) => const ResponsiveHomePage(initialIndex: 4),
            '/support': (context) => const ResponsiveHomePage(child: HelpSupportScreen()),
            '/checkout': (context) => const CheckoutScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name?.startsWith('/shop/') ?? false) {
              final idString = settings.name?.substring(6);
              if (idString != null && idString.isNotEmpty) {
                try {
                  final id = int.parse(idString);
                  return MaterialPageRoute(
                    builder: (context) => ResponsiveHomePage(
                      initialIndex: 1, // Stay on shop tab
                      child: ProductDetailScreen(productId: id),
                    ),
                  );
                } catch (e) {
                  print('Error parsing product ID: $e');
                }
              }
            } else if (settings.name?.startsWith('/reset-password/') ?? false) {
              final token = settings.name?.substring(17);
              if (token != null && token.isNotEmpty) {
                return MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(token: token),
                );
              }
            } else if (settings.name?.startsWith('/payment-status') ?? false) {
              final uri = Uri.parse(settings.name!);
              final orderId = uri.queryParameters['order_id'];
              if (orderId != null) {
                return MaterialPageRoute(
                  builder: (context) => PaymentStatusScreen(orderId: orderId),
                );
              }
            }
            return MaterialPageRoute(builder: (context) => const Text('Error: Unknown Route'));
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       duration: const Duration(seconds: 2),
       vsync: this,
    )..forward();

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _checkFirstTime();
  }

  void _checkFirstTime() async {
    // 1. Deep Link Check (Priority 1)
    if (mounted) {
      final currentUri = Uri.base;
      print("SplashScreen: Current URI: $currentUri");

      String? targetRoute;
      String? orderId;

      // Strategy 1: Check Fragment (Common in Flutter Web Hash Routing)
      // Example: http://host/#/payment-status?order_id=123
      if (currentUri.fragment.contains('payment-status')) {
         targetRoute = '/payment-status';
         try {
           final parts = currentUri.fragment.split('?');
           if (parts.length > 1) {
              final params = Uri.splitQueryString(parts[1]);
              orderId = params['order_id'];
           }
         } catch (e) { print("Error parsing fragment: $e"); }
      }
      
      // Strategy 2: Check Main Query Parameters (Cashfree often appends here)
      // Example: http://host/?order_id=123#/payment-status
      if (orderId == null && currentUri.queryParameters.containsKey('order_id')) {
         orderId = currentUri.queryParameters['order_id'];
         // If we found an ID but no route in fragment, assume it's a payment return
         if (targetRoute == null) targetRoute = '/payment-status';
      }

      if (targetRoute != null && orderId != null) {
        print('SplashScreen: Deep link detected ($targetRoute) for Order $orderId');
        
        // Critical: Allow a moment for the Flutter engine to stabilize visually
        await Future.delayed(const Duration(milliseconds: 100));

        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
               Navigator.of(context).pushReplacementNamed("$targetRoute?order_id=$orderId");
            }
        });
        return; // Stop further checks
      }
    }

    await Future.delayed(const Duration(seconds: 3)); // Slightly longer for premium feel

    if (!mounted) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    bool isLoggedIn = await appState.checkLoginStatus();

    if (isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

      if (isFirstTime) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3949ab), // Primary Indigo
              Color(0xFF5e35b1), // Deep Purple
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _opacity,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Container with Shadow
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.png',
                          width: 80,
                          height: 80,
                          errorBuilder: (c, o, s) => const Icon(Icons.shopping_bag, size: 60, color: Color(0xFF3949ab)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // App Name
                    const Text(
                      "Thameeha",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Premium E-Commerce",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    const CircularProgressIndicator(
                      color: Colors.white, 
                      strokeWidth: 3,
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

// --- Responsive Logic ---

class ResponsiveHomePage extends StatelessWidget {
  final int initialIndex;
  final Widget? child;

  const ResponsiveHomePage({super.key, this.initialIndex = 0, this.child});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: child != null ? child! : MobileLayout(initialIndex: initialIndex),
      tabletBody: child != null ? child! : MobileLayout(initialIndex: initialIndex),
      desktopBody: DesktopLayout(initialIndex: initialIndex, child: child),
    );
  }
}


class MobileLayout extends StatefulWidget {
  final int initialIndex;
  const MobileLayout({super.key, this.initialIndex = 0});

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  @override
  void initState() {
    super.initState();
    // Sync AppState with route's initial index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).setSelectedTab(widget.initialIndex);
    });
  }

  final List<Widget> _screens = [
    const HomePageContent(),
    const ShopScreen(),
    const CartScreen(),
    const OrdersScreen(),
    const SettingsScreen(),
  ];

  void _onNavTap(String route) {
    // Navigation logic handled by AppState now
    final appState = Provider.of<AppState>(context, listen: false);
    switch (route) {
        case '/home':
          appState.setSelectedTab(0);
          break;
        case '/shop':
          appState.setSelectedTab(1);
          break;
        case '/cart':
          appState.setSelectedTab(2);
          break;
        case '/orders':
          appState.setSelectedTab(3);
          break;
        case '/settings':
          appState.setSelectedTab(4);
          break;
      }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      body: IndexedStack(
        index: appState.selectedTabIndex,
        children: _screens,
      ),
      bottomNavigationBar: MobileBottomBar(
        selectedIndex: appState.selectedTabIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

class DesktopLayout extends StatefulWidget {
  final int initialIndex;
  final Widget? child;
  const DesktopLayout({super.key, this.initialIndex = 0, this.child});

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> {
  
  @override
  void initState() {
    super.initState();
     WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).setSelectedTab(widget.initialIndex);
    });
  }

  Widget _getScreen(int index) {
    if (widget.child != null) return widget.child!;
    
    switch (index) {
      case 0:
        return const HomePageContent(disableHeader: true);
      case 1:
        return const ShopScreen();
      case 2:
        return const CartScreen();
      case 3:
        return const OrdersScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const HomePageContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Scaffold(
      body: Column(
        children: [
          // Global Header for Desktop
          const HeaderSection(isDesktop: true),

          // Main Content Area
          Expanded(
            child: _getScreen(appState.selectedTabIndex),
          ),
        ],
      ),
    );
  }
}
