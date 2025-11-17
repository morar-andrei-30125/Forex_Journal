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
  const EditProfileScreen({super.key, this.existingProfile, this.isFirstTime = false});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstName, _lastName, _job;
  DateTime? _dob; File? _imageFile;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.existingProfile?.firstName ?? '');
    _lastName = TextEditingController(text: widget.existingProfile?.lastName ?? '');
    _job = TextEditingController(text: widget.existingProfile?.jobTitle ?? '');
    _dob = widget.existingProfile?.dateOfBirth;
    if (widget.existingProfile?.profileImagePath != null) _imageFile = File(widget.existingProfile!.profileImagePath!);
  }

  Future<void> _pickImage() async {
    try { MyApp.of(context)?.setFilePickerMode(true);
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) setState(() => _imageFile = File(result.files.single.path!));
    } finally { await Future.delayed(const Duration(milliseconds: 500)); if (mounted) MyApp.of(context)?.setFilePickerMode(false); }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final profile = UserProfile(firstName: _firstName.text, lastName: _lastName.text, jobTitle: _job.text, dateOfBirth: _dob, profileImagePath: _imageFile?.path);
      await dbService.saveUserProfile(profile);
      if (mounted) {
        if (widget.isFirstTime) Navigator.pushReplacement(context, MaterialPageRoute(builder: (ctx) => const HomeTabsScreen()));
        else Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isFirstTime ? 'Profil Nou' : 'Editează')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(key: _formKey, child: Column(children: [
              GestureDetector(onTap: _pickImage, child: CircleAvatar(radius: 60, backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null, child: _imageFile == null ? const Icon(Icons.camera_alt) : null)),
              const SizedBox(height: 20),
              TextFormField(controller: _firstName, decoration: const InputDecoration(labelText: 'Prenume'), validator: (v) => v!.isEmpty ? 'x' : null),
              TextFormField(controller: _lastName, decoration: const InputDecoration(labelText: 'Nume'), validator: (v) => v!.isEmpty ? 'x' : null),
              TextFormField(controller: _job, decoration: const InputDecoration(labelText: 'Job')),
              if (!widget.isFirstTime) OutlinedButton.icon(icon: const Icon(Icons.lock_reset), label: const Text('Schimbă PIN'), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const PinScreen(isChangingPin: true)))),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _saveProfile, child: const Text('Salvează')),
          ]))),
    );
  }
}