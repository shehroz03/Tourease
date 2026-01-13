import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/tour_service.dart';
import '../../services/earnings_service.dart';
import '../../models/tour_model.dart';
import '../../models/agency_earnings_model.dart';
import '../../theme/themed_background.dart';
import '../../widgets/animations/fade_in_slide.dart';

class AgencyDashboard extends StatefulWidget {
  const AgencyDashboard({super.key});

  @override
  State<AgencyDashboard> createState() => _AgencyDashboardState();
}

class _AgencyDashboardState extends State<AgencyDashboard> {
  final _tourService = TourService();
  final _earningsService = EarningsService();
  bool _isLoading = true;
  List<TourModel> _tours = [];
  int _totalBookings = 0;
  // removed separate _totalRevenue as it will be in the Earnings card

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      return;
    }

    try {
      // Refresh earnings data
      await _earningsService.recalculateTotalEarnings(user.id);

      final tours = await _tourService.getAgencyTours(user.id);
      int bookings = 0;
      // We still calculate bookings count here
      for (TourModel tour in tours) {
        bookings += tour.bookedSeats;
      }

      if (mounted) {
        setState(() {
          _tours = tours;
          _totalBookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ThemedBackground(
              child: RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 180,
                      pinned: true,
                      backgroundColor: theme.colorScheme.primary,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -20,
                                top: -20,
                                child: Icon(
                                  Icons.dashboard_outlined,
                                  size: 200,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, ${user?.name ?? 'Agency'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Here is what is happening today',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeInSlide(
                              index: 1,
                              child: StreamBuilder<AgencyEarningsModel>(
                                stream: _earningsService.streamEarnings(
                                  user?.id ?? '',
                                ),
                                builder: (context, snapshot) {
                                  final earnings = snapshot.data;
                                  return _AgencyEarningsCard(
                                    earnings: earnings,
                                    onWithdraw: () =>
                                        _showWithdrawDialog(earnings),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            FadeInSlide(index: 2, child: _buildStatsGrid()),
                            const SizedBox(height: 32),
                            FadeInSlide(
                              index: 3,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Recent Tours',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.push('/agency/tours'),
                                    child: const Text('See All'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_tours.isEmpty)
                      const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(48.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No tours created yet.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final tour = _tours[index];
                            return FadeInSlide(
                              index: 4 + index,
                              child: _buildTourCard(tour),
                            );
                          }, childCount: _tours.length > 5 ? 5 : _tours.length),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        _buildStatCard(
          'Total Tours',
          _tours.length.toString(),
          Icons.map_outlined,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Bookings',
          _totalBookings.toString(),
          Icons.people_outline,
          Colors.orange,
        ),
        _buildStatCard(
          'Agency Rating',
          '4.9',
          Icons.star_outline,
          Colors.amber,
        ),
      ],
    );
  }

  Future<void> _showWithdrawDialog(AgencyEarningsModel? earnings) async {
    if (earnings == null || earnings.availableBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient funds to withdraw.')),
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    final amountController = TextEditingController();
    final bankNameController = TextEditingController(text: user?.bankName);
    final accountHolderController = TextEditingController(
      text: user?.bankAccountHolderName,
    );
    final accountNumberController = TextEditingController(
      text: user?.bankAccountNumber,
    );

    // For Card (simulated)
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();

    int selectedTab = 0; // 0 for Bank, 1 for Card

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setModalState) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 12,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Withdraw Funds',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Choose your preferred withdrawal method',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Balance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade800, Colors.blue.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AVAILABLE BALANCE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${earnings.availableBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Amount Input
                  const Text(
                    'Amount to Withdraw',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      hintText: '0.00',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Payment Method Tabs
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedTab == 0
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedTab == 0
                                    ? Colors.blue
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.account_balance,
                                  color: selectedTab == 0
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                const Text(
                                  'Bank Account',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedTab == 1
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedTab == 1
                                    ? Colors.blue
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.credit_card,
                                  color: selectedTab == 1
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                const Text(
                                  'Debit/Credit Card',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Method specific fields
                  if (selectedTab == 0) ...[
                    TextField(
                      controller: bankNameController,
                      decoration: InputDecoration(
                        labelText: 'Bank Name',
                        prefixIcon: const Icon(Icons.business_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: accountNumberController,
                      decoration: InputDecoration(
                        labelText: 'Account Number / IBAN',
                        prefixIcon: const Icon(Icons.numbers),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: accountHolderController,
                      decoration: InputDecoration(
                        labelText: 'Account Holder Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: cardNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Card Number',
                        hintText: 'XXXX XXXX XXXX XXXX',
                        prefixIcon: const Icon(Icons.credit_card_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: expiryController,
                            decoration: InputDecoration(
                              labelText: 'Expiry Date',
                              hintText: 'MM/YY',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: cvvController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'CVV',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Note: Card details are used for simulation purposes.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          _showError('Please enter a valid amount');
                          return;
                        }
                        if (amount > earnings.availableBalance) {
                          _showError('Amount exceeds available balance');
                          return;
                        }

                        if (selectedTab == 0) {
                          if (bankNameController.text.isEmpty ||
                              accountNumberController.text.isEmpty ||
                              accountHolderController.text.isEmpty) {
                            _showError('Please fill all bank details');
                            return;
                          }
                        } else {
                          if (cardNumberController.text.isEmpty ||
                              expiryController.text.isEmpty ||
                              cvvController.text.isEmpty) {
                            _showError('Please fill all card details');
                            return;
                          }
                        }

                        Navigator.pop(sheetContext);
                        _executeWithdrawal(
                          earnings,
                          amount,
                          selectedTab == 0
                              ? bankNameController.text
                              : 'Card ending in ${cardNumberController.text.length > 4 ? cardNumberController.text.substring(cardNumberController.text.length - 4) : '...'}',
                          accountHolderController.text,
                          selectedTab == 0
                              ? accountNumberController.text
                              : cardNumberController.text,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Confirm Withdrawal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      // Clean up controllers
      amountController.dispose();
      bankNameController.dispose();
      accountHolderController.dispose();
      accountNumberController.dispose();
      cardNumberController.dispose();
      expiryController.dispose();
      cvvController.dispose();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _executeWithdrawal(
    AgencyEarningsModel earnings,
    double amount,
    String bankName,
    String holderName,
    String accountNumber,
  ) async {
    try {
      await _earningsService.requestWithdrawal(
        earnings.agencyId,
        amount,
        bankName: bankName,
        accountHolderName: holderName,
        accountNumber: accountNumber,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Withdrawal request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdrawal failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTourCard(TourModel tour) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            onTap: tour.status == TourStatus.active
                ? () => context.push(
                    '/agency/live-console/${tour.id}',
                    extra: tour.title,
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: tour.coverImage != null
                          ? DecorationImage(
                              image: NetworkImage(tour.coverImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey[100],
                    ),
                    child: tour.coverImage == null
                        ? const Icon(Icons.image_outlined, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tour.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                tour.location,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildMiniChip(
                              Icons.people_outline,
                              '${tour.bookedSeats}/${tour.seats}',
                              Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            _buildMiniChip(
                              Icons.check_circle_outline,
                              tour.status.name.toUpperCase(),
                              _getStatusColor(tour.status),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  FittedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${tour.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Text(
                          'per person',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TourStatus status) {
    switch (status) {
      case TourStatus.active:
        return Colors.green;
      case TourStatus.draft:
        return Colors.orange;
      case TourStatus.inactive:
        return Colors.red;
      case TourStatus.completed:
        return Colors.blue;
    }
  }
}

class _AgencyEarningsCard extends StatelessWidget {
  final AgencyEarningsModel? earnings;
  final VoidCallback onWithdraw;

  const _AgencyEarningsCard({required this.earnings, required this.onWithdraw});

  @override
  Widget build(BuildContext context) {
    // If earnings not loaded yet, show skeleton or zero
    final totalEarnings = earnings?.totalEarnings ?? 0.0;
    final available = earnings?.availableBalance ?? 0.0;
    final withdrawn = earnings?.totalWithdrawn ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Earnings',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Icon(
                Icons.monetization_on_outlined,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${totalEarnings.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${available.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Withdrawn',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${withdrawn.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: available > 0 ? onWithdraw : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
              ),
              child: const Text(
                'Withdraw Funds',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
