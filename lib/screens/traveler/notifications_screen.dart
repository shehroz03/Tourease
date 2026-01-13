import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/themed_background.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _emailNotifications = false;
  bool _pushNotifications = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _emailNotifications = data?['notificationEmail'] ?? false;
          _pushNotifications = data?['notificationPush'] ?? false;
          _isInitialized = true;
        });
      } else {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) return;

      final authService = AuthService();
      await authService.updateUser(user.id, {
        'notificationEmail': _emailNotifications,
        'notificationPush': _pushNotifications,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(onPressed: _saveSettings, child: const Text('Save')),
        ],
      ),
      body: ThemedBackground(
        child: _isLoading && !_isInitialized
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildNotificationCard(
                    context,
                    title: 'Email Notifications',
                    subtitle: 'Receive travel updates via email',
                    icon: Icons.email_outlined,
                    value: _emailNotifications,
                    onChanged: (val) {
                      setState(() => _emailNotifications = val);
                      _saveSettings();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationCard(
                    context,
                    title: 'Push Notifications',
                    subtitle: 'Get real-time alerts on your device',
                    icon: Icons.notifications_active_outlined,
                    iconColor: Colors.orange,
                    value: _pushNotifications,
                    onChanged: (val) {
                      setState(() => _pushNotifications = val);
                      _saveSettings();
                    },
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'TourEase uses these settings to keep you updated on your bookings and tour status.',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Color iconColor = Colors.blue,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SwitchListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor),
          ),
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.selected)) {
              return Theme.of(context).colorScheme.primary;
            }
            return null; // Use default
          }),
        ),
      ),
    );
  }
}
