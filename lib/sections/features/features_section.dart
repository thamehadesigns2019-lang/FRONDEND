import 'package:flutter/material.dart';
import 'package:thameeha/theme/themes.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 40,
        horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 24,
      ),
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive grid layout
          int crossAxisCount;
          double childAspectRatio;
          double spacing;
          
          if (constraints.maxWidth < 600) {
            // Mobile: 2 columns (changed from 1)
            crossAxisCount = 2;
            childAspectRatio = 0.9; // More square-like
            spacing = 12;
          } else if (constraints.maxWidth < 900) {
            // Tablet: 2 columns
            crossAxisCount = 2;
            childAspectRatio = 1.5;
            spacing = 20;
          } else {
            // Desktop: 4 columns
            crossAxisCount = 4;
            childAspectRatio = 1.0;
            spacing = 24;
          }
          
          return GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
            children: const [
              _FeatureCard(
                icon: Icons.local_shipping_outlined,
                title: 'Free Shipping',
                description: 'On all orders over \$50',
                color: AppTheme.primaryPurple,
              ),
              _FeatureCard(
                icon: Icons.support_agent_outlined,
                title: '24/7 Support',
                description: 'We are here to help',
                color: AppTheme.accentCyan,
              ),
              _FeatureCard(
                icon: Icons.verified_user_outlined,
                title: 'Secure Payment',
                description: '100% secure checkout',
                color: AppTheme.successGreen,
              ),
              _FeatureCard(
                icon: Icons.refresh_outlined,
                title: 'Easy Returns',
                description: '30 days return policy',
                color: AppTheme.accentPink,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: isMobile ? 24 : 32),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14 : 16,
            ),
          ),
          SizedBox(height: isMobile ? 4 : 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isMobile ? 12 : 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
