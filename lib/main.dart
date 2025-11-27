// fisier: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:forex_journal_app/firebase_options.dart'; 
import 'package:forex_journal_app/services/database_service.dart';
import 'package:forex_journal_app/services/auth_service.dart'; // <--- ACESTA LIPSEA
import 'package:forex_journal_app/screens/loading_screen.dart'; 
import 'package:forex_journal_app/screens/pin_screen.dart'; 
import 'package:forex_journal_app/screens/login_screen.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

late DatabaseService dbService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  dbService = DatabaseService();
  await dbService.db; 
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState? of(BuildContext context) => context.findAncestorStateOfType<MyAppState>();

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isLocked = true; 
  bool _hasPinSet = false; 
  bool _isLoading = true;
  bool _isPickingFile = false;
  ThemeMode _themeMode = ThemeMode.system;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initApp() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('user_pin');
    final isDark = prefs.getBool('is_dark_mode') ?? false;

    setState(() {
      _hasPinSet = pin != null && pin.isNotEmpty;
      if (!_hasPinSet) _isLocked = false; 
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _isLoading = false;
    });
  }

  void toggleTheme(bool isDark) async {
    setState(() { _themeMode = isDark ? ThemeMode.dark : ThemeMode.light; });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
  }

  Future<void> updatePinStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('user_pin');
    setState(() {
      _hasPinSet = pin != null && pin.isNotEmpty;
      if (!_hasPinSet) _isLocked = false; 
      _isLoading = false;
    });
  }

  void unlockApp() => setState(() => _isLocked = false);
  void setFilePickerMode(bool isActive) { _isPickingFile = isActive; }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jurnal FOREX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light), useMaterial3: true, scaffoldBackgroundColor: Colors.grey[50], appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0)),
      darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark), useMaterial3: true, scaffoldBackgroundColor: const Color(0xFF121212), appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0, backgroundColor: Color(0xFF1E1E1E))),
      themeMode: _themeMode, 
      
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges, // Acum va funcționa
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));

          if (!snapshot.hasData) return const LoginScreen();

          return _buildAppContent();
        },
      ),
    );
  }

  Widget _buildAppContent() {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Stack(
      children: [
        if (!_hasPinSet) const PinScreen(isSettingPin: true) else const LoadingScreen(),
        if (_isLocked && _hasPinSet) const Positioned.fill(child: PinScreen(isSettingPin: false)),
      ],
    );
  }
}