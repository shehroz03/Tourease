import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/booking_service.dart';
import '../../services/tour_service.dart';
import '../../models/booking_model.dart';
import '../../models/tour_model.dart';
import '../../theme/themed_background.dart';

class AgencyBookingsScreen extends StatefulWidget {
  const AgencyBookingsScreen({super.key});

  @override
  State<AgencyBookingsScreen> createState() => _AgencyBookingsScreenState();
}

class _AgencyBookingsScreenState extends State<AgencyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bookings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: ThemedBackground(
        child: StreamBuilder<List<BookingModel>>(
          stream: bookingService.streamAgencyBookings(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildErrorState(context, snapshot.error.toString());
            }

            final allBookings = snapshot.data ?? [];
            final pendingBookings = allBookings
                .where((b) => b.status == BookingStatus.pending)
                .toList();
            final confirmedBookings = allBookings
                .where((b) => b.status == BookingStatus.confirmed)
                .toList();
            final completedBookings = allBookings
                .where((b) => b.status == BookingStatus.completed)
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _BookingList(bookings: allBookings),
                _BookingList(bookings: pendingBookings),
                _BookingList(bookings: confirmedBookings),
                _BookingList(bookings: completedBookings),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    String errorMessage = 'Failed to load bookings';
    if (error.contains('index')) {
      errorMessage = 'Please create the required Firestore index.';
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  const _BookingList({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'No bookings found',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: bookings.length,
      itemBuilder: (context, index) =>
          _AgencyBookingCard(booking: bookings[index]),
    );
  }
}

class _AgencyBookingCard extends StatelessWidget {
  final BookingModel booking;
  const _AgencyBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final tourService = TourService();
    final bookingService = BookingService();

    return FutureBuilder<TourModel?>(
      future: tourService.getTourById(booking.tourId),
      builder: (context, snapshot) {
        final tour = snapshot.data;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
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
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatusChip(status: booking.status),
                        Text(
                          '#${booking.id.substring(0, 8)}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tour?.title ?? 'Loading Tour Details...',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM dd, yyyy').format(booking.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${booking.seats} Seats',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Revenue',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '\$${booking.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (booking.status == BookingStatus.pending)
                          Row(
                            children: [
                              IconButton.filledTonal(
                                onPressed: () => _handleAction(
                                  context,
                                  bookingService,
                                  'cancelled',
                                ),
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                ),
                                tooltip: 'Decline Booking',
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: () => _handleAction(
                                  context,
                                  bookingService,
                                  'confirmed',
                                ),
                                icon: const Icon(Icons.check),
                                tooltip: 'Confirm Booking',
                              ),
                            ],
                          )
                        else if (booking.status == BookingStatus.confirmed)
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () => _handleAction(
                                  context,
                                  bookingService,
                                  'cancelled',
                                ),
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _handleAction(
                                  context,
                                  bookingService,
                                  'completed',
                                ),
                                icon: const Icon(Icons.done_all, size: 16),
                                label: const Text(
                                  'Complete',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    BookingService service,
    String action,
  ) async {
    try {
      String message = '';
      if (action == 'confirmed') {
        await service.updateBookingStatus(booking.id, BookingStatus.confirmed);
        message = 'Booking confirmed';
      } else if (action == 'completed') {
        await service.updateBookingStatus(booking.id, BookingStatus.completed);
        message = 'Tour marked as completed!';
      } else if (action == 'cancelled') {
        await service.cancelBooking(booking.id, booking.tourId, booking.seats);
        message = 'Booking cancelled';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: action == 'cancelled'
                ? Colors.orange
                : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  final BookingStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case BookingStatus.pending:
        color = Colors.orange;
        break;
      case BookingStatus.confirmed:
        color = Colors.green;
        break;
      case BookingStatus.cancelled:
        color = Colors.red;
        break;
      case BookingStatus.completed:
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
