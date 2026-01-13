import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/review_model.dart';
import '../../models/tour_model.dart';
import '../../services/review_service.dart';
import '../../services/tour_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/themed_background.dart';

class MyReviewsScreen extends StatelessWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reviews'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: ThemedBackground(
        child: StreamBuilder<List<ReviewModel>>(
          stream: ReviewService().streamReviewsForTraveler(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final reviews = snapshot.data ?? [];
            if (reviews.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
              itemCount: reviews.length,
              itemBuilder: (context, index) =>
                  _ReviewItem(review: reviews[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.reviews_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No reviews yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your experiences after completing a tour!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final ReviewModel review;

  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<TourModel?>(
            future: TourService().getTourById(review.tourId),
            builder: (context, snapshot) {
              final tourTitle =
                  snapshot.data?.title ?? 'Loading tour details...';
              return Text(
                tourTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Icon(
                  Icons.star,
                  size: 16,
                  color: index < review.rating
                      ? Colors.amber
                      : Colors.grey[300],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMM d, y').format(review.createdAt),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const Spacer(),
              if (!review.isApproved)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[100]!),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: TextStyle(color: Colors.grey[700], height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
