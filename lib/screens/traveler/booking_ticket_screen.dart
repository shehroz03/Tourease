import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

import '../../models/booking_model.dart';
import '../../models/tour_model.dart';
import '../../services/booking_service.dart';
import '../../services/tour_service.dart';
import '../../theme/themed_background.dart';

class BookingTicketScreen extends StatefulWidget {
  final String bookingId;
  const BookingTicketScreen({super.key, required this.bookingId});

  @override
  State<BookingTicketScreen> createState() => _BookingTicketScreenState();
}

class _BookingTicketScreenState extends State<BookingTicketScreen> {
  final _bookingService = BookingService();
  final _tourService = TourService();

  BookingModel? _booking;
  TourModel? _tour;
  String? _travelerName;
  String? _agencyName;
  String? _agencyContact; // Optional: Agency contact if available
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTicketData();
  }

  Future<void> _loadTicketData() async {
    try {
      // 1. Fetch Booking
      final booking = await _bookingService.getBookingById(widget.bookingId);
      if (booking == null) {
        throw Exception('Booking not found');
      }

      // 2. Fetch Tour
      final tour = await _tourService.getTourById(booking.tourId);

      // 3. Fetch Traveler Name
      String? travelerName;
      try {
        final travelerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(booking.travelerId)
            .get();
        if (travelerDoc.exists) {
          final data = travelerDoc.data();
          travelerName = data?['name'] ?? data?['fullName'];
        }
      } catch (e) {
        debugPrint('Error fetching traveler: $e');
      }

      // 4. Fetch Agency Details
      String? agencyName;
      String? agencyContact;
      try {
        final agencyId = booking.agencyId;
        final agencyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(agencyId)
            .get();
        if (agencyDoc.exists) {
          final data = agencyDoc.data();
          agencyName = data?['name'] ?? data?['agencyName'] ?? 'Unknown Agency';
          agencyContact = data?['phoneNumber'] ?? data?['phone'];
        }
      } catch (e) {
        debugPrint('Error fetching agency: $e');
      }

      if (mounted) {
        setState(() {
          _booking = booking;
          _tour = tour;
          _travelerName = travelerName;
          _agencyName = agencyName;
          _agencyContact = agencyContact;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Ticket...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('Error loading ticket: ${_error ?? "Unknown error"}'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Confirmation')),
      body: ThemedBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTicketCard(),
              const SizedBox(height: 24),
              // Optional: Download/Share buttons could go here
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.blue, // Standard header color
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Center(
              child: Text(
                'E-TICKET',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),

          // QR Code Section
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 24),
            color: Colors.white, // Explicit white bg for QR readability
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data:
                    'https://tourease-demo.web.app/verify-ticket?id=${_booking!.id}',
                version: QrVersions.auto,
                size: 180.0,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
          ),

          const Divider(height: 1),

          // Core Ticket Info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Ticket Number & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TICKET NUMBER', style: _labelStyle),
                        const SizedBox(height: 4),
                        SelectableText(
                          'TKT-${_booking!.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _booking!.status == BookingStatus.confirmed
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _booking!.status == BookingStatus.confirmed
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      child: Text(
                        _booking!.status.name.toUpperCase(),
                        style: TextStyle(
                          color: _booking!.status == BookingStatus.confirmed
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Passenger Details
                _buildSectionHeader('PASSENGER DETAILS'),
                _buildDetailRow('Name', _travelerName ?? 'N/A'),
                _buildDetailRow(
                  'Booking Date',
                  DateFormat('MMM dd, yyyy').format(_booking!.createdAt),
                ),

                const SizedBox(height: 24),

                // Tour Details
                if (_tour != null) ...[
                  _buildSectionHeader('TOUR DETAILS'),
                  _buildDetailRow('Tour Name', _tour!.title),
                  _buildDetailRow(
                    'Dates',
                    '${DateFormat('MMM dd').format(_tour!.startDate)} - ${DateFormat('MMM dd, yyyy').format(_tour!.endDate)}',
                  ),
                  _buildDetailRow('Seats', '${_booking!.seats}'),
                  _buildDetailRow(
                    'Pickup',
                    _tour!.startLocation?.address ?? 'Not specified',
                  ),
                  const SizedBox(height: 24),
                ],

                // Agency Details
                _buildSectionHeader('AGENCY DETAILS'),
                _buildDetailRow(
                  'Agency',
                  _agencyName ?? 'Information not available',
                ),
                if (_agencyContact != null)
                  _buildDetailRow('Contact', _agencyContact!),

                const SizedBox(height: 24),

                // Payment Details
                _buildSectionHeader('PAYMENT'),
                _buildDetailRow(
                  'Total Amount',
                  'Rs. ${_booking!.totalPrice.toStringAsFixed(2)}',
                  isBold: true,
                ),
                _buildRow(
                  'Payment Status',
                  _booking!.status == BookingStatus.confirmed
                      ? 'PAID / CONFIRMED'
                      : 'PENDING',
                  valueColor: _booking!.status == BookingStatus.confirmed
                      ? Colors.green
                      : Colors.orange,
                  isBold: true,
                ),

                const SizedBox(height: 32),

                // Footer Note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please arrive at the pickup location 15 minutes before departure time.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom decorations (circles for ticket tears)
          // Optional visual flair
        ],
      ),
    );
  }

  static const _labelStyle = TextStyle(
    color: Colors.grey,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _labelStyle),
        const Divider(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
