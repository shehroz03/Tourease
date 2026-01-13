import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../providers/auth_provider.dart';

class WriteReviewScreen extends StatefulWidget {
  final BookingModel booking;
  final String tourTitle;

  const WriteReviewScreen({
    super.key,
    required this.booking,
    required this.tourTitle,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _reviewService = ReviewService();
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _isLoading = false;
  bool _isInitialLoading = true;
  ReviewModel? _existingReview;

  @override
  void initState() {
    super.initState();
    _loadExistingReview();
  }

  Future<void> _loadExistingReview() async {
    final review = await _reviewService.getReviewForBooking(
      widget.booking.id,
      widget.booking.travelerId,
    );
    if (mounted) {
      setState(() {
        _existingReview = review;
        if (review != null) {
          _rating = review.rating;
          _commentController.text = review.comment ?? '';
        }
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthProvider>().user;
      await _reviewService.submitReview(
        booking: widget.booking,
        travelerName: user?.name ?? 'Traveler',
        travelerPhotoUrl: user?.photoUrl,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit review: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // PopScope is sufficient with canPop: true here.
        // Extra navigation inside onPopInvokedWithResult was causing crashes.
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _existingReview != null ? 'Edit Review' : 'Write a Review',
          ),
        ),
        body: _isInitialLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tourTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How was your experience?',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Your Rating',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          onPressed: () => setState(() => _rating = starValue),
                          icon: Icon(
                            _rating >= starValue
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 40,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Your Comments (Optional)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _commentController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts about this tour...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                _existingReview != null
                                    ? 'Update Review'
                                    : 'Submit Review',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
