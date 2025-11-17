// fisier: lib/main.dart

import 'package:flutter/material.dart';
import 'package:forex_journal_app/services/database_service.dart';
import 'package:forex_journal_app/screens/loading_screen.dart'; 
import 'package:forex_journal_app/screens/pin_screen.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// Variabila globală pentru baza de date
late DatabaseService dbService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inițializăm baza de date înainte de pornirea aplicației
  dbService = DatabaseService();
  await dbService.db; 
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // Acces public la starea aplicației
  static MyAppState? of(BuildContext context) => context.findAncestorStateOfType<MyAppState>();

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // --- STĂRI SECURITATE ---
  bool _isLocked = true; 
  bool _hasPinSet = false; 
  bool _isLoading = true;
  bool _isPickingFile = false;
  
  Timer? _lockTimer;
  static const int _lockGracePeriodSeconds = 30;

  // --- STARE TEMĂ ---
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
    _lockTimer?.cancel();
    super.dispose();
  }

  // --- LOGICA DE BLOCARE AUTOMATĂ ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_hasPinSet && !_isPickingFile) {
        _startLockTimer();
      }
    } else if (state == AppLifecycleState.resumed) {
      _cancelLockTimer();
    }
  }

  void _startLockTimer() {
    _cancelLockTimer(); 
    _lockTimer = Timer(const Duration(seconds: _lockGracePeriodSeconds), () {
      if (mounted) {
        setState(() {
          _isLocked = true; 
        });
      }
    });
  }

  void _cancelLockTimer() {
    if (_lockTimer != null) {
      _lockTimer!.cancel();
      _lockTimer = null;
    }
  }

  // --- INIȚIALIZARE ---
  Future<void> _initApp() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('user_pin');
    final isDark = prefs.getBool('is_dark_mode') ?? false;

    setState(() {
      _hasPinSet = pin != null && pin.isNotEmpty;
      if (!_hasPinSet) {
        _isLocked = false; 
      }
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _isLoading = false;
    });
  }

  // --- METODE PUBLICE ---

  void toggleTheme(bool isDark) async {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
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

  void unlockApp() {
    setState(() {
      _isLocked = false;
    });
  }

  void setFilePickerMode(bool isActive) {
    _isPickingFile = isActive;
    if (isActive) _cancelLockTimer();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jurnal FOREX',
      debugShowCheckedModeBanner: false,
      
      // --- TEMA LUMINOSĂ ---
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      
      // --- TEMA ÎNTUNECATĂ (SIMPLIFICATĂ FĂRĂ CARDTHEME) ---
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          centerTitle: true, 
          elevation: 0, 
          backgroundColor: Color(0xFF1E1E1E)
        ),
        // Am scos CardTheme pentru a evita eroarea. Material 3 se va ocupa automat de culori.
      ),
      
      themeMode: _themeMode, 

      builder: (context, child) {
        if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        return Stack(
          children: [
            if (!_hasPinSet) 
               const PinScreen(isSettingPin: true)
            else 
               child ?? const LoadingScreen(),

            if (_isLocked && _hasPinSet)
              const Positioned.fill(
                child: PinScreen(isSettingPin: false),
              ),
          ],
        );
      },
      home: const LoadingScreen(), 
    );
  }
}