import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/tour_service.dart';
import '../../models/tour_model.dart';
import '../../theme/themed_background.dart';

class AgencyToursScreen extends StatefulWidget {
  const AgencyToursScreen({super.key});

  @override
  State<AgencyToursScreen> createState() => _AgencyToursScreenState();
}

class _AgencyToursScreenState extends State<AgencyToursScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final tourService = TourService();

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tours'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ongoing'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: ThemedBackground(
        child: StreamBuilder<List<TourModel>>(
          stream: tourService.streamAgencyTours(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allTours = snapshot.data ?? [];

            return TabBarView(
              controller: _tabController,
              children: [
                _buildToursList(
                  context,
                  allTours
                      .where((t) => t.status != TourStatus.completed)
                      .toList(),
                  'No ongoing tours',
                ),
                _buildToursList(
                  context,
                  allTours
                      .where((t) => t.status == TourStatus.completed)
                      .toList(),
                  'No completed tours',
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/agency/tours/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create New Tour'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildToursList(
    BuildContext context,
    List<TourModel> tours,
    String emptyMessage,
  ) {
    if (tours.isEmpty) {
      return _buildEmptyState(context, emptyMessage);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tours.length,
      itemBuilder: (context, index) {
        final tour = tours[index];
        return _TourManagementCard(tour: tour);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.tour_outlined,
                size: 80,
                color: Colors.blue.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your tour packages will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourManagementCard extends StatelessWidget {
  final TourModel tour;
  const _TourManagementCard({required this.tour});

  @override
  Widget build(BuildContext context) {
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/agency/tours/edit/${tour.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        image: tour.coverImage != null
                            ? DecorationImage(
                                image: NetworkImage(tour.coverImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: tour.coverImage == null
                          ? const Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _StatusChip(status: tour.status),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tour.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tour.location,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoItem(
                            'Duration',
                            '${tour.endDate.difference(tour.startDate).inDays + 1} Days',
                            Icons.timer_outlined,
                          ),
                          _buildInfoItem(
                            'Price',
                            '\$${tour.price.toStringAsFixed(0)}',
                            Icons.attach_money,
                          ),
                          _buildInfoItem(
                            'Booking',
                            '${tour.bookedSeats}/${tour.seats}',
                            Icons.people_outline,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.blue.shade700),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
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
    Color color;
    switch (status) {
      case TourStatus.draft:
        color = Colors.grey;
        break;
      case TourStatus.active:
        color = Colors.green;
        break;
      case TourStatus.inactive:
        color = Colors.orange;
        break;
      case TourStatus.completed:
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
        ],
      ),
      child: Text(
        status.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
