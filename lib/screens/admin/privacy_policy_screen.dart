import 'package:flutter/material.dart';
import '../../theme/themed_background.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Compliance'), elevation: 0),
      body: ThemedBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Legal Framework',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 32),
              _buildSection(
                context,
                '1. Information We Collect',
                'We collect information that you provide directly to us, including:\n\n'
                    '• Name and contact information\n'
                    '• Profile information\n'
                    '• Booking and transaction details\n'
                    '• Communication preferences',
                Icons.person_search_outlined,
              ),
              _buildSection(
                context,
                '2. How We Use Your Information',
                'We use the information we collect to:\n\n'
                    '• Provide, maintain, and improve our services\n'
                    '• Process transactions and send related information\n'
                    '• Send you technical notices and support messages\n'
                    '• Respond to your comments and questions\n'
                    '• Monitor and analyze trends and usage',
                Icons.analytics_outlined,
              ),
              _buildSection(
                context,
                '3. Information Sharing',
                'We do not sell, trade, or rent your personal information to third parties. We may share your information only:\n\n'
                    '• With travel agencies for booking purposes\n'
                    '• When required by law or to protect our rights\n'
                    '• With your consent',
                Icons.share_outlined,
              ),
              _buildSection(
                context,
                '4. Data Security',
                'We implement appropriate security measures to protect your personal information. However, no method of transmission over the internet is 100% secure.',
                Icons.security_outlined,
              ),
              _buildSection(
                context,
                '5. Your Rights',
                'You have the right to:\n\n'
                    '• Access your personal information\n'
                    '• Correct inaccurate information\n'
                    '• Request deletion of your information\n'
                    '• Opt-out of certain communications',
                Icons.gpp_good_outlined,
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Last Updated Docs: ${DateTime.now().year}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.6,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
