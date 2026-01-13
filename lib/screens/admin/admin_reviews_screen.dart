import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';

class AdminReviewsScreen extends StatelessWidget {
  const AdminReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reviewService = ReviewService();

    return Scaffold(
      appBar: AppBar(title: const Text('Review Moderation')),
      body: StreamBuilder<List<ReviewModel>>(
        stream: reviewService.streamReportedReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final reviews = snapshot.data ?? [];

          if (reviews.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text('No reported reviews', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _ReportedReviewCard(
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

class _ReportedReviewCard extends StatelessWidget {
  final ReviewModel review;
  final ReviewService reviewService;

  const _ReportedReviewCard({
    required this.review,
    required this.reviewService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reported Reason:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          review.reportReason ?? 'No reason provided',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  if (review.reportedAt != null)
                    Text(
                      DateFormat('MMM dd').format(review.reportedAt!),
                      style: TextStyle(color: Colors.red[300], fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Review Content
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: review.travelerPhotoUrl != null
                      ? NetworkImage(review.travelerPhotoUrl!)
                      : null,
                  child: review.travelerPhotoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.travelerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(review.comment ?? 'No comment'),
            const SizedBox(height: 16),
            const Divider(),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _handleDismiss(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Keep Review (Dismiss)'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _handleDelete(context),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete Review'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDismiss(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dismiss Report'),
        content: const Text(
          'This will clear the report flag and keep the review visible. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Dismiss Report'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await reviewService.dismissReport(review.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Report dismissed')));
      }
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text(
          'This will permanently delete the review. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Delete Review',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await reviewService.deleteReview(review.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Review deleted')));
      }
    }
  }
}
