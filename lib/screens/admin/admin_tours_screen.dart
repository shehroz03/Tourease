import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../services/tour_service.dart';
import '../../models/tour_model.dart';
import '../../theme/themed_background.dart';

class AdminToursScreen extends StatelessWidget {
  const AdminToursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tourService = TourService();

    return Scaffold(
      appBar: AppBar(title: const Text('Global Tour Inventory'), elevation: 0),
      body: ThemedBackground(
        child: StreamBuilder<List<TourModel>>(
          stream: tourService.streamAllTours(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final tours = snapshot.data ?? [];
            if (tours.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: [
                _buildSummaryHeader(tours),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    itemCount: tours.length,
                    itemBuilder: (context, index) =>
                        _TourAdminCard(tour: tours[index]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(List<TourModel> tours) {
    final activeCount = tours
        .where((t) => t.status == TourStatus.active)
        .length;
    final totalRevenue = tours.fold(
      0.0,
      (sum, t) => sum + (t.price * t.bookedSeats),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade900,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem(
            'Total Tours',
            '${tours.length}',
            Icons.inventory_2_outlined,
          ),
          _buildSummaryItem(
            'Active',
            '$activeCount',
            Icons.check_circle_outline,
          ),
          _buildSummaryItem(
            'Revenue',
            'Rs. ${NumberFormat.compact().format(totalRevenue)}',
            Icons.payments_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade100, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.blue.shade200,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'No Tours Found',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'All tours from agencies will appear here.',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Text(
        'Error loading tours: $error',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}

class _TourAdminCard extends StatelessWidget {
  final TourModel tour;
  const _TourAdminCard({required this.tour});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tour.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${tour.agencyId.substring(0, 8)}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: tour.status),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                _buildInfoBlock(
                  'Price',
                  'Rs. ${tour.price.toStringAsFixed(0)}',
                  Icons.sell_outlined,
                ),
                const Spacer(),
                _buildInfoBlock(
                  'Seats',
                  '${tour.bookedSeats}/${tour.seats}',
                  Icons.people_outline,
                ),
                const Spacer(),
                _buildInfoBlock(
                  'Location',
                  tour.location,
                  Icons.location_on_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('MMM dd').format(tour.startDate)} - ${DateFormat('MMM dd, yyyy').format(tour.endDate)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/admin/tour/${tour.id}'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: Colors.blue.shade800,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View Details'),
                      Icon(Icons.arrow_forward_ios, size: 10),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBlock(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TourStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = status == TourStatus.active
        ? Colors.green
        : (status == TourStatus.draft
              ? Colors.grey
              : (status == TourStatus.completed ? Colors.blue : Colors.orange));
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
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
