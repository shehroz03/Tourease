import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking_model.dart';
import 'package:intl/intl.dart';

class TicketVerificationScreen extends StatefulWidget {
  final String bookingId;

  const TicketVerificationScreen({super.key, required this.bookingId});

  @override
  State<TicketVerificationScreen> createState() =>
      _TicketVerificationScreenState();
}

class _TicketVerificationScreenState extends State<TicketVerificationScreen> {
  BookingModel? _booking;
  String? _tourName;
  String? _travelerName;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final booking = BookingModel.fromFirestore(doc);

        // Fetch additional details
        String tourName = 'Unknown Tour';
        String travelerName = 'Unknown Traveler';

        try {
          final tourDoc = await FirebaseFirestore.instance
              .collection('tours')
              .doc(booking.tourId)
              .get();
          if (tourDoc.exists) {
            final data = tourDoc.data();
            if (data != null && data.containsKey('title')) {
              tourName = data['title'];
            }
          }
        } catch (e) {
          debugPrint('Error fetching tour: $e');
        }

        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(booking.travelerId)
              .get();
          if (userDoc.exists) {
            final data = userDoc.data();
            if (data != null && data.containsKey('name')) {
              travelerName = data['name'];
            } else if (data != null && data.containsKey('firstName')) {
              travelerName = '${data['firstName']} ${data['lastName'] ?? ''}';
            }
          }
        } catch (e) {
          debugPrint('Error fetching user (might be restricted): $e');
          travelerName = 'Restricted';
        }

        // Validate ticket status
        if (booking.status == BookingStatus.confirmed ||
            booking.status == BookingStatus.completed ||
            booking.status == BookingStatus.pending) {
          // Pending is technically valid for verification of existence, but maybe not entry?
          // Prompt said "VALID or INVALID". Usually Pending is NOT valid for entry.
          // I will mark Pending as "Payment Pending".

          setState(() {
            _booking = booking;
            _tourName = tourName;
            _travelerName = travelerName;
            _isLoading = false;
          });
        } else {
          // Cancelled
          setState(() {
            _booking = booking; // Still show it, but as invalid UI
            _tourName = tourName;
            _travelerName = travelerName;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Ticket not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error verifying ticket: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Ticket Verification'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cancel, color: Colors.red, size: 80),
                const SizedBox(height: 24),
                const Text(
                  'INVALID TICKET',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Determine status UI
    bool isValid =
        _booking!.status == BookingStatus.confirmed ||
        _booking!.status == BookingStatus.completed;
    Color statusColor = isValid
        ? Colors.green
        : (_booking!.status == BookingStatus.cancelled
              ? Colors.red
              : Colors.orange);
    String statusText = isValid
        ? 'VALID TICKET'
        : (_booking!.status == BookingStatus.cancelled
              ? 'CANCELLED'
              : 'PAYMENT PENDING');
    IconData statusIcon = isValid
        ? Icons.check_circle
        : (_booking!.status == BookingStatus.cancelled
              ? Icons.cancel
              : Icons.warning);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ticket Verification'),
        backgroundColor: statusColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 64),
                    const SizedBox(height: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Ticket details card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'Ticket Number',
                        'TKT-${_booking!.id.substring(0, 8).toUpperCase()}',
                        bold: true,
                      ),
                      const Divider(height: 24),
                      const Text(
                        'PASSENGER DETAILS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Name', _travelerName ?? 'N/A'),
                      const Divider(height: 24),
                      const Text(
                        'TOUR DETAILS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Tour', _tourName ?? 'N/A'),
                      // BookingModel doesn't have startDate, Tour has it.
                      // Wait, BookingModel doesn't have startDate?
                      // I need to check BookingModel again.
                      // It DOES NOT. It has createdAt.
                      // Tour has startDate. I should fetch it or just show Booking Date.
                      // Prompt code used `_booking!.startDate`.
                      // I will use _booking!.createdAt for Booking Date.
                      _buildInfoRow(
                        'Booked Date',
                        _formatDate(_booking!.createdAt),
                      ),
                      _buildInfoRow('Seats', '${_booking!.seats}'),
                      const Divider(height: 24),
                      _buildInfoRow(
                        'Status',
                        _booking!.status.name.toUpperCase(),
                        valueColor: statusColor,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Footer
              Text(
                'Verified on ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 16,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }
}
