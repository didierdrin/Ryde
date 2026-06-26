import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ryde_rw/models/user.dart';
import 'package:ryde_rw/service/api_service.dart';
import 'package:ryde_rw/service/image_upload_service.dart';
import 'package:ryde_rw/service/local_storage_service.dart';
import 'package:ryde_rw/shared/shared_states.dart';
import 'package:ryde_rw/theme/colors.dart';
import 'package:ryde_rw/widgets/trip_list_avatar.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  final _licenseDateController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleRegController = TextEditingController();

  String? _profilePictureUrl;
  String? _licenseDocumentUrl;
  String? _vehicleImageUrl;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _licenseDateController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleRegController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final base = await ApiService.getProfile();
      final user = User.fromApiJson(base);
      _nameController.text = user.name;
      _phoneController.text = user.phoneNumber;
      _profilePictureUrl = user.profilePictureUrl;

      if (user.isDriver) {
        final res = await ApiService.getDriverProfile();
        final d = (res['driver'] as Map?)?.cast<String, dynamic>() ?? {};
        _licenseController.text = d['licenseNumber']?.toString() ?? '';
        _addressController.text = d['address']?.toString() ?? '';
        _dobController.text = _fmtDate(d['dateOfBirth']);
        _licenseDateController.text = _fmtDate(d['licenseIssuedDate']);
        _experienceController.text = d['yearsExperience']?.toString() ?? '';
        _bioController.text = d['bio']?.toString() ?? '';
        _licenseDocumentUrl = d['licenseDocumentUrl']?.toString();
        final vehicle = d['vehicle'] as Map<String, dynamic>?;
        if (vehicle != null) {
          _vehicleMakeController.text = vehicle['make']?.toString() ?? '';
          _vehicleModelController.text = vehicle['model']?.toString() ?? '';
          _vehicleRegController.text = vehicle['registrationNumber']?.toString() ?? '';
          _vehicleImageUrl = vehicle['imageUrl']?.toString();
        }
      } else if (user.isPassenger) {
        final res = await ApiService.getPassengerProfile();
        final p = (res['passenger'] as Map?)?.cast<String, dynamic>() ?? {};
        _dobController.text = _fmtDate(p['dateOfBirth']);
        _emergencyNameController.text = p['emergencyContactName']?.toString() ?? '';
        _emergencyPhoneController.text = p['emergencyContactPhone']?.toString() ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtDate(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  Future<void> _pickImage(void Function(String url) onUrl) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    final url = await ImageUploadService.uploadImage(File(picked.path), 'profiles');
    if (!url.startsWith('data:') && !url.startsWith('http')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed')));
      }
      return;
    }
    setState(() => onUrl(url));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final user = ref.read(userProvider)!;
      await ApiService.updateProfile({
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        if (_profilePictureUrl != null) 'profilePictureUrl': _profilePictureUrl,
      });

      if (user.isDriver) {
        await ApiService.updateDriverProfile({
          'licenseNumber': _licenseController.text.trim(),
          'address': _addressController.text.trim(),
          if (_dobController.text.isNotEmpty) 'dateOfBirth': _dobController.text.trim(),
          if (_licenseDateController.text.isNotEmpty) 'licenseIssuedDate': _licenseDateController.text.trim(),
          if (_experienceController.text.isNotEmpty) 'yearsExperience': int.tryParse(_experienceController.text.trim()),
          if (_bioController.text.isNotEmpty) 'bio': _bioController.text.trim(),
          if (_licenseDocumentUrl != null) 'licenseDocumentUrl': _licenseDocumentUrl,
          if (_profilePictureUrl != null) 'profilePictureUrl': _profilePictureUrl,
        });
        if (_vehicleMakeController.text.isNotEmpty) {
          try {
            await ApiService.updateVehicle({
              'make': _vehicleMakeController.text.trim(),
              'model': _vehicleModelController.text.trim(),
              if (_vehicleImageUrl != null) 'imageUrl': _vehicleImageUrl,
            });
          } catch (_) {}
        }
      } else if (user.isPassenger) {
        await ApiService.updatePassengerProfile({
          if (_dobController.text.isNotEmpty) 'dateOfBirth': _dobController.text.trim(),
          if (_emergencyNameController.text.isNotEmpty) 'emergencyContactName': _emergencyNameController.text.trim(),
          if (_emergencyPhoneController.text.isNotEmpty) 'emergencyContactPhone': _emergencyPhoneController.text.trim(),
          if (_profilePictureUrl != null) 'profilePictureUrl': _profilePictureUrl,
        });
      }

      final refreshed = await ApiService.getProfile();
      final updatedUser = User.fromApiJson(refreshed);
      await LocalStorage.setUser(updatedUser);
      ref.read(userProvider.notifier).setUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () => _pickImage((url) => _profilePictureUrl = url),
                    child: Stack(
                      children: [
                        TripListAvatar(imageUrl: _profilePictureUrl, radius: 50),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: primaryColor,
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(child: Text(user.userType, style: TextStyle(color: Colors.grey[600]))),
                const SizedBox(height: 24),
                _field('Full name', _nameController),
                _field('Phone', _phoneController, keyboard: TextInputType.phone),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                ),
                if (user.isDriver) ...[
                  const Divider(height: 32),
                  Text('Driver details', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _field('License number', _licenseController),
                  _field('Address', _addressController),
                  _field('Date of birth (YYYY-MM-DD)', _dobController),
                  _field('License issued (YYYY-MM-DD)', _licenseDateController),
                  _field('Years of experience', _experienceController, keyboard: TextInputType.number),
                  _field('Short bio', _bioController, maxLines: 3),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage((url) => _licenseDocumentUrl = url),
                    icon: const Icon(Icons.badge_outlined),
                    label: Text(_licenseDocumentUrl == null ? 'Upload license (image/PDF)' : 'License document uploaded'),
                  ),
                  const Divider(height: 32),
                  Text('Vehicle', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _field('Make', _vehicleMakeController),
                  _field('Model', _vehicleModelController),
                  _field('Registration', _vehicleRegController),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage((url) => _vehicleImageUrl = url),
                    icon: const Icon(Icons.directions_car),
                    label: Text(_vehicleImageUrl == null ? 'Upload car photo' : 'Car photo uploaded'),
                  ),
                  if (_vehicleImageUrl != null) ...[
                    const SizedBox(height: 8),
                    Center(child: TripListAvatar(imageUrl: _vehicleImageUrl, fallbackIcon: Icons.directions_car, radius: 40)),
                  ],
                ],
                if (user.isPassenger) ...[
                  const Divider(height: 32),
                  Text('Passenger details', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _field('Date of birth (YYYY-MM-DD)', _dobController),
                  _field('Emergency contact name', _emergencyNameController),
                  _field('Emergency contact phone', _emergencyPhoneController, keyboard: TextInputType.phone),
                ],
              ],
            ),
    );
  }

  Widget _field(String label, TextEditingController controller, {TextInputType? keyboard, int maxLines = 1, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: readOnly,
          fillColor: readOnly ? Colors.grey.shade100 : null,
        ),
      ),
    );
  }
}
