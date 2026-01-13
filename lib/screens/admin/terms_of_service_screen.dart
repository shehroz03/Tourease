import 'package:flutter/material.dart';
import '../../theme/themed_background.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traveler Agreement'), elevation: 0),
      body: ThemedBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Legal Obligations',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 32),
              _buildSection(
                context,
                '1. Acceptance of Terms',
                'By accessing and using TourEase, you accept and agree to be bound by the terms and provision of this agreement.',
                Icons.handshake_outlined,
              ),
              _buildSection(
                context,
                '2. Use License',
                'Permission is granted to temporarily use TourEase for personal, non-commercial transitory viewing only. Under this license you may not:\n\n'
                    '• Modify or copy the materials\n'
                    '• Use the materials for any commercial purpose\n'
                    '• Attempt to decompile or reverse engineer any software\n'
                    '• Remove any copyright or other proprietary notations',
                Icons.assignment_turned_in_outlined,
              ),
              _buildSection(
                context,
                '3. User Accounts',
                'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.',
                Icons.account_circle_outlined,
              ),
              _buildSection(
                context,
                '4. Bookings and Payments',
                'All tour bookings are subject to availability. Prices are subject to change without notice. Payments are processed securely through our payment partners.',
                Icons.payments_outlined,
              ),
              _buildSection(
                context,
                '5. Cancellation Policy',
                'Cancellation policies vary by tour and agency. Please review the specific cancellation policy for each tour before booking.',
                Icons.event_busy_outlined,
              ),
              _buildSection(
                context,
                '6. Limitation of Liability',
                'TourEase acts as a platform connecting travelers with agencies. We are not responsible for the services provided by agencies or any issues arising from bookings.',
                Icons.gavel_outlined,
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Agreement Effective: ${DateTime.now().year}',
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
