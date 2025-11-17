import 'package:flutter/material.dart';
import 'package:forex_journal_app/models/account.dart';
import 'package:forex_journal_app/main.dart';
import 'package:forex_journal_app/screens/account_details_screen.dart';

class AccountManagementScreen extends StatefulWidget {
  final Function(int accountId) onAccountSelected; 
  final int? activeAccountId; 
  
  const AccountManagementScreen({super.key, required this.onAccountSelected, this.activeAccountId});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  late Future<List<Account>> _accountsFuture;
  final _formKey = GlobalKey<FormState>();
  String _accountName = '';
  String _accountType = 'Real'; 
  double _initialBalance = 0.0;
  
  @override
  void initState() {
    super.initState();
    _accountsFuture = dbService.getAllAccounts();
  }
  
  void _refreshAccounts() {
    setState(() { _accountsFuture = dbService.getAllAccounts(); });
  }

  void _saveNewAccount() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newAccount = Account(name: _accountName, type: _accountType, initialBalance: _initialBalance);
      final accountId = await dbService.saveAccount(newAccount);
      widget.onAccountSelected(accountId); 
      _refreshAccounts();
      if (mounted) {
        _formKey.currentState!.reset();
        Navigator.of(context).pop(); 
      }
    }
  }

  void _showAddAccountDialog() {
    _accountType = 'Real'; 
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adaugă Cont Nou'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(decoration: const InputDecoration(labelText: 'Nume Cont'), validator: (v) => v!.isEmpty ? 'Necesar' : null, onSaved: (v) => _accountName = v!),
                  const SizedBox(height: 10),
                  TextFormField(decoration: const InputDecoration(labelText: 'Sold Inițial'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Necesar' : null, onSaved: (v) => _initialBalance = double.parse(v!)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(value: _accountType, items: ['Real', 'Demo', 'Micro'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _accountType = v!), onSaved: (v) => _accountType = v!),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anulează')),
            ElevatedButton(onPressed: _saveNewAccount, child: const Text('Salvează')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conturi de Tranzacționare'), automaticallyImplyLeading: false),
      body: FutureBuilder<List<Account>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final accounts = snapshot.data ?? [];
          
          if (accounts.isEmpty) {
            return Center(child: ElevatedButton.icon(onPressed: _showAddAccountDialog, icon: const Icon(Icons.add), label: const Text('Adaugă Primul Cont')));
          }
          
          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return FutureBuilder<double>(
                future: dbService.getCurrentBalance(account.id),
                builder: (context, snapshot) {
                  final currentBalance = snapshot.data ?? account.initialBalance;
                  final isSelected = account.id == widget.activeAccountId; 
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: account.type == 'Real' ? Colors.green.shade700 : Colors.blue.shade700,
                        child: Text(account.type.isNotEmpty ? account.type[0] : '?', style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text('${account.name} (${account.type})'),
                      subtitle: Text('Sold: \$${currentBalance.toStringAsFixed(2)}'),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => AccountDetailsScreen(
                          account: account,
                          isActive: isSelected,
                          onActivate: () { widget.onAccountSelected(account.id); },
                          onDelete: () async { await dbService.deleteAccount(account.id); if (isSelected) widget.onAccountSelected(0); _refreshAccounts(); } // Hack: send 0 or handle null in parent properly, we handled in HomeTabs to check for null
                        )));
                      },
                    ),
                  );
                }
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddAccountDialog, child: const Icon(Icons.add)),
    );
  }
}