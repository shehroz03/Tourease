import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  /// Simulates payment processing with artificial delay
  /// Returns true for success, false for failure (based on card validation)
  Future<PaymentResult> processPayment({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
  }) async {
    // Simulate network delay (1-2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    // Validate payment method
    if (!_validatePaymentMethod(method)) {
      return PaymentResult(
        success: false,
        message: 'Invalid payment details. Please check and try again.',
        transactionId: null,
      );
    }

    // Simulate random success/failure for demo variety (90% success rate)
    final random = DateTime.now().millisecondsSinceEpoch % 10;
    // 0 = fail, 1-9 = success.
    final isSuccess = random != 0;

    // For demo stability, you might want 100% success if card is valid,
    // but random failure adds realism. We'll stick to 90%.

    if (isSuccess) {
      // Generate mock transaction ID
      final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';

      try {
        // Update booking status in Firestore
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({
              'status': 'confirmed',
              'paymentStatus': 'paid',
              'transactionId': transactionId,
              'paidAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        return PaymentResult(
          success: true,
          message: 'Payment successful! Your booking is confirmed.',
          transactionId: transactionId,
        );
      } catch (e) {
        return PaymentResult(
          success: false,
          message: 'Payment processed but failed to update booking: $e',
          transactionId: transactionId,
        );
      }
    } else {
      return PaymentResult(
        success: false,
        message: 'Payment declined by bank. Please try another card.',
        transactionId: null,
      );
    }
  }

  bool _validatePaymentMethod(PaymentMethod method) {
    if (method is CreditCard) {
      // Basic card validation
      // Remove spaces for length check
      final cleanNumber = method.cardNumber.replaceAll(' ', '');
      if (cleanNumber.length != 16) return false;

      if (method.cvv.length != 3) return false;
      if (method.expiryMonth < 1 || method.expiryMonth > 12) return false;

      // Allow current year
      if (method.expiryYear < DateTime.now().year) return false;
      return true;
    }
    return true;
  }
}

class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;

  PaymentResult({
    required this.success,
    required this.message,
    this.transactionId,
  });
}

// Payment method models
abstract class PaymentMethod {}

class CreditCard extends PaymentMethod {
  final String cardNumber;
  final String cardholderName;
  final int expiryMonth;
  final int expiryYear;
  final String cvv;

  CreditCard({
    required this.cardNumber,
    required this.cardholderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
  });
}
