import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../theme/themed_background.dart';

class AgencyManagementScreen extends StatefulWidget {
  const AgencyManagementScreen({super.key});

  @override
  State<AgencyManagementScreen> createState() => _AgencyManagementScreenState();
}

class _AgencyManagementScreenState extends State<AgencyManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agency Verification'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue.shade700,
          labelColor: Colors.blue.shade700,
          unselectedLabelColor: Colors.grey,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Verified'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AgencyList(
            stream: _adminService.streamAgenciesByStatus(
              VerificationStatus.pending,
            ),
            emptyIcon: Icons.hourglass_empty_rounded,
            emptyMessage: 'No pending applications',
          ),
          _AgencyList(
            stream: _adminService.streamAgenciesByStatus(
              VerificationStatus.verified,
            ),
            emptyIcon: Icons.verified_user_outlined,
            emptyMessage: 'No verified agencies',
          ),
          _AgencyList(
            stream: _adminService.streamAgenciesByStatus(
              VerificationStatus.rejected,
            ),
            emptyIcon: Icons.gpp_bad_outlined,
            emptyMessage: 'No rejected applications',
          ),
        ],
      ),
    );
  }
}

class _AgencyList extends StatelessWidget {
  final Stream<List<UserModel>> stream;
  final String emptyMessage;
  final IconData emptyIcon;

  const _AgencyList({
    required this.stream,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ThemedBackground(
      child: StreamBuilder<List<UserModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorMessage(snapshot.error.toString());
          }

          final agencies = snapshot.data ?? [];
          if (agencies.isEmpty) {
            return _buildEmptyState(emptyIcon, emptyMessage);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: agencies.length,
            itemBuilder: (context, index) =>
                _AgencyCard(agency: agencies[index]),
          );
        },
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Connection Error',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgencyCard extends StatelessWidget {
  final UserModel agency;
  const _AgencyCard({required this.agency});

  @override
  Widget build(BuildContext context) {
    final adminService = AdminService();
    final currentUser = context.read<AuthProvider>().user;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAgencyHeader(context),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    Icons.person,
                    'Owner',
                    agency.ownerName ?? 'N/A',
                  ),
                  _buildDetailRow(
                    Icons.location_on,
                    'Location',
                    '${agency.city}, ${agency.country}',
                  ),
                  _buildDetailRow(Icons.phone, 'Phone', agency.phone ?? 'N/A'),
                  if (agency.whatsapp != null && agency.whatsapp!.isNotEmpty)
                    _buildDetailRow(Icons.chat, 'WhatsApp', agency.whatsapp!),
                  _buildDetailRow(
                    Icons.work,
                    'Experience',
                    '${agency.yearsOfExperience ?? 0} Years',
                  ),
                  _buildDetailRow(
                    Icons.card_membership,
                    'License #',
                    agency.businessLicenseNumber ?? 'N/A',
                  ),
                  if (agency.cnicNumber != null)
                    _buildDetailRow(
                      Icons.credit_card,
                      'CNIC',
                      agency.cnicNumber!,
                    ),

                  if (agency.websiteUrl != null &&
                      agency.websiteUrl!.isNotEmpty)
                    _buildDetailRow(
                      Icons.language,
                      'Website',
                      agency.websiteUrl!,
                    ),

                  if (agency.facebookUrl != null ||
                      agency.instagramUrl != null ||
                      agency.tiktokUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.share, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text(
                            'Socials: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (agency.facebookUrl != null)
                                const Icon(
                                  Icons.facebook,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                              if (agency.instagramUrl != null)
                                const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.pink,
                                ),
                              if (agency.tiktokUrl != null)
                                const Icon(
                                  Icons.music_note,
                                  size: 16,
                                  color: Colors.black,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  if (agency.description != null &&
                      agency.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      agency.description!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],

                  if (agency.specializedDestinations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Specialized In',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: agency.specializedDestinations
                          .map(
                            (dest) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                dest,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 20),
                  _buildDocumentsSection(context),

                  if (agency.rejectionReason != null &&
                      agency.status == VerificationStatus.rejected) ...[
                    const SizedBox(height: 20),
                    _buildRejectionReason(),
                  ],
                  const SizedBox(height: 20),
                  _buildActionButtons(context, adminService, currentUser),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgencyHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.blue.shade50.withValues(alpha: 0.5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue.shade700,
            backgroundImage: agency.photoUrl != null
                ? CachedNetworkImageProvider(agency.photoUrl!)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agency.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  agency.email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => context.push('/agency-profile/${agency.id}'),
                  child: Text(
                    'View Profile',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _StatusChip(status: agency.status),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context) {
    final docs = [
      if (agency.cnicFrontUrl != null)
        {'label': 'CNIC Front', 'url': agency.cnicFrontUrl!},
      if (agency.cnicBackUrl != null)
        {'label': 'CNIC Back', 'url': agency.cnicBackUrl!},
      if (agency.businessLicenseUrl != null)
        {'label': 'Business License', 'url': agency.businessLicenseUrl!},
    ];

    if (docs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification Documents',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return Column(
                children: [
                  GestureDetector(
                    onTap: () => _viewImage(context, doc['url']!),
                    child: Container(
                      width: 100,
                      height: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: doc['url']!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      doc['label']!,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRejectionReason() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Reason: ${agency.rejectionReason}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AdminService adminService,
    UserModel? currentUser,
  ) {
    if (agency.status == VerificationStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: () => _showRejectDialog(context, adminService, agency),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Reject'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () =>
                  _handleApprove(context, adminService, currentUser),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (agency.status == VerificationStatus.verified) {
      return OutlinedButton.icon(
        onPressed: () => _handleRevoke(context, adminService),
        icon: const Icon(Icons.remove_moderator_outlined, size: 18),
        label: const Text('Revoke Verification'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange.shade800,
          side: BorderSide(color: Colors.orange.shade200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 0),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () => _handleApprove(context, adminService, currentUser),
        icon: const Icon(Icons.check, size: 18),
        label: const Text('Approve Now'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _handleApprove(
    BuildContext context,
    AdminService adminService,
    UserModel? currentUser,
  ) async {
    try {
      await adminService.approveAgency(agency.id, currentUser?.id ?? '');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agency approved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRevoke(
    BuildContext context,
    AdminService adminService,
  ) async {
    try {
      await adminService.revokeAgency(agency.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agency verification revoked'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Revocation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    AdminService adminService,
    UserModel agency,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for rejecting this agency.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Rejection Reason',
                hintText: 'e.g. Missing business license',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isNotEmpty) {
                try {
                  await adminService.rejectAgency(
                    agency.id,
                    reasonController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Agency rejected'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Rejection failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final VerificationStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = status == VerificationStatus.verified
        ? Colors.green
        : (status == VerificationStatus.pending ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
