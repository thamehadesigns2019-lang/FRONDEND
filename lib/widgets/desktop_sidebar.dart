import 'package:flutter/material.dart';
import 'package:thameeha/theme/themes.dart';

class DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(String) onMenuTap;

  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 0), // Full width items
              children: [
                _buildMenuItem(0, 'HOME', Icons.home_outlined, Icons.home, '/home'),
                _buildMenuItem(1, 'SHOP', Icons.shopping_bag_outlined, Icons.shopping_bag, '/shop'),
                _buildMenuItem(2, 'CART', Icons.shopping_cart_outlined, Icons.shopping_cart, '/cart'),
                _buildMenuItem(3, 'ORDERS', Icons.receipt_long_outlined, Icons.receipt_long, '/orders'),
                const Divider(height: 32, thickness: 1),
                _buildMenuItem(4, 'SETTINGS', Icons.settings_outlined, Icons.settings, '/settings'),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () => onMenuTap('/home'),
        borderRadius: BorderRadius.circular(8),
        child: const Row(
          mainAxisSize: MainAxisSize.min, // Constrain width for clickable area
          children: [
            Icon(Icons.shopping_bag_outlined, color: Colors.black, size: 28),
            SizedBox(width: 12),
            Text(
              'THAMEEHA',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: Colors.black,
                fontFamily: 'Serif',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(int index, String title, IconData icon, IconData activeIcon, String route) {
    final isSelected = selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onMenuTap(route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            border: isSelected 
                ? const Border(left: BorderSide(color: Colors.black, width: 4))
                : null,
            color: isSelected ? Colors.grey.shade50 : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? Colors.black : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Text(
        '© 2025 THAMEEHA',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 10,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
