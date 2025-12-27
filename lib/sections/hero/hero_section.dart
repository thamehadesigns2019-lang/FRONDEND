import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/theme/themes.dart';
import 'package:thameeha/constants.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.easeOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.easeOut)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: Provider.of<AppState>(context, listen: false).apiService.fetchUiSection('hero'),
      builder: (context, snapshot) {
        final style = snapshot.data?['style'] ?? 'single';
        final List<dynamic> images = List.from(snapshot.data?['images'] ?? []);

        return Container(
          height: isMobile ? 450 : 600,
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            children: [
              // Background Layer (Images)
              if (style == 'collage')
                _buildCollageLayout(images, isMobile)
              else
                _buildSliderLayout(images, isMobile),

              // Overlay Gradient for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),

              // Content Layer
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Text(
                              'NEW COLLECTION 2025',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3.0,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'ELEVATE YOUR STYLE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 32 : 48,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: 6.0,
                              fontFamily: 'Serif', 
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Text(
                            'Discover the latest trends in fashion and accessories.\nPremium quality, exclusive designs.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              color: Colors.white70,
                              height: 1.8,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w300,
                              shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ElevatedButton(
                          onPressed: () {
                            Provider.of<AppState>(context, listen: false).setSelectedTab(1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(horizontal: isMobile ? 40 : 56, vertical: 24),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('SHOP NOW', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 3.0)),
                              SizedBox(width: 16),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliderLayout(List<dynamic> images, bool isMobile) {
    if (images.isEmpty) return _buildSolidHero();
    
    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        return _buildHeroImage(images[index]);
      },
    );
  }

  Widget _buildCollageLayout(List<dynamic> images, bool isMobile) {
    if (images.isEmpty) return _buildSolidHero();
    if (images.length == 1) return _buildHeroImage(images[0]);

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: _buildHeroImage(images[0]),
        ),
        const SizedBox(height: 4),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              if (images.length > 1) Expanded(child: _buildHeroImage(images[1])),
              if (images.length > 2) const SizedBox(width: 4),
              if (images.length > 2) Expanded(child: _buildHeroImage(images[2])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage(dynamic item) {
    String? rawUrl;
    if (item is Map) rawUrl = item['url']?.toString();
    else if (item is String) rawUrl = item;

    if (rawUrl == null || rawUrl.isEmpty) return _buildSolidHero();

    ImageProvider provider;
    if (rawUrl.startsWith('data:')) {
      provider = MemoryImage(base64Decode(rawUrl.split(',').last));
    } else {
      String fullUrl = rawUrl;
      if (rawUrl.startsWith('/')) {
        String baseUrl = AppConstants.apiUrl;
        if (baseUrl.endsWith('/api')) baseUrl = baseUrl.substring(0, baseUrl.length - 4);
        fullUrl = "$baseUrl$rawUrl";
      }
      provider = NetworkImage(fullUrl);
    }

    return Image(
      image: provider,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _buildSolidHero(),
    );
  }

  Widget _buildSolidHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF1a1a1a)],
        ),
      ),
    );
  }
}
