import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../theme/themed_background.dart';
import '../../widgets/animations/fade_in_slide.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final adminService = AdminService();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Console'), elevation: 0),
      body: ThemedBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInSlide(
                index: 0,
                child: _buildHeader(user?.name ?? 'Administrator'),
              ),
              const SizedBox(height: 32),
              FadeInSlide(index: 1, child: _buildStatsSection(adminService)),
              const SizedBox(height: 32),
              FadeInSlide(index: 2, child: _buildQuickActionsHeader(context)),
              const SizedBox(height: 16),
              FadeInSlide(
                index: 3,
                child: _QuickAction(
                  icon: Icons.verified_user_outlined,
                  title: 'Agency Verification',
                  subtitle: 'Review and approve new partners',
                  onTap: () => context.go('/admin/agencies'),
                ),
              ),
              const SizedBox(height: 12),
              FadeInSlide(
                index: 4,
                child: _QuickAction(
                  icon: Icons.map_outlined,
                  title: 'Tour Management',
                  subtitle: 'Monitor all published itineraries',
                  onTap: () => context.go('/admin/tours'),
                ),
              ),
              const SizedBox(height: 12),
              FadeInSlide(
                index: 5,
                child: _QuickAction(
                  icon: Icons.policy_outlined,
                  title: 'Legal & Compliance',
                  subtitle: 'Update terms and privacy policies',
                  onTap: () => context.go('/admin/settings'),
                ),
              ),
              const SizedBox(height: 12),
              FadeInSlide(
                index: 6,
                child: _QuickAction(
                  icon: Icons.rate_review_outlined,
                  title: 'Review Moderation',
                  subtitle: 'Approve or reject traveler reviews',
                  onTap: () => context.push('/admin/review-moderation'),
                ),
              ),
              const SizedBox(height: 12),
              FadeInSlide(
                index: 7,
                child: _QuickAction(
                  icon: Icons.chat_bubble_outline,
                  title: 'Messages',
                  subtitle: 'Chat with agencies',
                  onTap: () => context.push('/admin/chats'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Command Center',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome back,\n$name',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here is what is happening today.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(AdminService adminService) {
    return FutureBuilder<Map<String, int>>(
      future: adminService.getDashboardStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildStatsLoadingGrid();
        }
        if (snapshot.hasError) {
          return _buildErrorMessage(snapshot.error.toString());
        }

        final stats = snapshot.data ?? {};
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _StatCard(
              title: 'Total Users',
              value: '${stats['totalUsers'] ?? 0}',
              icon: Icons.people_outline,
              color: Colors.blue,
            ),
            _StatCard(
              title: 'Agencies',
              value: '${stats['totalAgencies'] ?? 0}',
              icon: Icons.business_outlined,
              color: Colors.indigo,
            ),
            _StatCard(
              title: 'Pending',
              value: '${stats['pendingAgencies'] ?? 0}',
              icon: Icons.pending_outlined,
              color: Colors.orange,
            ),
            _StatCard(
              title: 'Tours Live',
              value: '${stats['totalTours'] ?? 0}',
              icon: Icons.explore_outlined,
              color: Colors.teal,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsLoadingGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: List.generate(
        4,
        (i) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Center(
      child: Text(
        'Error loading stats: $error',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildQuickActionsHeader(BuildContext context) {
    return const Row(
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Spacer(),
        Icon(Icons.bolt, color: Colors.orange, size: 20),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              // Optional trend indicator
              Icon(
                Icons.arrow_outward,
                color: color.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
