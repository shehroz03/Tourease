import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';
import 'map_location_picker.dart';

class LocationPickerDialog extends StatefulWidget {
  final LocationData? initialLocation;
  final String title;

  const LocationPickerDialog({
    super.key,
    this.initialLocation,
    this.title = 'Select Location',
  });

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final _addressController = TextEditingController();
  LocationData? _selectedLocation;
  bool _isSearching = false;
  bool _isGettingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _addressController.text = widget.initialLocation!.address;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final location = await Navigator.push<LocationData>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLocationPicker(
          initialLocation: _selectedLocation,
          title: widget.title,
        ),
      ),
    );

    if (location != null) {
      setState(() {
        _selectedLocation = location;
        _addressController.text = location.address;
      });
    }
  }

  Future<void> _searchAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter an address')));
      return;
    }

    setState(() => _isSearching = true);

    try {
      final location = await LocationService.geocodeAddress(address);
      if (location != null) {
        setState(() {
          _selectedLocation = location;
          _addressController.text = location.address;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Address not found')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isGettingCurrentLocation = true);

    try {
      final location = await LocationService.getCurrentLocation();
      if (location != null) {
        setState(() {
          _selectedLocation = location;
          _addressController.text = location.address;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingCurrentLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: 'Address',
              hintText: 'Enter address or tap "Pick on Map"',
              prefixIcon: const Icon(Icons.location_on),
              suffixIcon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchAddress,
                    ),
            ),
            onSubmitted: (_) => _searchAddress(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isGettingCurrentLocation
                      ? null
                      : _useCurrentLocation,
                  icon: _isGettingCurrentLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: const Text('Current'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openMapPicker,
                  icon: const Icon(Icons.map),
                  label: const Text('Map'),
                ),
              ),
            ],
          ),
          if (_selectedLocation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Location:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedLocation!.address,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lat: ${_selectedLocation!.lat.toStringAsFixed(6)}, Lng: ${_selectedLocation!.lng.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedLocation != null
              ? () => Navigator.pop(context, _selectedLocation)
              : null,
          child: const Text('Select'),
        ),
      ],
    );
  }
}
