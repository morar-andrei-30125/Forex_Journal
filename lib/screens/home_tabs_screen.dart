import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:forex_journal_app/screens/add_transaction_screen.dart';
import 'package:forex_journal_app/screens/stats_screen.dart';
import 'package:forex_journal_app/screens/strategies_screen.dart';
import 'package:forex_journal_app/screens/account_management_screen.dart';
import 'package:forex_journal_app/models/account.dart';
import 'package:forex_journal_app/screens/profile_screen.dart';
import 'package:forex_journal_app/screens/position_calculator_screen.dart';
import 'package:forex_journal_app/screens/pip_calculator_screen.dart';
import 'package:forex_journal_app/screens/teaching_screen.dart'; 
import 'package:forex_journal_app/main.dart'; 

class HomeTabsScreen extends StatefulWidget {
  const HomeTabsScreen({super.key});

  @override
  State<HomeTabsScreen> createState() => _HomeTabsScreenState();
}

class _HomeTabsScreenState extends State<HomeTabsScreen> {
  // Ordinea: 0:Stats, 1:Add, 2:Edu, 3:Strategies, 4:Profile
  int _selectedIndex = 0;
  
  Account? _currentAccount; 
  String? _activeAccountId; 

  @override
  void initState() {
    super.initState();
    _checkInitialAccount();
  }

  void _checkInitialAccount() async {
    final accounts = await dbService.getAllAccounts();
    if (accounts.isNotEmpty) {
      _setActiveAccount(accounts.first.id);
    } else {
      _setActiveAccount(null); 
    }
  }

  void _setActiveAccount(String? accountId) async {
    if (accountId == null) {
      setState(() {
        _activeAccountId = null;
        _currentAccount = null;
      });
      // Nu schimbăm _selectedIndex, lăsăm utilizatorul pe tab-ul curent, dar gol
      return;
    }

    final account = await dbService.getAccount(accountId);
    if (account != null) {
      setState(() {
        _activeAccountId = accountId;
        _currentAccount = account; 
        _selectedIndex = 0; // Cont activat, mergi la Statistici
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCurrentScreen() {
    // Dacă nu avem cont selectat, ARĂTĂM LISTA DE CONTURI
    if (_activeAccountId == null) {
      // Excepție: Strategiile, Educația și Profilul pot fi văzute (sau sunt goale)
      if (_selectedIndex == 2) return const TeachingScreen();
      if (_selectedIndex == 3) return const StrategiesScreen();
      if (_selectedIndex == 4) return const ProfileScreen();
      
      // Altfel, forțăm ecranul de conturi
      return AccountManagementScreen(onAccountSelected: _setActiveAccount, activeAccountId: null);
    }

    // Navigarea normală (când ai cont selectat)
    switch (_selectedIndex) {
      case 0: return StatsScreen(accountId: _activeAccountId!);
      case 1: return AddTransactionScreen(accountId: _activeAccountId!);
      case 2: return const TeachingScreen();
      case 3: return const StrategiesScreen();
      case 4: return const ProfileScreen();
      default: return const Center(child: Text('Unknown Screen'));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Protecție: dacă nu avem cont și suntem pe tab-uri care cer cont
    if (_currentAccount == null && _selectedIndex != 2 && _selectedIndex != 3 && _selectedIndex != 4) {
       // Când nu ai cont, singura acțiune logică pe Stats/Add e să vezi lista de conturi
       return Scaffold(
        appBar: AppBar(
          title: const Text('Select Account'),
          actions: [
             IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: () async => await FirebaseAuth.instance.signOut()),
          ],
        ),
        body: AccountManagementScreen(onAccountSelected: _setActiveAccount, activeAccountId: null),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentAccount != null ? _currentAccount!.name : 'Select Account'), 
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_currentAccount != null) ...[
            // 1. BUTON CONTURI (PORTOFEL) - NOUA FUNCȚIONALITATE
            IconButton(
              icon: const Icon(Icons.account_balance_wallet), 
              tooltip: 'View Accounts', 
              // Deschide ecranul de management conturi ca un pop-up/ecran nou
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => AccountManagementScreen(onAccountSelected: _setActiveAccount, activeAccountId: _activeAccountId),
                ));
              },
            ),

            // 2. MENIU UNELTE
            PopupMenuButton<String>(
              icon: const Icon(Icons.grid_view), 
              tooltip: 'Tools Menu',
              onSelected: (val) async {
                 if (val == 'risk') {
                    final bal = await dbService.getCurrentBalance(_activeAccountId!);
                    if(context.mounted) Navigator.push(context, MaterialPageRoute(builder: (ctx)=>PositionCalculatorScreen(currentBalance: bal)));
                 } else if (val == 'pip') {
                    Navigator.push(context, MaterialPageRoute(builder: (ctx)=>const PipCalculatorScreen()));
                 }
              },
              itemBuilder: (ctx) => [
                 const PopupMenuItem(value: 'risk', child: ListTile(leading: Icon(Icons.pie_chart), title: Text('Position Calculator'))),
                 const PopupMenuItem(value: 'pip', child: ListTile(leading: Icon(Icons.attach_money), title: Text('Pip Calculator'))),
              ]
            ),
          ],
          
          // Buton LOGOUT
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Logout',
            onPressed: () async {
              setState(() { _activeAccountId = null; _currentAccount = null; });
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      
      body: _buildCurrentScreen(),
      
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Add'),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Learn'),
        BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), label: 'Strategies'), // MODIFICAT: Acum e pe index 3
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed, 
    );
  }
}