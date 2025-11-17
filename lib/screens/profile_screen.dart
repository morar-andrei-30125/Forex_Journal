import 'package:flutter/material.dart';
import 'package:forex_journal_app/models/user_profile.dart';
import 'package:forex_journal_app/main.dart';
import 'package:forex_journal_app/screens/edit_profile_screen.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<UserProfile?>? _profileFuture;
  @override
  void initState() { super.initState(); _refreshProfile(); }
  void _refreshProfile() { setState(() { _profileFuture = dbService.getUserProfile(); }); }

  void _confirmResetApp(BuildContext context) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Resetare'), content: const Text('Ștergi TOT?'), actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Nu')),
          TextButton(onPressed: () async { Navigator.pop(ctx); await dbService.wipeAllData(); runApp(const MyApp()); }, child: const Text('DA', style: TextStyle(color: Colors.red))),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = MyApp.of(context)?.isDarkMode ?? false;
    return Scaffold(
      body: FutureBuilder<UserProfile?>(future: _profileFuture, builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final profile = snapshot.data;
          if (profile == null) return const Center(child: Text("Profil lipsă"));
          
          return SingleChildScrollView(child: Column(children: [
                const SizedBox(height: 40),
                CircleAvatar(radius: 80, backgroundImage: profile.profileImagePath != null ? FileImage(File(profile.profileImagePath!)) : null, child: profile.profileImagePath == null ? const Icon(Icons.person, size: 80) : null),
                const SizedBox(height: 20),
                Text('${profile.firstName} ${profile.lastName}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                ListTile(leading: const Icon(Icons.work), title: const Text("Ocupație"), subtitle: Text(profile.jobTitle)),
                SwitchListTile(title: const Text("Dark Mode"), value: isDarkMode, onChanged: (val) { MyApp.of(context)?.toggleTheme(val); setState((){}); }),
                const SizedBox(height: 30),
                ElevatedButton.icon(icon: const Icon(Icons.edit), label: const Text("Editează Profil / PIN"), onPressed: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (ctx) => EditProfileScreen(existingProfile: profile))); if (result == true) _refreshProfile(); }),
                const SizedBox(height: 40),
                TextButton.icon(icon: const Icon(Icons.delete_forever, color: Colors.red), label: const Text("RESET APLICAȚIE", style: TextStyle(color: Colors.red)), onPressed: () => _confirmResetApp(context)),
              ]));
        }),
    );
  }
}