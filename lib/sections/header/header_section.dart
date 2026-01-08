import 'package:flutter/material.dart';
import 'package:thameeha/constants.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/widgets/responsive_layout.dart';
import 'package:thameeha/widgets/product_search_bar.dart';

class HeaderSection extends StatelessWidget {
  final bool isDesktop;

  const HeaderSection({super.key, this.isDesktop = false});

  @override
  Widget build(BuildContext context) {
    // If widget.isDesktop is explicitly passed as true (from DesktopLayout), trust it
    // Otherwise fallback to ResponsiveLayout check
    final bool isDesktopView = ResponsiveLayout.isDesktop(context);
    final bool isDesktopMode = isDesktop || isDesktopView;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: isDesktopMode ? 24.0 : AppConstants.defaultPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo Section - Always Show
          Row(
            children: [
              InkWell(
                onTap: () {
                   // Navigate Home on Logo Click?
                   final appState = Provider.of<AppState>(context, listen: false);
                   if (isDesktopMode) {
                      appState.setSelectedTab(0);
                   } else {
                      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
                   }
                },
                child: Image.asset(AppConstants.logoUrl, height: 32, fit: BoxFit.contain, errorBuilder: (_,__,___) => const SizedBox()),
              ), 
              SizedBox(width: AppConstants.defaultPadding / 2),
              const Text(
                AppConstants.appName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          if (isDesktopMode) ...[
             const SizedBox(width: 48),
             // Search Bar
             Expanded(
               child: Center(
                 child: ConstrainedBox(
                   constraints: const BoxConstraints(maxWidth: 600),
                   child: const ProductSearchBar(),
                 ),
               ),
             ),
             const SizedBox(width: 48),
          ],
          
           // Right Actions
          Row(
            children: [
               // Home Icon for Desktop
               if (isDesktopMode) ...[
                 IconButton(
                   onPressed: () {
                      final appState = Provider.of<AppState>(context, listen: false);
                      appState.setSelectedTab(0);
                   },
                   icon: const Icon(Icons.home),
                   tooltip: "Home",
                 ),
                 const SizedBox(width: 8),
               ],

               IconButton(
                 onPressed: () => Navigator.pushNamed(context, '/cart'), 
                 icon: const Icon(Icons.shopping_cart),
                 tooltip: "Cart",
               ),
               
               if (Provider.of<AppState>(context).isAuthenticated) ...[
                  // Orders UI Text Button (Desktop)
                  if (isDesktopMode) ...[
                    const SizedBox(width: 24),
                    TextButton(
                      onPressed: () {
                         final appState = Provider.of<AppState>(context, listen: false);
                         Navigator.pushNamed(context, '/orders');
                      },
                      child: const Text("Orders", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ],

                  // Profile Dropdown
                  const SizedBox(width: 16),
                  PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(Icons.person, color: Colors.black, size: 20),
                        ),
                        if (isDesktopMode) ...[
                          const SizedBox(width: 8),
                          const Text("Account", style: TextStyle(fontWeight: FontWeight.bold)),
                          const Icon(Icons.arrow_drop_down),
                        ]
                      ],
                    ),
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await Provider.of<AppState>(context, listen: false).logout();
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      } else if (value == 'settings') {
                        Navigator.pushNamed(context, '/settings');
                      } else if (value == 'support') {
                        Navigator.pushNamed(context, '/support');
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings, color: Colors.grey, size: 20),
                            SizedBox(width: 12),
                            Text('Settings'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'support',
                        child: Row(
                          children: [
                            Icon(Icons.help_outline, color: Colors.grey, size: 20),
                            SizedBox(width: 12),
                            Text('Support'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red, size: 20),
                            SizedBox(width: 12),
                            Text('Logout', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),

               ] else ...[
                  const SizedBox(width: 16),
                  if (ResponsiveLayout.isMobile(context))
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      icon: const Icon(Icons.login),
                      tooltip: "Login",
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      icon: const Icon(Icons.login),
                      label: const Text("LOGIN"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
               ]
            ]
          )

        ],
      ),
    );
  }
}
