import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/tour_service.dart';
import '../../models/booking_model.dart';
import '../../models/tour_model.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';

class MyBookingsScreen extends StatefulWidget {
  final int initialTab;
  const MyBookingsScreen({super.key, this.initialTab = 0});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final bookingService = BookingService();
    final tourService = TourService();

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: bookingService.streamTravelerBookings(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bookings = snapshot.data ?? [];

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.wait(
              bookings.map((b) async {
                final tour = await tourService.getTourById(b.tourId);
                return {'booking': b, 'tour': tour};
              }),
            ),
            builder: (context, tourSnapshot) {
              if (!tourSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final now = DateTime.now();
              final allData = tourSnapshot.data!;

              final activeBookings = allData
                  .where((data) {
                    final b = data['booking'] as BookingModel;
                    final t = data['tour'] as TourModel?;

                    // Pending is always active as it needs payment/confirming
                    if (b.status == BookingStatus.pending) return true;

                    // Confirmed is active only if the tour is still in the future or ongoing
                    if (b.status == BookingStatus.confirmed) {
                      if (t == null) {
                        return true; // Keep it in active if tour not found (safest)
                      }
                      return t.endDate.isAfter(now);
                    }

                    return false;
                  })
                  .map((data) => data['booking'] as BookingModel)
                  .toList();

              final historyBookings = allData
                  .where((data) {
                    final b = data['booking'] as BookingModel;
                    final t = data['tour'] as TourModel?;

                    // Completed and Cancelled are always history
                    if (b.status == BookingStatus.completed ||
                        b.status == BookingStatus.cancelled) {
                      return true;
                    }

                    // Confirmed is history if the tour has already ended
                    if (b.status == BookingStatus.confirmed) {
                      if (t == null) return false;
                      return t.endDate.isBefore(now) ||
                          t.endDate.isAtSameMomentAs(now);
                    }

                    return false;
                  })
                  .map((data) => data['booking'] as BookingModel)
                  .toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _BookingsList(bookings: activeBookings, isActive: true),
                  _BookingsList(bookings: historyBookings, isActive: false),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final List<BookingModel> bookings;
  final bool isActive;

  const _BookingsList({required this.bookings, required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active bookings' : 'No booking history',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? 'Book your first tour to get started!'
                  : 'Your completed bookings will appear here',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _BookingCard(booking: bookings[index], isActive: isActive);
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isActive;

  const _BookingCard({required this.booking, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final tourService = TourService();
    final reviewService = ReviewService();

    return FutureBuilder<TourModel?>(
      future: tourService.getTourById(booking.tourId),
      builder: (context, tourSnapshot) {
        if (!tourSnapshot.hasData) {
          return const Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final tour = tourSnapshot.data;
        if (tour == null) {
          return const Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Tour not found'),
            ),
          );
        }

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tour Image
              if (tour.coverImage != null)
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: tour.coverImage!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 50),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tour Title
                    Text(
                      tour.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Agency Name
                    Row(
                      children: [
                        const Icon(
                          Icons.business,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tour.agencyName,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Date and Duration
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${DateFormat('MMM dd').format(tour.startDate)} - ${DateFormat('MMM dd, yyyy').format(tour.endDate)}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Seats and Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${booking.seats} seat${booking.seats > 1 ? 's' : ''}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        Text(
                          '\$${booking.totalPrice.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          booking.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(
                            booking.status,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _getStatusText(booking.status),
                        style: TextStyle(
                          color: _getStatusColor(booking.status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    if (isActive) ...[
                      Row(
                        children: [
                          if (booking.status == BookingStatus.confirmed) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  debugPrint(
                                    'MyBookingsScreen: Track Live clicked for tour ${tour.id}',
                                  );
                                  context.push('/live-track/${tour.id}');
                                },
                                icon: const Icon(Icons.location_on, size: 18),
                                label: const Text('Track Live'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                  side: const BorderSide(color: Colors.green),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: booking.status == BookingStatus.pending
                                ? ElevatedButton.icon(
                                    onPressed: () =>
                                        context.push('/payment/${booking.id}'),
                                    icon: const Icon(Icons.payment, size: 18),
                                    label: const Text('Pay Now'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: () =>
                                        context.push('/ticket/${booking.id}'),
                                    icon: const Icon(
                                      Icons.confirmation_number,
                                      size: 18,
                                    ),
                                    label: const Text('View Ticket'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ] else if (booking.status == BookingStatus.completed) ...[
                      // Review button for completed bookings
                      FutureBuilder<ReviewModel?>(
                        future: reviewService.getReviewForBooking(
                          booking.id,
                          booking.travelerId,
                        ),
                        builder: (context, reviewSnapshot) {
                          final hasReview =
                              reviewSnapshot.hasData &&
                              reviewSnapshot.data != null;
                          return SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.push(
                                  '/traveler/review',
                                  extra: {
                                    'booking': booking,
                                    'tourTitle': tour.title,
                                  },
                                );
                              },
                              icon: Icon(
                                hasReview ? Icons.edit : Icons.rate_review,
                                size: 18,
                              ),
                              label: Text(
                                hasReview ? 'Edit Review' : 'Write a Review',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasReview
                                    ? Colors.orange
                                    : Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending Payment';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}
