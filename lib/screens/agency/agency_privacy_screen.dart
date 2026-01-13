import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/themed_background.dart';

class AgencyPrivacyScreen extends StatefulWidget {
  const AgencyPrivacyScreen({super.key});

  @override
  State<AgencyPrivacyScreen> createState() => _AgencyPrivacyScreenState();
}

class _AgencyPrivacyScreenState extends State<AgencyPrivacyScreen> {
  bool _isChanging = false;

  Future<void> _changePasswordDialog() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: _buildInputDecoration(
                'Current Password',
                Icons.lock_outline,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: _buildInputDecoration(
                'New Password',
                Icons.lock_reset,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: _buildInputDecoration(
                'Confirm New Password',
                Icons.lock_reset,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != true) return;
    if (!mounted) return;

    final current = currentController.text.trim();
    final next = newController.text.trim();
    final confirm = confirmController.text.trim();

    if (next.isEmpty || next.length < 6 || next != confirm) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid password details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isChanging = true);
    try {
      if (context.read<AuthProvider>().user == null) throw Exception('No user');
      await AuthService().changePassword(
        currentPassword: current,
        newPassword: next,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isChanging = false);
    }
  }

  Future<void> _deleteAccountDialog() async {
    final pwController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This is permanent. Type your password to confirm account deletion.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pwController,
              obscureText: true,
              decoration: _buildInputDecoration('Password', Icons.lock_outline),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final pw = pwController.text.trim();
    if (pw.isEmpty) return;

    setState(() => _isChanging = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      if (user == null) throw Exception('No user');

      await AuthService().deleteUserAccount(userId: user.id, password: pw);
      await authProvider.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isChanging = false);
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ThemedBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSectionHeader('Security Settings'),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Regularly update your password to stay secure',
              onTap: _isChanging ? null : _changePasswordDialog,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              icon: Icons.delete_outline,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account and all data',
              isDestructive: true,
              onTap: _isChanging ? null : _deleteAccountDialog,
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Privacy Policy'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data Usage',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TourEase is committed to protecting your agency data. We only collect necessary information to provide our services and connect you with travelers.',
                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Consent',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By using our platform, you agree to our terms of service and how we handle your business information.',
                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.red
        : Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDestructive ? Colors.red : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
