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
          padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
          color: const Color(0xFF1A1A2E),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                            Text(
                              companyName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey[400],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
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
                        _FooterLink('About Us'), // Hardcoded basic links
                        _FooterLink('Contact'),
                        
                        // Dynamic Links
                        ...customLinks.map((l) => _FooterLink(l['label']!, onTap: () {
                           // Launch URL if needed, for now just a spacer
                        })).toList(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Divider(color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© ${DateTime.now().year} $companyName. All rights reserved.',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      if (socials.containsKey('facebook')) _SocialIcon(Icons.facebook),
                      if (socials.containsKey('facebook')) const SizedBox(width: 12),
                      
                      if (socials.containsKey('instagram')) _SocialIcon(Icons.camera_alt),
                      if (socials.containsKey('instagram')) const SizedBox(width: 12),
                      
                      if (socials.containsKey('twitter')) _SocialIcon(Icons.alternate_email),
                      if (socials.containsKey('twitter')) const SizedBox(width: 12),
                      
                      if (socials.containsKey('linkedin')) _SocialIcon(Icons.business),
                      if (socials.containsKey('linkedin')) const SizedBox(width: 12),

                      if (socials.containsKey('youtube')) _SocialIcon(Icons.video_library),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }
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
