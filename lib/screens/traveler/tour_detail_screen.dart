import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../services/tour_service.dart';
import '../../services/booking_service.dart';
import '../../services/chat_service.dart';
import '../../models/tour_model.dart';
import '../../models/booking_model.dart';
import '../../widgets/tour_route_map.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';

class TourDetailScreen extends StatefulWidget {
  final String tourId;
  const TourDetailScreen({super.key, required this.tourId});

  @override
  State<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends State<TourDetailScreen> {
  final _tourService = TourService();
  final _bookingService = BookingService();
  final _chatService = ChatService();
  TourModel? _tour;
  bool _isLoading = true;
  bool _isBooking = false;
  bool _isStartingChat = false;
  bool _hasBooking = false;
  int _selectedSeats = 1;
  late Stream<List<ReviewModel>> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _reviewsStream = ReviewService().streamReviewsForTour(widget.tourId);
    _loadTour();
  }

  Future<void> _loadTour() async {
    final tour = await _tourService.getTourById(widget.tourId);
    if (!mounted) return;

    final user = context.read<AuthProvider>().user;
    bool hasBooking = false;
    if (user != null) {
      hasBooking = await _bookingService.hasBookingForTour(
        user.id,
        widget.tourId,
      );
    }

    if (mounted) {
      setState(() {
        _tour = tour;
        _hasBooking = hasBooking;
        // Load agency reviews instead of tour-specific ones for broader social proof
        if (tour != null) {
          _reviewsStream = ReviewService().streamApprovedReviewsForAgency(
            tour.agencyId,
          );
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _bookTour() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || _tour == null) return;
    setState(() => _isBooking = true);

    try {
      final booking = BookingModel(
        id: '',
        tourId: _tour!.id,
        travelerId: user.id,
        agencyId: _tour!.agencyId,
        status: BookingStatus.pending,
        totalPrice: _tour!.price * _selectedSeats,
        seats: _selectedSeats,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bookingId = await _bookingService.createBooking(booking);
      if (mounted) context.push('/payment/$bookingId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  Future<void> _startChat() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || _tour == null) return;
    setState(() => _isStartingChat = true);

    try {
      final chatId = await _chatService.getOrCreateChat(
        travelerId: user.id,
        agencyId: _tour!.agencyId,
        tourId: _tour!.id,
      );
      if (mounted) context.push('/chat/$chatId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_tour == null) {
      return const Scaffold(body: Center(child: Text('Tour not found')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(),
                  const SizedBox(height: 24),
                  _buildInfoChips(),
                  const SizedBox(height: 32),
                  const Text(
                    'About this tour',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _tour!.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildRouteSection(),
                  const SizedBox(height: 32),
                  if (!_hasBooking) _buildSeatsPicker(),
                  const SizedBox(height: 32),
                  _buildReviewsSection(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _hasBooking
          ? _buildBookedBottomBar()
          : _buildBottomBar(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final pages = <String>[];
    if (_tour!.coverImage != null) pages.add(_tour!.coverImage!);
    pages.addAll(_tour!.galleryImages.where((g) => g != _tour!.coverImage));

    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      stretch: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: pages.isEmpty
            ? Container(
                color: Colors.blue[50],
                child: const Icon(Icons.tour, size: 80, color: Colors.blue),
              )
            : _TourImageCarousel(pages: pages),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _tour!.category.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                if (_hasBooking)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'BOOKED',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  _tour!.averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  ' (${_tour!.reviewCount})',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _tour!.title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => context.push('/agency-profile/${_tour!.agencyId}'),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue[50],
                    child: const Icon(
                      Icons.business,
                      size: 18,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Hosted by ${_tour!.agencyName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_tour!.agencyVerified) const SizedBox(width: 4),
                            if (_tour!.agencyVerified)
                              const Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                        const Text(
                          'Top Rated Agency',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isStartingChat ? null : _startChat,
                    icon: _isStartingChat
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        context.push('/agency-profile/${_tour!.agencyId}'),
                    icon: const Icon(Icons.business, size: 18),
                    label: const Text('View Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChips() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // 3 items, 2 spaces. Calculate item width.
        // We want some spacing, say 16px between items.
        // (W - 16*2) / 3
        final itemWidth = (availableWidth - 32) / 3;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoChip(
              Icons.location_on_outlined,
              'Location',
              _tour!.location,
              itemWidth,
            ),
            _buildInfoChip(
              Icons.calendar_today_outlined,
              'Duration',
              '${_tour!.endDate.difference(_tour!.startDate).inDays} Days',
              itemWidth,
            ),
            _buildInfoChip(
              Icons.people_outline,
              'Capacity',
              '${_tour!.availableSeats} Seats',
              itemWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    String value,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSeatsPicker() {
    if (_tour!.availableSeats <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Seats',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Number of travelers',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildSeatBtn(Icons.remove, () {
                if (_selectedSeats > 1) setState(() => _selectedSeats--);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_selectedSeats',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildSeatBtn(Icons.add, () {
                if (_selectedSeats < _tour!.availableSeats) {
                  setState(() => _selectedSeats++);
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeatBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: Colors.blue),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Total Price',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${(_tour!.price * _selectedSeats).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _tour!.availableSeats > 0 && !_isBooking
                  ? _bookTour
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
                shadowColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.4),
              ),
              child: _isBooking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Reserve Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookedBottomBar() {
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => context.go('/traveler/bookings'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 4,
          shadowColor: Colors.green.withValues(alpha: 0.4),
        ),
        child: const Text(
          'Already Booked - View Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildRouteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tour Route',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        TourRouteMap(tour: _tour!, height: 250),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'What Travelers Say',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.push('/agency-profile/${_tour!.agencyId}'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<ReviewModel>>(
          stream: _reviewsStream,
          builder: (context, snapshot) {
            final reviews = snapshot.data ?? [];
            if (reviews.isEmpty) {
              return const Center(
                child: Text(
                  'No reviews yet',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length > 2 ? 2 : reviews.length,
              itemBuilder: (context, index) =>
                  _ReviewCard(review: reviews[index]),
            );
          },
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: review.travelerPhotoUrl != null
                    ? CachedNetworkImageProvider(review.travelerPhotoUrl!)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.travelerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star,
                        size: 12,
                        color: i < review.rating
                            ? Colors.amber
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment ?? '',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TourImageCarousel extends StatefulWidget {
  final List<String> pages;
  const _TourImageCarousel({required this.pages});

  @override
  State<_TourImageCarousel> createState() => _TourImageCarouselState();
}

class _TourImageCarouselState extends State<_TourImageCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.pages.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, index) => CachedNetworkImage(
            imageUrl: widget.pages[index],
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.pages.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _index == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _index == i ? Colors.white : Colors.white54,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
