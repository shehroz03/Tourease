import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/themed_background.dart';

class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      await context.read<AuthProvider>().refreshUser();
      if (mounted) {
        final user = context.read<AuthProvider>().user;
        if (user != null &&
            user.verified &&
            user.status == VerificationStatus.verified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Congratulations! Your account is approved!'),
              backgroundColor: Colors.green,
            ),
          );
          // Router should auto-redirect them to dashboard, but we can nudge
          context.go('/agency/dashboard');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification status updated')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isRejected = user.status == VerificationStatus.rejected;
    final isPending = user.status == VerificationStatus.pending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Verification'),
        elevation: 0,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refresh,
            tooltip: 'Check for Approval',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.signOut();
              context.go('/login');
            },
          ),
        ],
      ),
      body: ThemedBackground(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(isPending, isRejected, user.rejectionReason),
                const SizedBox(height: 32),
                if (isPending || isRejected) ...[
                  _buildSubmittedSection(_getAvailableDocs(user)),
                  const SizedBox(height: 32),
                ],
                ElevatedButton.icon(
                  onPressed: () => context.push('/agency/registration'),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Update Application Details'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                if (isRejected) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Please review the feedback and update your documents.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 48),
                _buildSupportInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool pending, bool rejected, String? reason) {
    Color statusColor = Colors.blue;
    IconData icon = Icons.verified_user_outlined;
    String title = 'Identity Verification';
    String desc = 'Please complete your profile to start hosting tours.';

    if (pending) {
      statusColor = Colors.orange;
      icon = Icons.hourglass_top_rounded;
      title = 'Review in Progress';
      desc =
          'Our team is currently verifying your agency documents. This usually takes 24-48 hours.';
    } else if (rejected) {
      statusColor = Colors.red;
      icon = Icons.gpp_bad_rounded;
      title = 'Action Required';
      desc = 'Your application needs some changes before we can approve it.';
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(icon, color: statusColor, size: 56),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              height: 1.5,
              fontSize: 15,
            ),
          ),
          if (rejected && reason != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.feedback_outlined,
                        color: Colors.red,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Rejection Reason',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reason,
                    style: TextStyle(color: Colors.red.shade900, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmittedSection(List<String> docs) {
    if (docs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Submitted Documents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${docs.length} files',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) => Container(
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: docs[index],
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Row(
        children: [
          Icon(Icons.help_outline, color: Colors.blue),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Contact support at support@tourease.pk',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getAvailableDocs(UserModel user) {
    final List<String> docs = [];
    if (user.businessLicenseUrl != null) docs.add(user.businessLicenseUrl!);
    if (user.cnicFrontUrl != null) docs.add(user.cnicFrontUrl!);
    if (user.cnicBackUrl != null) docs.add(user.cnicBackUrl!);
    docs.addAll(user.verificationDocuments);
    return docs.toSet().toList();
  }
}
