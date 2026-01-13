import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/tour_service.dart';
import '../../services/booking_service.dart';
import '../../models/tour_model.dart';
import '../../models/booking_model.dart';
import '../../widgets/tour_card.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/animations/fade_in_slide.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Adventure',
    'Relaxation',
    'Culture',
    'Nature',
    'Urban',
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final tourService = TourService();
    final bookingService = BookingService();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, user),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInSlide(
                    index: 0,
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Explore the world',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            Text(
                              user != null
                                  ? 'Hello, ${user.name} 👋'
                                  : 'Find your next adventure',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person_outline,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInSlide(index: 1, child: _buildCategories()),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (user != null)
                  FadeInSlide(
                    index: 2,
                    child: _buildActiveTripsSection(
                      context,
                      bookingService,
                      user.id,
                    ),
                  ),

                const SizedBox(height: 8),
                FadeInSlide(
                  index: 3,
                  child: _buildGlobalHistorySection(context),
                ),

                const SizedBox(height: 16),
                FadeInSlide(
                  index: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Popular Destinations',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/traveler/search'),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: StreamBuilder<List<TourModel>>(
                stream: tourService.streamActiveTours(userId: user?.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final tours = (snapshot.data ?? []).where((t) {
                    if (_selectedCategory == 'All') return true;
                    return t.category.toLowerCase() ==
                        _selectedCategory.toLowerCase();
                  }).toList();

                  if (tours.isEmpty) {
                    return _buildEmptyState();
                  }

                  return Column(
                    children: tours
                        .asMap()
                        .entries
                        .map(
                          (entry) => FadeInSlide(
                            index: 5 + entry.key,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: TourCard(
                                tour: entry.value,
                                onTap: () => context.push(
                                  '/traveler/tour/${entry.value.id}',
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, user) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'TourEase',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.5,
                    ),
                  ),
                  Text(
                    'JOURNEY BEYOND BOUNDARIES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Hero(
            tag: 'search_bar',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/traveler/search'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Where do you want to go?',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) {
                setState(() => _selectedCategory = cat);
              },
              backgroundColor: Colors.white,
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              showCheckmark: false,
              elevation: isSelected ? 4 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveTripsSection(
    BuildContext context,
    BookingService bookingService,
    String userId,
  ) {
    return StreamBuilder<List<BookingModel>>(
      stream: bookingService.streamTravelerBookings(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final bookings = snapshot.data!;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait(
            bookings.map((b) async {
              final tour = await TourService().getTourById(b.tourId);
              return {'booking': b, 'tour': tour};
            }),
          ),
          builder: (context, tourSnapshot) {
            if (!tourSnapshot.hasData) return const SizedBox.shrink();

            final now = DateTime.now();
            final activeBookingsData = tourSnapshot.data!.where((data) {
              final b = data['booking'] as BookingModel;
              final t = data['tour'] as TourModel?;
              return b.status == BookingStatus.confirmed &&
                  t != null &&
                  t.endDate.isAfter(now);
            }).toList();

            if (activeBookingsData.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Active Trips',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/traveler/bookings'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: activeBookingsData.length,
                    itemBuilder: (context, index) => _ActiveTripCard(
                      booking: activeBookingsData[index]['booking'],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 48),
          Icon(Icons.explore_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No tours found in this category',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Try exploring other categories!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalHistorySection(BuildContext context) {
    final reviewService = ReviewService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Success Stories',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'See travelers who recently completed their journey',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<ReviewModel>>(
          stream: reviewService.streamAllReviews(limit: 5),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final reviews = snapshot.data!;

            return SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Container(
                    width: 260,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[100]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push(
                          '/traveler/success-story/${review.id}',
                          extra: review,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.blue[50],
                                backgroundImage: review.travelerPhotoUrl != null
                                    ? CachedNetworkImageProvider(
                                        review.travelerPhotoUrl!,
                                      )
                                    : null,
                                child: review.travelerPhotoUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 20,
                                        color: Colors.blue,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      review.travelerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 12,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Completed a tour',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          Icons.star,
                                          size: 10,
                                          color: i < review.rating
                                              ? Colors.amber
                                              : Colors.grey[200],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  final BookingModel booking;
  const _ActiveTripCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TourModel?>(
      future: TourService().getTourById(booking.tourId),
      builder: (context, snapshot) {
        final tour = snapshot.data;
        return Container(
          width: 300,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/live-track/${booking.tourId}'),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: Colors.greenAccent,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'LIVE NOW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.location_searching,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      tour?.title ?? 'Loading Trip...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to track live location',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
