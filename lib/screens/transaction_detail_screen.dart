import 'package:flutter/material.dart';
import 'package:forex_journal_app/models/transaction.dart';
import 'package:forex_journal_app/models/strategy.dart'; 
import 'package:forex_journal_app/main.dart'; 
import 'package:forex_journal_app/screens/add_transaction_screen.dart'; 
import 'dart:io';

class TransactionDetailScreen extends StatefulWidget {
  final Transaction transaction;
  const TransactionDetailScreen({super.key, required this.transaction});
  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Transaction _currentTransaction; 

  @override
  void initState() {
    super.initState();
    _currentTransaction = widget.transaction;
  }

  Future<Strategy?> _loadStrategy(Transaction tx) async {
    await tx.strategy.load();
    return tx.strategy.value;
  }

  void _deleteTransaction() {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Șterge'), content: const Text('Sigur?'), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Nu')),
      TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () async { Navigator.pop(ctx); await dbService.deleteTransaction(_currentTransaction.id); if (mounted) { Navigator.pop(context, true); } }, child: const Text('Da')),
    ]));
  }

  void _editTransaction() async {
    final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddTransactionScreen(accountId: _currentTransaction.accountId, transactionToEdit: _currentTransaction)));
    if (result == true) {
      final updatedTx = await dbService.getTransaction(_currentTransaction.id);
      if (updatedTx != null) setState(() => _currentTransaction = updatedTx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWin = _currentTransaction.profitLossAmount >= 0;
    return Scaffold(
      appBar: AppBar(title: Text('${_currentTransaction.instrument} - Detalii'), actions: [
          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: _editTransaction),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteTransaction),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Card(color: isWin ? Colors.green.shade50 : Colors.red.shade50, child: ListTile(title: const Text('Rezultat', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${_currentTransaction.profitLossAmount.toStringAsFixed(2)} \$', style: TextStyle(fontSize: 18, color: isWin ? Colors.green.shade800 : Colors.red.shade800)), trailing: Text('${_currentTransaction.profitLossPips.toStringAsFixed(1)} PIPS'))),
            const SizedBox(height: 16),
            _buildDetailCard(title: 'Detalii', children: [
                _buildDetailRow('Instrument', _currentTransaction.instrument),
                _buildDetailRow('Notițe', _currentTransaction.comment),
                _buildDetailRow('Emoție', _currentTransaction.emotion),
                _buildDetailRow('Lot Size', _currentTransaction.lotSize.toStringAsFixed(2)),
                _buildDetailRow('Intrare', _currentTransaction.entryPrice.toString()),
                _buildDetailRow('Ieșire', _currentTransaction.exitPrice.toString()),
                _buildDetailRow('Data', _currentTransaction.entryDate.toString().substring(0, 16)),
            ]),
            const SizedBox(height: 16),
            FutureBuilder<Strategy?>(future: _loadStrategy(_currentTransaction), builder: (context, snapshot) {
                return _buildDetailCard(title: 'Strategie', children: [_buildDetailRow('Nume', snapshot.data?.name ?? 'N/A')]);
            }),
            const SizedBox(height: 24),
            if (_currentTransaction.screenshotPath.isNotEmpty && File(_currentTransaction.screenshotPath).existsSync()) Image.file(File(_currentTransaction.screenshotPath), fit: BoxFit.contain, height: 300) else const Text('Fără poză.'),
        ]),
      ),
    );
  }
  
  Widget _buildDetailCard({required String title, required List<Widget> children}) { return Card(child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const Divider(), ...children]))); }
  Widget _buildDetailRow(String label, String value) { return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Flexible(child: Text(value, textAlign: TextAlign.right))])); }
}