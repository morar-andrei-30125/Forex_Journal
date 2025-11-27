import 'package:flutter/material.dart';
import 'package:forex_journal_app/models/account.dart';
import 'package:forex_journal_app/main.dart';
import 'package:forex_journal_app/screens/account_details_screen.dart';

class AccountManagementScreen extends StatefulWidget {
  final Function(String?) onAccountSelected;
  final String? activeAccountId;

  const AccountManagementScreen({
    super.key,
    required this.onAccountSelected,
    this.activeAccountId,
  });

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
    setState(() {
      _accountsFuture = dbService.getAllAccounts();
    });
  }

  void _saveNewAccount() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newAccount = Account(
        name: _accountName,
        type: _accountType,
        initialBalance: _initialBalance,
      );

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
          title: const Text('Add New Account'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Account Name'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onSaved: (v) => _accountName = v!,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Initial Balance'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onSaved: (v) => _initialBalance = double.parse(v!),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _accountType,
                    items: ['Real', 'Demo', 'Micro'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _accountType = v!),
                    onSaved: (v) => _accountType = v!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(onPressed: _saveNewAccount, child: const Text('Save')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trading Accounts'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Account>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final accounts = snapshot.data ?? [];

          if (accounts.isEmpty) {
            return Center(
              child: ElevatedButton.icon(
                onPressed: _showAddAccountDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add First Account'),
              ),
            );
          }

          return ListView.builder(
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              return FutureBuilder<double>(
                future: dbService.getCurrentBalance(account.id),
                builder: (context, balanceSnapshot) {
                  final currentBalance = balanceSnapshot.data ?? account.initialBalance;
                  final isSelected = account.id == widget.activeAccountId;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: account.type == 'Real' ? Colors.green.shade700 : Colors.blue.shade700,
                        child: Text(
                          account.type.isNotEmpty ? account.type[0] : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text('${account.name} (${account.type})'),
                      subtitle: Text('Balance: \$${currentBalance.toStringAsFixed(2)}'),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => AccountDetailsScreen(
                              account: account,
                              isActive: isSelected,
                              onActivate: () {
                                widget.onAccountSelected(account.id);
                              },
                              onDelete: () async {
                                await dbService.deleteAccount(account.id);
                                if (isSelected) widget.onAccountSelected(null);
                                _refreshAccounts();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}