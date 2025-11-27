import 'package:flutter/material.dart';
import 'package:forex_journal_app/models/user_profile.dart';
import 'package:forex_journal_app/main.dart';
import 'package:forex_journal_app/screens/edit_profile_screen.dart';
import 'package:forex_journal_app/screens/admin_panel_screen.dart'; // NOU: Import Admin
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'; // Pt logout

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<UserProfile?>? _profileFuture;
  bool _isAdmin = false; // Stare pentru butonul secret

  @override
  void initState() {
    super.initState();
    _refreshProfile();
    _checkAdmin();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = dbService.getUserProfile();
    });
  }

  // Verifică dacă suntem Admin
  void _checkAdmin() async {
    final adminStatus = await dbService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = adminStatus;
      });
    }
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }

  void _confirmResetApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resetare'),
        content: const Text('Ștergi TOT?'),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Nu')),
          TextButton(onPressed: () async { 
            Navigator.pop(ctx); 
            await dbService.wipeAllData(); 
            runApp(const MyApp()); 
          }, child: const Text('DA', style: TextStyle(color: Colors.red))),
        ]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MyApp.of(context)?.isDarkMode ?? false;

    return Scaffold(
      body: FutureBuilder<UserProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final profile = snapshot.data;
          // Fallback vizual dacă nu e profil
          final displayName = profile != null ? '${profile.firstName} ${profile.lastName}' : 'Utilizator';
          final displayJob = profile?.jobTitle ?? 'Trader';

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 80, 
                  backgroundImage: (profile?.profileImagePath != null) ? FileImage(File(profile!.profileImagePath!)) : null,
                  child: (profile?.profileImagePath == null) ? const Icon(Icons.person, size: 80) : null
                ),
                const SizedBox(height: 20),
                Text(displayName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text(displayJob, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                
                const SizedBox(height: 30),
                
                // --- BUTONUL DE ADMIN (Apare doar la tine) ---
                if (_isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)
                      ),
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text("PANOU ADMINISTRATOR"),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AdminPanelScreen()));
                      },
                    ),
                  ),

                if (profile != null) ...[
                   // Detalii doar dacă avem profil
                   ListTile(title: const Text("Vârstă"), subtitle: Text(profile.dateOfBirth != null ? '${_calculateAge(profile.dateOfBirth!)} ani' : '-'), leading: const Icon(Icons.cake)),
                   ListTile(title: const Text("Ocupație"), subtitle: Text(profile.jobTitle), leading: const Icon(Icons.work)),
                ],

                SwitchListTile(
                  title: const Text("Dark Mode"), 
                  value: isDarkMode, 
                  onChanged: (val) { MyApp.of(context)?.toggleTheme(val); setState((){}); },
                  secondary: const Icon(Icons.dark_mode),
                ),

                const SizedBox(height: 30),
                
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit), 
                  label: const Text("Editează Profil / PIN"), 
                  onPressed: () async { 
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (ctx) => EditProfileScreen(existingProfile: profile))); 
                    if (result == true) _refreshProfile(); 
                  }
                ),
                
                const SizedBox(height: 40),
                TextButton.icon(
                  icon: const Icon(Icons.delete_forever, color: Colors.red), 
                  label: const Text("RESET APLICAȚIE", style: TextStyle(color: Colors.red)), 
                  onPressed: () => _confirmResetApp(context)
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}