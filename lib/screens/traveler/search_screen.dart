import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/tour_service.dart';
import '../../models/tour_model.dart';
import '../../widgets/tour_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _tourService = TourService();
  List<TourModel> _tours = [];
  List<TourModel> _filteredTours = [];
  bool _isLoading = true;
  String? _selectedCategory;
  final RangeValues _priceRange = const RangeValues(0, 10000);

  final List<String> _categories = [
    'Adventure',
    'Beach',
    'Cultural',
    'Nature',
    'City',
    'Mountain',
  ];

  @override
  void initState() {
    super.initState();
    _loadTours();
  }

  Future<void> _loadTours() async {
    final tours = await _tourService.searchTours();
    setState(() {
      _tours = tours;
      _filteredTours = tours;
      _isLoading = false;
    });
  }

  void _filterTours() {
    setState(() {
      _filteredTours = _tours.where((tour) {
        final matchesSearch = _searchController.text.isEmpty ||
            tour.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            tour.location.toLowerCase().contains(_searchController.text.toLowerCase());

        final matchesCategory = _selectedCategory == null ||
            tour.category == _selectedCategory;

        final matchesPrice = tour.price >= _priceRange.start &&
            tour.price <= _priceRange.end;

        return matchesSearch && matchesCategory && matchesPrice;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Tours'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by destination or tour name',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterTours();
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => _filterTours(),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = null;
                          });
                          _filterTours();
                        },
                      ),
                      const SizedBox(width: 8),
                      ..._categories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory =
                                    _selectedCategory == category ? null : category;
                              });
                              _filterTours();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTours.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tours found',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredTours.length,
                        itemBuilder: (context, index) {
                          final tour = _filteredTours[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TourCard(
                              tour: tour,
                              onTap: () => context.push('/traveler/tour/${tour.id}'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
