import 'package:flutter/material.dart';
import 'package:forex_journal_app/main.dart';
import 'package:forex_journal_app/screens/home_tabs_screen.dart';
import 'package:forex_journal_app/screens/edit_profile_screen.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  Future<bool> _hasProfile() async {
    final profile = await dbService.getUserProfile();
    return profile != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final hasProfile = snapshot.data ?? false;

        if (hasProfile) {
          return const HomeTabsScreen();
        } else {
          return const EditProfileScreen(isFirstTime: true);
        }
      },
    );
  }
}