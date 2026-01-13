import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../theme/themed_background.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String supportEmail = 'support@tourease.com';

  Future<void> _sendEmail() async {
    final uri = Uri.parse(
      'mailto:$supportEmail?subject=TourEase Support Request',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _createSupportTicket(
    BuildContext context,
    String message,
  ) async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('support_tickets').add({
        'userId': user.id,
        'userEmail': user.email,
        'userName': user.name,
        'message': message,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Support ticket created. We\'ll get back to you soon!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showContactDialog(BuildContext context) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send us a message and we\'ll get back to you as soon as possible.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: InputDecoration(
                labelText: 'Your message',
                hintText: 'Describe your issue or question...',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              maxLines: 5,
              minLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                _createSupportTicket(context, messageController.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ThemedBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How can we help you?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search our FAQs or contact our dedicated support team.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Frequently Asked Questions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFAQSection(),
            const SizedBox(height: 32),
            _buildContactSection(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      children: const [
        _FAQTile(
          question: 'How do I book a tour?',
          answer:
              'Browse available tours on the home screen, tap on a tour to see details, select the number of seats, and click "Book Now". You\'ll receive a confirmation once your booking is processed.',
        ),
        _FAQTile(
          question: 'Can I cancel my booking?',
          answer:
              'Yes, you can cancel pending bookings from the "My Bookings" screen. Once a booking is confirmed by the agency, cancellation policies may apply.',
        ),
        _FAQTile(
          question: 'How do I contact an agency?',
          answer:
              'You can chat with an agency directly from a tour detail page or from your bookings. Click the "Chat" button to start a conversation.',
        ),
        _FAQTile(
          question: 'What payment methods are accepted?',
          answer:
              'Payment processing is handled securely through our platform. Currently, we support major credit cards and digital payment methods.',
        ),
        _FAQTile(
          question: 'How do I update my profile?',
          answer:
              'Go to your Profile screen and tap "Edit Profile" to update your name, phone number, and profile photo.',
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showContactDialog(context),
          icon: const Icon(Icons.support_agent),
          label: const Text('Chat with Support'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _sendEmail,
          icon: const Icon(Icons.mail_outline),
          label: Text('Email us at $supportEmail'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _FAQTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQTile({required this.question, required this.answer});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        title: Text(
          widget.question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) =>
            setState(() => _isExpanded = expanded),
        shape: const Border(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              widget.answer,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
