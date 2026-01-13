import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../services/tour_service.dart';
import '../../services/cloudinary_service.dart';
import '../../models/tour_model.dart';
import '../../models/location_model.dart';
import '../../widgets/location_picker_dialog.dart';
import '../../theme/themed_background.dart';

class CreateTourScreen extends StatefulWidget {
  final String? tourId;
  const CreateTourScreen({super.key, this.tourId});

  @override
  State<CreateTourScreen> createState() => _CreateTourScreenState();
}

class _CreateTourScreenState extends State<CreateTourScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tourService = TourService();
  final _imagePicker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();

  String _category = 'Adventure';
  TourStatus _status = TourStatus.active;
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  String? _coverImageUrl;
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  bool _isUploading = false;
  TourModel? _existingTour;
  LocationData? _startLocation;
  LocationData? _endLocation;
  List<TourStop> _stops = [];

  final List<XFile> _galleryImages = [];
  final List<Uint8List> _galleryImageBytes = [];
  List<String> _galleryImageUrls = [];

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
    if (widget.tourId != null) _loadTour();
  }

  Future<void> _loadTour() async {
    setState(() => _isLoading = true);
    final tour = await _tourService.getTourById(widget.tourId!);
    if (!mounted) return;
    if (tour != null) {
      setState(() {
        _existingTour = tour;
        _titleController.text = tour.title;
        _descriptionController.text = tour.description;
        _locationController.text = tour.location;
        _priceController.text = tour.price.toString();
        _seatsController.text = tour.seats.toString();
        _category = tour.category;
        _status = tour.status;
        _startDate = tour.startDate;
        _endDate = tour.endDate;
        _coverImageUrl = tour.coverImage;
        _galleryImageUrls = List.from(tour.galleryImages);
        _startLocation = tour.startLocation;
        _endLocation = tour.endLocation;
        _stops = List.from(tour.stops);
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImage = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _pickGalleryImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    final totalNow = _galleryImageUrls.length + _galleryImages.length;
    if (picked != null && totalNow < 4) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _galleryImages.add(picked);
        _galleryImageBytes.add(bytes);
      });
    } else if (totalNow >= 4 && picked != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 4 gallery images allowed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _removeGalleryImage(int index) {
    setState(() {
      final existingCount = _galleryImageUrls.length;
      if (index < existingCount) {
        _galleryImageUrls.removeAt(index);
      } else {
        final localIndex = index - existingCount;
        _galleryImages.removeAt(localIndex);
        _galleryImageBytes.removeAt(localIndex);
      }
    });
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: Colors.blue.shade700),
        ),
        child: child!,
      ),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveTour() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      String? imageUrl = _coverImageUrl;
      if (_imageBytes != null && _selectedImage != null) {
        setState(() => _isUploading = true);
        imageUrl = await CloudinaryService.uploadFromBytes(
          bytes: _imageBytes!,
          fileName: _selectedImage!.name,
          folder: 'tours/${user.id}',
        );
      }

      final List<String> finalGalleryUrls = List.from(_galleryImageUrls);
      if (_galleryImageBytes.isNotEmpty) {
        setState(() => _isUploading = true);
        final names = _galleryImages
            .map(
              (e) => e.name.isNotEmpty
                  ? e.name
                  : 'gal_${DateTime.now().millisecondsSinceEpoch}.jpg',
            )
            .toList();
        final uploaded = await CloudinaryService.uploadMultipleFromBytes(
          bytesList: _galleryImageBytes,
          fileNames: names,
          folder: 'tours/${user.id}',
        );
        finalGalleryUrls.addAll(uploaded);
      }

      final tour = TourModel(
        id: _existingTour?.id ?? '',
        agencyId: user.id,
        agencyName: user.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        price: double.parse(_priceController.text),
        category: _category,
        seats: int.parse(_seatsController.text),
        bookedSeats: _existingTour?.bookedSeats ?? 0,
        coverImage: imageUrl,
        galleryImages: finalGalleryUrls,
        status: _status,
        startLocation: _startLocation,
        endLocation: _endLocation,
        stops: _stops,
        agencyVerified: user.verified,
        agencyStatus: user.status.name,
        createdAt: _existingTour?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_existingTour != null) {
        await _tourService.updateTour(_existingTour!.id, tour.toFirestore());
      } else {
        await _tourService.createTour(tour);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _existingTour != null ? 'Tour updated!' : 'Tour created!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existingTour != null ? 'Edit Tour' : 'Create New Tour'),
        elevation: 0,
      ),
      body: ThemedBackground(
        child: _isLoading && _existingTour == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildImageSection(),
                      const SizedBox(height: 32),
                      _buildGallerySection(),
                      const SizedBox(height: 32),
                      _buildGeneralInfo(),
                      const SizedBox(height: 32),
                      _buildRouteSection(),
                      const SizedBox(height: 48),
                      _buildSubmitButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Cover Image'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 220,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: _imageBytes != null
                  ? Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : _coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _coverImageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) =>
                          const Center(child: CircularProgressIndicator()),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Tour Gallery (Up to 4)'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: (() {
            final t = _galleryImageUrls.length + _galleryImages.length;
            return t < 4 ? t + 1 : t;
          })(),
          itemBuilder: (context, index) {
            final existingCount = _galleryImageUrls.length;
            final localCount = _galleryImages.length;
            final total = existingCount + localCount;

            if (index == total && total < 4) {
              return GestureDetector(
                onTap: _pickGalleryImage,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.blue.shade100,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 30,
                        color: Colors.blue.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          color: Colors.blue.shade300,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final isExisting = index < existingCount;
            return Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: isExisting
                        ? CachedNetworkImage(
                            imageUrl: _galleryImageUrls[index],
                            fit: BoxFit.cover,
                          )
                        : Image.memory(
                            _galleryImageBytes[index - existingCount],
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () => _removeGalleryImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildGeneralInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('General Details'),
          const SizedBox(height: 20),
          _buildTextField(_titleController, 'Tour Title', Icons.title),
          const SizedBox(height: 16),
          _buildTextField(
            _descriptionController,
            'Description',
            Icons.description,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _locationController,
            'Main City/Location',
            Icons.location_on,
          ),
          const SizedBox(height: 16),
          _buildDropdown(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  _priceController,
                  'Price (\$)',
                  Icons.attach_money,
                  isNumber: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  _seatsController,
                  'Seats',
                  Icons.people_outline,
                  isNumber: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDatePicker('Start', _startDate, true)),
              const SizedBox(width: 16),
              Expanded(child: _buildDatePicker('End', _endDate, false)),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusDropdown(),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: _buildInputDecoration(label, icon),
      validator: (v) => v?.isEmpty == true ? 'Required' : null,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: _buildInputDecoration('Category', Icons.category_outlined),
      items: _categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() => _category = v!),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<TourStatus>(
      initialValue: _status,
      decoration: _buildInputDecoration('Current Status', Icons.flag_outlined),
      items: TourStatus.values
          .map(
            (s) =>
                DropdownMenuItem(value: s, child: Text(s.name.toUpperCase())),
          )
          .toList(),
      onChanged: (v) => setState(() => _status = v!),
    );
  }

  Widget _buildDatePicker(String label, DateTime date, bool isStart) {
    return InkWell(
      onTap: () => _selectDate(isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Tour Route'),
          const SizedBox(height: 20),
          _buildLocationItem(
            'Starting Point',
            _startLocation,
            Icons.play_circle_outline,
            Colors.green,
            () async {
              final loc = await _showLocationPicker(_startLocation);
              if (loc != null) setState(() => _startLocation = loc);
            },
          ),
          const Padding(
            padding: EdgeInsets.only(left: 36),
            child: VerticalDivider(width: 1, thickness: 1),
          ),
          const SizedBox(height: 12),
          ..._stops.asMap().entries.map(
            (e) => Column(
              children: [
                _buildStopItem(e.key, e.value),
                const Padding(
                  padding: EdgeInsets.only(left: 36),
                  child: VerticalDivider(width: 1, thickness: 1),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          _buildLocationItem(
            'Ending Destination',
            _endLocation,
            Icons.stop_circle,
            Colors.red,
            () async {
              final loc = await _showLocationPicker(_endLocation);
              if (loc != null) setState(() => _endLocation = loc);
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: _addStop,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add Mid-Tour Stop'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(
    String label,
    LocationData? loc,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  loc?.address ?? 'Tap to select location',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: loc == null ? Colors.blue.shade200 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildStopItem(int index, TourStop stop) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stop ${index + 1}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                stop.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.remove_circle_outline,
            color: Colors.red,
            size: 20,
          ),
          onPressed: () => setState(() {
            _stops.removeAt(index);
            for (int i = 0; i < _stops.length; i++) {
              _stops[i] = _stops[i].copyWith(order: i);
            }
          }),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveTour,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 5,
        shadowColor: Colors.blue.withValues(alpha: 0.3),
      ),
      child: _isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isUploading ? 'Uploading Assets...' : 'Saving Tour...',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            )
          : Text(
              _existingTour != null
                  ? 'Update Tour Package'
                  : 'Publish Tour Package',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.blue.shade200),
        const SizedBox(height: 12),
        Text(
          'Upload Cover Photo',
          style: TextStyle(
            color: Colors.blue.shade400,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<LocationData?> _showLocationPicker(LocationData? initial) async {
    return showDialog<LocationData>(
      context: context,
      builder: (context) => LocationPickerDialog(
        title: 'Select Location',
        initialLocation: initial,
      ),
    );
  }

  Future<void> _addStop() async {
    final loc = await _showLocationPicker(null);
    if (loc == null) return;

    final nameController = TextEditingController();
    if (!mounted) return;
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Stop Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'e.g., Sightseeing Spot'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      setState(
        () => _stops.add(
          TourStop(
            name: name,
            lat: loc.lat,
            lng: loc.lng,
            order: _stops.length,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _seatsController.dispose();
    super.dispose();
  }
}
