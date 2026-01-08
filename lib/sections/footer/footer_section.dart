import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/theme/themes.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Provider.of<AppState>(context, listen: false).apiService.fetchUiSection('footer'),
      builder: (context, snapshot) {
        // Defaults
        String companyName = 'Thameeha';
        String description = 'Your premium destination for fashion and lifestyle products. Quality meets innovation.';
        Map<String, String> socials = {};
        List<Map<String, String>> customLinks = [];

        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!;
          if (data['companyName'] != null && data['companyName'].toString().isNotEmpty) companyName = data['companyName'];
          if (data['description'] != null && data['description'].toString().isNotEmpty) description = data['description'];
          
          if (data['socials'] != null) {
             final s = data['socials'];
             if (s['facebook']?.isNotEmpty ?? false) socials['facebook'] = s['facebook'];
             if (s['instagram']?.isNotEmpty ?? false) socials['instagram'] = s['instagram'];
             if (s['twitter']?.isNotEmpty ?? false) socials['twitter'] = s['twitter'];
             if (s['linkedin']?.isNotEmpty ?? false) socials['linkedin'] = s['linkedin'];
             if (s['youtube']?.isNotEmpty ?? false) socials['youtube'] = s['youtube'];
          }

          if (data['links'] != null && data['links'] is List) {
             for(var l in data['links']) {
                customLinks.add({
                  'label': l['label'] ?? '',
                  'url': l['url'] ?? ''
                });
             }
          }
        }
        
        return Container(
          color: const Color(0xFF1A1A2E),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final double horizontalPadding = isMobile ? 16 : 24;
              final double topPadding = isMobile ? 32 : 60;
              final double titleSize = isMobile ? 20 : 24;
              final double descSize = isMobile ? 13 : 14; // Smaller text for mobile
              
              return Padding(
                padding: EdgeInsets.only(top: topPadding, bottom: 24, left: horizontalPadding, right: horizontalPadding),
                child: Column(
                  children: [
                    // Main Content
                    isMobile 
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCompanyInfo(companyName, description, titleSize, descSize),
                          const SizedBox(height: 32),
                          _buildLinksSection(context, customLinks),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildCompanyInfo(companyName, description, titleSize, descSize),
                          ),
                          const SizedBox(width: 40),
                          Expanded(
                            child: _buildLinksSection(context, customLinks),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 32),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 24),
                    
                    // Bottom Bar
                    isMobile
                    ? Column(
                        children: [
                          _buildSocials(socials),
                          const SizedBox(height: 16),
                          Text(
                            '© ${DateTime.now().year} $companyName. All rights reserved.',
                            style: TextStyle(color: Colors.grey[500], fontSize: 10), // Smaller copyright
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '© ${DateTime.now().year} $companyName. All rights reserved.',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                          _buildSocials(socials),
                        ],
                      ),
                  ],
                ),
              );
            }
          ),
        );
      }
    );
  }

  Widget _buildCompanyInfo(String name, String desc, double titleSize, double descSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          desc,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: descSize,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLinksSection(BuildContext context, List<Map<String, String>> customLinks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Links',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        _FooterLink('Home', onTap: () => Provider.of<AppState>(context, listen: false).setSelectedTab(0)),
        _FooterLink('Shop', onTap: () => Provider.of<AppState>(context, listen: false).setSelectedTab(1)),
        _FooterLink('About Us'), // Placeholder
        _FooterLink('Contact'),
        
        ...customLinks.map((l) => _FooterLink(l['label']!, onTap: () {})).toList(),
      ],
    );
  }

  Widget _buildSocials(Map<String, String> socials) {
     return Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          if (socials.containsKey('facebook')) _SocialIcon(Icons.facebook),
          if (socials.containsKey('instagram')) _SocialIcon(Icons.camera_alt),
          if (socials.containsKey('twitter')) _SocialIcon(Icons.alternate_email),
          if (socials.containsKey('linkedin')) _SocialIcon(Icons.business),
          if (socials.containsKey('youtube')) _SocialIcon(Icons.video_library),
        ],
     );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _FooterLink(this.text, {this.onTap});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;

  const _SocialIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}
