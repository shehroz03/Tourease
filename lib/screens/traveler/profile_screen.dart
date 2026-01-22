import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../theme/themed_background.dart';
import '../../services/data_seed_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: ThemedBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              stretch: true,
              backgroundColor: Theme.of(context).colorScheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                ],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (user.photoUrl != null)
                      CachedNetworkImage(
                        imageUrl: user.photoUrl!,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            user.email,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    _buildSection(context, 'Account Settings', [
                      _ProfileMenuItem(
                        icon: Icons.person_outline,
                        iconColor: Colors.blue,
                        title: 'Edit Profile',
                        subtitle: 'Change your name and info',
                        onTap: () => context.push('/traveler/profile/edit'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.notifications_outlined,
                        iconColor: Colors.orange,
                        title: 'Notifications',
                        subtitle: 'Manage your alerts',
                        onTap: () =>
                            context.push('/traveler/profile/notifications'),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection(context, 'My Activity', [
                      _ProfileMenuItem(
                        icon: Icons.history,
                        iconColor: Colors.teal,
                        title: 'Completed Tours',
                        subtitle: 'Tours you have finished',
                        onTap: () => context.push('/traveler/bookings?tab=1'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.reviews_outlined,
                        iconColor: Colors.amber,
                        title: 'My Reviews',
                        subtitle: 'Reviews you have written',
                        onTap: () => context.push('/traveler/my-reviews'),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection(context, 'Support', [
                      _ProfileMenuItem(
                        icon: Icons.help_outline,
                        iconColor: Colors.green,
                        title: 'Help & Support',
                        subtitle: 'FAQs and contact us',
                        onTap: () => context.push('/traveler/profile/help'),
                      ),
                      _ProfileMenuItem(
                        icon: Icons.info_outline,
                        iconColor: Colors.purple,
                        title: 'About',
                        subtitle: 'Learn more about us',
                        onTap: () => context.push('/traveler/profile/about'),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    // Debug section - only visible in debug mode
                    if (const bool.fromEnvironment('dart.vm.product') == false)
                      _buildSection(context, 'Debug Tools', [
                        _ProfileMenuItem(
                          icon: Icons.data_object,
                          iconColor: Colors.deepPurple,
                          title: 'Seed Demo & Showcase Data',
                          subtitle: 'Add sample completed tours & reviews',
                          onTap: () =>
                              _seedDummyData(context, user.id, user.name),
                        ),
                      ]),
                    if (const bool.fromEnvironment('dart.vm.product') == false)
                      const SizedBox(height: 24),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => _handleLogout(context, authProvider),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        side: BorderSide(color: Colors.red.shade100),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        Card(
          elevation: 0,
          color: Colors.grey[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Future<void> _handleLogout(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(80, 40),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await authProvider.signOut();
      if (context.mounted) {
        context.replace('/login');
      }
    }
  }

  Future<void> _seedDummyData(
    BuildContext context,
    String userId,
    String travelerName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seed Dummy Data'),
        content: const Text(
          'This will add sample completed bookings and reviews to your account. '
          'This is useful for testing and visualization purposes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              minimumSize: const Size(80, 40),
            ),
            child: const Text('Seed Data'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final seedService = DataSeedService();
        await seedService.cleanOldShowcaseData(); // Remove broken old tours
        await seedService.seedDummyDataForTraveler(userId);
        await seedService.seedDummyReviewsForTours();
        await seedService.seedGlobalActivity();
        await seedService
            .seedReviewsForAllAgenciesAndTours(); // Ensure all agencies get reviews
        await seedService.seedShowcaseData(userId, travelerName: travelerName);

        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dummy data seeded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error seeding data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }
}
