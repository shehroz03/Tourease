import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';

class AgencyReviewsScreen extends StatelessWidget {
  const AgencyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final reviewService = ReviewService();

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Reviews')),
      body: StreamBuilder<List<ReviewModel>>(
        stream: reviewService.streamReviewsForAgency(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reviews = snapshot.data ?? [];

          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No reviews yet'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _AgencyReviewCard(
                review: review,
                reviewService: reviewService,
              );
            },
          );
        },
      ),
    );
  }
}

class _AgencyReviewCard extends StatelessWidget {
  final ReviewModel review;
  final ReviewService reviewService;

  const _AgencyReviewCard({required this.review, required this.reviewService});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue.shade50,
                      backgroundImage: review.travelerPhotoUrl != null
                          ? NetworkImage(review.travelerPhotoUrl!)
                          : null,
                      child: review.travelerPhotoUrl == null
                          ? Icon(Icons.person, color: Colors.blue.shade300)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.travelerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(review.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        review.rating.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              Text(
                review.comment!,
                style: const TextStyle(height: 1.5, fontSize: 14),
              ),
              const SizedBox(height: 12),
            ],

            // Report Button
            Align(
              alignment: Alignment.centerRight,
              child: review.isReported
                  ? TextButton.icon(
                      onPressed: null, // Disabled
                      icon: const Icon(
                        Icons.flag,
                        color: Colors.grey,
                        size: 18,
                      ),
                      label: const Text(
                        'Reported',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: () => _showReportDialog(context),
                      icon: const Icon(
                        Icons.flag_outlined,
                        color: Colors.orange,
                        size: 18,
                      ),
                      label: const Text(
                        'Report',
                        style: TextStyle(color: Colors.orange),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.orange.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please provide a reason for reporting this review to the admin.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
              if (reasonController.text.trim().isEmpty) return;

              await reviewService.reportReview(
                review.id,
                reasonController.text.trim(),
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Review reported to Admin')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
