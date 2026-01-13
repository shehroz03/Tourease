// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart' as app_auth;
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../theme/themed_background.dart';
import '../../models/user_model.dart';
import '../../widgets/document_preview.dart';

class EditAgencyProfileScreen extends StatefulWidget {
  const EditAgencyProfileScreen({super.key});

  @override
  State<EditAgencyProfileScreen> createState() =>
      _EditAgencyProfileScreenState();
}

class _EditAgencyProfileScreenState extends State<EditAgencyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _agencyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _officeAddressController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _licenseNumController = TextEditingController();
  final _cnicNumController = TextEditingController();
  final _experienceController = TextEditingController();
  final _websiteController = TextEditingController();
  final _destinationsController = TextEditingController();

  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();

  final _imagePicker = ImagePicker();

  XFile? _logoFile;
  XFile? _cnicFrontFile;
  XFile? _cnicBackFile;
  XFile? _licenseFile;

  List<String> _specializedDestinations = [];
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<app_auth.AuthProvider>().user;
    if (user != null) {
      _agencyNameController.text = user.name;
      _descriptionController.text = user.description ?? '';
      _cityController.text = user.city ?? '';
      _countryController.text = user.country ?? '';
      _phoneController.text = user.phone ?? '';
      _whatsappController.text = user.whatsapp ?? '';
      _officeAddressController.text = user.address ?? '';
      _ownerNameController.text = user.ownerName ?? '';
      _licenseNumController.text = user.businessLicenseNumber ?? '';
      _cnicNumController.text = user.cnicNumber ?? '';
      _experienceController.text = user.yearsOfExperience?.toString() ?? '';
      _websiteController.text = user.websiteUrl ?? '';
      _facebookController.text = user.facebookUrl ?? '';
      _instagramController.text = user.instagramUrl ?? '';
      _tiktokController.text = user.tiktokUrl ?? '';
      _specializedDestinations = List.from(user.specializedDestinations);
    }
  }

  @override
  void dispose() {
    _agencyNameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _officeAddressController.dispose();
    _ownerNameController.dispose();
    _licenseNumController.dispose();
    _cnicNumController.dispose();
    _experienceController.dispose();
    _websiteController.dispose();
    _destinationsController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required String type}) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: type == 'logo' ? 512 : 1024,
        maxHeight: type == 'logo' ? 512 : 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (type == 'logo') _logoFile = image;
          if (type == 'cnicFront') _cnicFrontFile = image;
          if (type == 'cnicBack') _cnicBackFile = image;
          if (type == 'license') _licenseFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadDoc(XFile? file, String prefix, String userId) async {
    if (file == null) return null;
    final fileName =
        '${prefix}_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await CloudinaryService.uploadXFile(
      file,
      fileName: fileName,
      folder: 'agency_docs',
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // For editing, we don't strictly require re-uploading docs if they exist,
    // but the form just checks files. `user` has existing URLs.

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<app_auth.AuthProvider>();
      final user = authProvider.user;
      if (user == null) return;

      setState(() => _isUploading = true);

      String? logoUrl;
      String? cnicFrontUrl;
      String? cnicBackUrl;
      String? licenseUrl;

      // Only upload if new file selected
      if (_logoFile != null ||
          _cnicFrontFile != null ||
          _cnicBackFile != null ||
          _licenseFile != null) {
        try {
          if (_logoFile != null)
            logoUrl = await _uploadDoc(_logoFile, 'logo', user.id);
          if (_cnicFrontFile != null)
            cnicFrontUrl = await _uploadDoc(_cnicFrontFile, 'cnic_f', user.id);
          if (_cnicBackFile != null)
            cnicBackUrl = await _uploadDoc(_cnicBackFile, 'cnic_b', user.id);
          if (_licenseFile != null)
            licenseUrl = await _uploadDoc(_licenseFile, 'license', user.id);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload failed: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isLoading = false;
            _isUploading = false;
          });
          return;
        }
      }
      setState(() => _isUploading = false);

      final authService = AuthService();
      final updateData = <String, dynamic>{
        'name': _agencyNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
        'phone': _phoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'address': _officeAddressController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'businessLicenseNumber': _licenseNumController.text.trim(),
        'cnicNumber': _cnicNumController.text.trim(),
        'yearsOfExperience':
            int.tryParse(_experienceController.text.trim()) ?? 0,
        'specializedDestinations': _specializedDestinations,
        'websiteUrl': _websiteController.text.trim(),
        'facebookUrl': _facebookController.text.trim(),
        'instagramUrl': _instagramController.text.trim(),
        'tiktokUrl': _tiktokController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If we edited critical fields, should we reset verification?
      // User said: "After admin approval, agency dashboard... If verified==false...".
      // Usually changing license number requires re-verification.
      // Let's reset verified status if they changed license number or Owner Name or CNIC?
      // For now, I'll keep it simple: just update. Admin can revoke if they see changes.
      // Or safer: set verified = false if critical fields changed.
      // But the requirement didn't explicitly ask for auto-unverify on edit.
      // But `AgencyRegistrationScreen` sets `pending`.
      // I'll leave it as just update for now unless they were 'rejected'.
      if (user.status == VerificationStatus.rejected) {
        updateData['status'] = VerificationStatus.pending.name;
        updateData['rejectionReason'] = null;
      }

      if (logoUrl != null) updateData['photoUrl'] = logoUrl;
      if (cnicFrontUrl != null) updateData['cnicFrontUrl'] = cnicFrontUrl;
      if (cnicBackUrl != null) updateData['cnicBackUrl'] = cnicBackUrl;
      if (licenseUrl != null) updateData['businessLicenseUrl'] = licenseUrl;

      await authService.updateUser(user.id, updateData);
      await authProvider.refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addDestination() {
    final destination = _destinationsController.text.trim();
    if (destination.isNotEmpty &&
        !_specializedDestinations.contains(destination)) {
      setState(() {
        _specializedDestinations.add(destination);
        _destinationsController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<app_auth.AuthProvider>().user;
    if (user == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: ThemedBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
          ),
          child: Column(
            children: [
              _buildLogoHeader(user),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Basic Information'),
                      _buildTextField(
                        controller: _agencyNameController,
                        label: 'Agency Name',
                        icon: Icons.business,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'About Agency',
                        icon: Icons.info_outline,
                        maxLines: 3,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _cityController,
                              label: 'City',
                              icon: Icons.location_city,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _countryController,
                              label: 'Country',
                              icon: Icons.public,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),

                      _buildSectionTitle('Contact Details'),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      _buildTextField(
                        controller: _whatsappController,
                        label: 'WhatsApp',
                        icon: Icons.chat,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      _buildTextField(
                        controller: _officeAddressController,
                        label: 'Address',
                        icon: Icons.map,
                        maxLines: 2,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),

                      _buildSectionTitle('Verification Info'),
                      _buildTextField(
                        controller: _ownerNameController,
                        label: 'Owner Name',
                        icon: Icons.person,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      _buildTextField(
                        controller: _licenseNumController,
                        label: 'License #',
                        icon: Icons.card_membership,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      _buildTextField(
                        controller: _cnicNumController,
                        label: 'CNIC',
                        icon: Icons.credit_card,
                      ),
                      _buildTextField(
                        controller: _experienceController,
                        label: 'Experience (Years)',
                        icon: Icons.history,
                        keyboardType: TextInputType.number,
                      ),

                      _buildDestinationsSection(),

                      _buildSectionTitle('Socials'),
                      _buildTextField(
                        controller: _websiteController,
                        label: 'Website',
                        icon: Icons.language,
                      ),
                      _buildTextField(
                        controller: _facebookController,
                        label: 'Facebook',
                        icon: Icons.facebook,
                      ),
                      _buildTextField(
                        controller: _instagramController,
                        label: 'Instagram',
                        icon: Icons.camera_alt,
                      ),
                      _buildTextField(
                        controller: _tiktokController,
                        label: 'TikTok',
                        icon: Icons.music_note,
                      ),

                      _buildSectionTitle('Documents (Tap to change)'),
                      _buildDocPicker(
                        label: 'Business License',
                        file: _licenseFile,
                        url: user.businessLicenseUrl,
                        type: 'license',
                        icon: Icons.business_center,
                      ),
                      _buildDocPicker(
                        label: 'CNIC Front',
                        file: _cnicFrontFile,
                        url: user.cnicFrontUrl,
                        type: 'cnicFront',
                        icon: Icons.assignment_ind,
                      ),
                      _buildDocPicker(
                        label: 'CNIC Back',
                        file: _cnicBackFile,
                        url: user.cnicBackUrl,
                        type: 'cnicBack',
                        icon: Icons.assignment_ind,
                      ),

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isLoading || _isUploading)
                              ? null
                              : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoHeader(UserModel user) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: ClipOval(
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.white,
                    child: (_logoFile == null && user.photoUrl == null)
                        ? const Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.grey,
                          )
                        : DocumentPreview(
                            imageUrl: user.photoUrl,
                            file: _logoFile,
                            height: 100,
                            placeholderIcon: Icons.add_a_photo,
                          ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _pickImage(type: 'logo'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Container(
            height: 2,
            width: 40,
            color: Theme.of(context).primaryColor,
            margin: const EdgeInsets.only(top: 4),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Specialized Destinations',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _destinationsController,
                decoration: InputDecoration(
                  hintText: 'e.g. Hunza',
                  prefixIcon: const Icon(Icons.place),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _addDestination(),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _addDestination,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _specializedDestinations.map((dest) {
            return Chip(
              label: Text(dest),
              onDeleted: () =>
                  setState(() => _specializedDestinations.remove(dest)),
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.1),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDocPicker({
    required String label,
    required XFile? file,
    String? url,
    required String type,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _pickImage(type: type),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DocumentPreview(
                  file: file,
                  imageUrl: url,
                  height: 50,
                  placeholderIcon: icon,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      file != null
                          ? 'New file selected'
                          : (url != null ? 'Uploaded' : 'Tap to upload'),
                      style: TextStyle(
                        color: (file != null || url != null)
                            ? Colors.green
                            : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
