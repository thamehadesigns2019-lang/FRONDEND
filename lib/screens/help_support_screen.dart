import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thameeha/providers/app_state.dart';
import 'package:thameeha/theme/themes.dart';
import 'package:thameeha/screens/support_chat_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  List<dynamic> _faqs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  Future<void> _loadFAQs() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final faqs = await appState.apiService.fetchFAQs();
      setState(() {
        _faqs = faqs;
      });
    } catch (e) {
      print('Error loading FAQs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: isSmall ? 16 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmall ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       _buildContactCard(isSmall),
                       const SizedBox(height: 32),
                       Padding(
                         padding: const EdgeInsets.only(left: 4, bottom: 16),
                         child: Text(
                          'FREQUENTLY ASKED QUESTIONS',
                          style: TextStyle(
                            fontSize: isSmall ? 12 : 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[600],
                            letterSpacing: 1.2,
                          ),
                        ),
                       ),
                      ..._faqs.map((faq) => _buildFaqTile(faq, isSmall)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildContactCard(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 20 : 32),
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
          Container(
            padding: EdgeInsets.all(isSmall ? 12 : 16),
            decoration: BoxDecoration(
              color: const Color(0xFF11998e).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.support_agent_rounded, size: isSmall ? 36 : 48, color: const Color(0xFF11998e)),
          ),
          const SizedBox(height: 24),
          Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: isSmall ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our dedicated support team is available 24/7 to assist you with any questions or issues.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: isSmall ? 14 : 16, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: isSmall ? 44 : 50,
            child: ElevatedButton.icon(
              onPressed: () {
                 Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => const SupportChatScreen())
                );
              },
              icon: Icon(Icons.chat_bubble_outline, size: isSmall ? 20 : 24),
              label: Text('Chat with Support Agent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmall ? 14 : 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(dynamic faq, bool isSmall) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24, vertical: isSmall ? 4 : 8),
          childrenPadding: EdgeInsets.only(left: isSmall ? 16 : 24, right: isSmall ? 16 : 24, bottom: isSmall ? 16 : 24),
          title: Text(
            faq['question'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 14 : 16,
              color: Colors.black87
            ),
          ),
          iconColor: Colors.black,
          collapsedIconColor: Colors.grey,
          children: [
            Text(
              faq['answer'] ?? '',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: isSmall ? 13 : 15,
                height: 1.6
              ),
            ),
          ],
        ),
      ),
    );
  }
}
