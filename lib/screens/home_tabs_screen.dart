import 'package:flutter/material.dart';
import 'package:forex_journal_app/screens/add_transaction_screen.dart';
import 'package:forex_journal_app/screens/stats_screen.dart';
import 'package:forex_journal_app/screens/strategies_screen.dart';
import 'package:forex_journal_app/screens/account_management_screen.dart';
import 'package:forex_journal_app/models/account.dart';
import 'package:forex_journal_app/screens/profile_screen.dart';
import 'package:forex_journal_app/screens/risk_calculator_screen.dart';
import 'package:forex_journal_app/screens/pip_calculator_screen.dart';
import 'package:forex_journal_app/main.dart'; 

class HomeTabsScreen extends StatefulWidget {
  const HomeTabsScreen({super.key});
  @override
  State<HomeTabsScreen> createState() => _HomeTabsScreenState();
}

class _HomeTabsScreenState extends State<HomeTabsScreen> {
  int _selectedIndex = 0; Account? _currentAccount; int? _activeAccountId; 

  @override
  void initState() { super.initState(); _checkInitialAccount(); }

  void _checkInitialAccount() async {
    final accounts = await dbService.getAllAccounts();
    if (accounts.isNotEmpty) _setActiveAccount(accounts.first.id); else _setActiveAccount(null);
  }

  void _setActiveAccount(int? accountId) async {
    if (accountId == null) { setState(() { _activeAccountId = null; _currentAccount = null; _selectedIndex = 3; }); return; }
    final account = await dbService.getAccount(accountId);
    if (account != null) setState(() { _activeAccountId = accountId; _currentAccount = account; _selectedIndex = 0; });
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  Widget _buildCurrentScreen() {
    if (_activeAccountId == null) {
      if (_selectedIndex == 2) return const StrategiesScreen();
      if (_selectedIndex == 4) return const ProfileScreen();
      return AccountManagementScreen(onAccountSelected: _setActiveAccount, activeAccountId: null);
    }
    switch (_selectedIndex) {
      case 0: return StatsScreen(accountId: _activeAccountId!);
      case 1: return AddTransactionScreen(accountId: _activeAccountId!);
      case 2: return const StrategiesScreen();
      case 3: return AccountManagementScreen(onAccountSelected: _setActiveAccount, activeAccountId: _activeAccountId);
      case 4: return const ProfileScreen();
      default: return const Center(child: Text('Ecran necunoscut'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentAccount == null && _selectedIndex != 3 && _selectedIndex != 2 && _selectedIndex != 4) {
       return Scaffold(appBar: AppBar(title: const Text('Jurnal Forex')), body: AccountManagementScreen(onAccountSelected: _setActiveAccount, activeAccountId: null));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentAccount != null ? 'Jurnal Forex - ${_currentAccount!.name}' : 'Selectare Cont'), 
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_currentAccount != null) ...[
            IconButton(icon: const Icon(Icons.calculate_outlined), tooltip: 'Calculator Risc', onPressed: () async { final balance = await dbService.getCurrentBalance(_activeAccountId!); if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (ctx) => RiskCalculatorScreen(currentBalance: balance))); }),
            IconButton(icon: const Icon(Icons.attach_money), tooltip: 'Calculator Pip', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => const PipCalculatorScreen()))),
            IconButton(icon: const Icon(Icons.account_balance_wallet), tooltip: 'Schimbă Contul', onPressed: () => _onItemTapped(3)),
          ]
        ],
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistici'), BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Adaugă'), BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), label: 'Strategii'), BottomNavigationBarItem(icon: Icon(Icons.account_box), label: 'Conturi'), BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil')],
        currentIndex: _selectedIndex, selectedItemColor: Colors.teal, unselectedItemColor: Colors.grey, onTap: _onItemTapped, type: BottomNavigationBarType.fixed, 
      ),
    );
  }
}