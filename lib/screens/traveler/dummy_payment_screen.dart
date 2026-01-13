// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../theme/themed_background.dart';

class DummyPaymentScreen extends StatefulWidget {
  final String bookingId;

  const DummyPaymentScreen({super.key, required this.bookingId});

  @override
  State<DummyPaymentScreen> createState() => _DummyPaymentScreenState();
}

class _DummyPaymentScreenState extends State<DummyPaymentScreen> {
  final BookingService _bookingService = BookingService();
  bool _isLoading = true;
  bool _isProcessing = false;
  BookingModel? _booking;
  String _selectedMethod = 'Debit/Credit Card (Demo)';

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final booking = await _bookingService.getBookingById(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading booking: $e')));
        context.pop();
      }
    }
  }

  Future<void> _processPayment({bool success = true}) async {
    if (_booking == null) return;

    setState(() => _isProcessing = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      if (success) {
        final reference =
            'DEMO-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}';

        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(_booking!.id)
            .update({
              'paymentStatus': 'paid',
              'paymentMethod': _selectedMethod,
              'paymentReference': reference,
              'paidAt': Timestamp.now(),
              'amountPaid': _booking!.totalPrice,
              // Determine status: if it was pending, make it confirmed.
              // If the earning logic relies on 'completed' or 'confirmed', 'confirmed' is good for now.
              'status': 'confirmed',
              'updatedAt': Timestamp.now(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demo payment successful!'),
              backgroundColor: Colors.green,
            ),
          );
          // Go back to my bookings or booking details
          context.go('/traveler/bookings');
        }
      } else {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(_booking!.id)
            .update({'paymentStatus': 'failed', 'updatedAt': Timestamp.now()});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment failure simulated.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isProcessing = false);
          // Reload to show failed status? Or just stay
          _loadBooking();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error processing payment: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_booking == null) {
      return const Scaffold(body: Center(child: Text('Booking not found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Secure Payment (Demo)')),
      body: ThemedBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 24),
              const Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildMethodSelector(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () => _processPayment(success: true),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Pay \$${_booking!.totalPrice.toStringAsFixed(2)} (Demo)',
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isProcessing
                    ? null
                    : () => _processPayment(success: false),
                child: const Text(
                  'Simulate Failure',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Booking Summary',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${_booking!.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _buildRow('Booking ID', _booking!.id.substring(0, 8).toUpperCase()),
            const SizedBox(height: 8),
            _buildRow('Seats', '${_booking!.seats}'),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMethodSelector() {
    return Column(
      children: [
        _buildRadioTile('Debit/Credit Card (Demo)'),
        _buildRadioTile('JazzCash (Demo)'),
        _buildRadioTile('Easypaisa (Demo)'),
      ],
    );
  }

  Widget _buildRadioTile(String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedMethod == value ? Colors.blue : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
        color: _selectedMethod == value
            ? Colors.blue.withValues(alpha: 0.05)
            : Colors.white,
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedMethod,
        onChanged: (val) {
          if (val != null) setState(() => _selectedMethod = val);
        },
        title: Text(value),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.blue;
          }
          return null;
        }),
      ),
    );
  }
}
