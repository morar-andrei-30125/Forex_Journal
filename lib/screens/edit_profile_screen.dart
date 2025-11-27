import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:forex_journal_app/models/user_profile.dart';
import 'package:forex_journal_app/main.dart';
import 'package:forex_journal_app/screens/home_tabs_screen.dart';
import 'package:forex_journal_app/screens/pin_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile? existingProfile;
  final bool isFirstTime;

  const EditProfileScreen({
    super.key,
    this.existingProfile,
    this.isFirstTime = false,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _jobController;
  DateTime? _dob;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.existingProfile?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.existingProfile?.lastName ?? '');
    _jobController = TextEditingController(text: widget.existingProfile?.jobTitle ?? '');
    _dob = widget.existingProfile?.dateOfBirth;

    if (widget.existingProfile?.profileImagePath != null) {
      _imageFile = File(widget.existingProfile!.profileImagePath!);
    }
  }

  Future<void> _pickImage() async {
    try {
      MyApp.of(context)?.setFilePickerMode(true);
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _imageFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image error: $e')));
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) MyApp.of(context)?.setFilePickerMode(false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _dob = date);
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final profile = UserProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        jobTitle: _jobController.text,
        dateOfBirth: _dob,
        profileImagePath: _imageFile?.path,
      );

      await dbService.saveUserProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully!')));
        if (widget.isFirstTime) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (ctx) => const HomeTabsScreen()),
          );
        } else {
          Navigator.of(context).pop(true);
        }
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _jobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstTime ? 'Create Trader Profile' : 'Edit Profile'),
        automaticallyImplyLeading: !widget.isFirstTime,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null ? const Icon(Icons.camera_alt, size: 40) : null,
                ),
              ),
              const SizedBox(height: 10),
              const Text('Tap to change photo', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),

              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _jobController,
                decoration: const InputDecoration(labelText: 'Job / Occupation', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),

              ListTile(
                title: Text(
                  _dob == null
                      ? 'Select Date of Birth'
                      : 'DOB: ${_dob!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                tileColor: Theme.of(context).colorScheme.surfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onTap: _pickDate,
              ),
              const SizedBox(height: 30),

              if (!widget.isFirstTime)
                OutlinedButton.icon(
                  icon: const Icon(Icons.lock_reset, color: Colors.red),
                  label: const Text('Change App PIN', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const PinScreen(isSettingPin: false, isChangingPin: true),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Profile', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}