import 'package:flutter/material.dart';
import 'package:forex_journal_app/models/account.dart';
import 'package:forex_journal_app/models/transaction.dart';
import 'package:forex_journal_app/main.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';

class AccountDetailsScreen extends StatefulWidget {
  final Account account;
  final bool isActive;
  final VoidCallback onActivate;
  final VoidCallback onDelete;

  const AccountDetailsScreen({
    super.key,
    required this.account,
    required this.isActive,
    required this.onActivate,
    required this.onDelete,
  });

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAccountData();
  }

  Future<Map<String, dynamic>> _loadAccountData() async {
    try {
      final transactions = await dbService.getAllTransactions(widget.account.id);
      final currentBalance = await dbService.getCurrentBalance(widget.account.id);
      return {
        'transactions': transactions,
        'balance': currentBalance,
      };
    } catch (e) {
      return {
        'transactions': <Transaction>[],
        'balance': widget.account.initialBalance,
      };
    }
  }

  Future<void> _exportToCsv(List<Transaction> transactions) async {
    try {
      MyApp.of(context)?.setFilePickerMode(true);

      List<List<dynamic>> rows = [];
      rows.add([
        "ID", "Entry Date", "Exit Date", "Instrument", "Type",
        "Lot Size", "Entry Price", "Exit Price", "Pips",
        "Profit/Loss", "Strategy", "Emotion"
      ]);

      for (var tx in transactions) {
        rows.add([
          tx.id, tx.entryDate.toIso8601String(), tx.exitDate.toIso8601String(),
          tx.instrument, tx.comment, tx.lotSize, tx.entryPrice, tx.exitPrice,
          tx.profitLossPips, tx.profitLossAmount,
          tx.strategyName, tx.emotion
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report',
        fileName: 'Journal_${widget.account.name.replaceAll(' ', '_')}.csv',
        allowedExtensions: ['csv'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsString('\uFEFF$csvData', encoding: utf8);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to: $outputFile')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export error: $e')));
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) MyApp.of(context)?.setFilePickerMode(false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete "${widget.account.name}"?\nAll transactions will be lost!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete();
              Navigator.pop(context);
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? {'transactions': <Transaction>[], 'balance': widget.account.initialBalance};

          final transactions = data['transactions'] as List<Transaction>;
          final balance = data['balance'] as double;

          final totalTrades = transactions.length;
          final totalProfit = transactions.fold(0.0, (sum, t) => sum + t.profitLossAmount);
          final wins = transactions.where((t) => t.profitLossAmount >= 0).length;
          final winRate = totalTrades > 0 ? (wins / totalTrades * 100) : 0.0;
          final historyList = List.from(transactions.reversed);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: widget.account.type == 'Real' ? Colors.green.shade800 : Colors.blue.shade800,
                    child: Text(
                      widget.account.type.isNotEmpty ? widget.account.type[0] : '?',
                      style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(child: Text(widget.account.type, style: TextStyle(fontSize: 16, color: Colors.grey[600]))),
                const SizedBox(height: 20),

                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('Current Balance', style: TextStyle(fontSize: 14)),
                        Text(
                          '\$${balance.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniStat('Net Profit', '\$${totalProfit.toStringAsFixed(2)}', totalProfit >= 0 ? Colors.green : Colors.red, isDark),
                            _buildMiniStat('Win Rate', '${winRate.toStringAsFixed(1)}%', Colors.orange, isDark),
                            _buildMiniStat('Trades', '$totalTrades', null, isDark),
                          ],
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                if (!widget.isActive)
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onActivate();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.account.name} activated!')));
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('ACTIVATE ACCOUNT'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 10),
                        Text('Active Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _exportToCsv(transactions),
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _confirmDelete,
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        label: const Text('Delete', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                const Text(
                  "Recent History",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                if (historyList.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("No transactions yet."),
                  ))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: historyList.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = historyList[index] as Transaction;
                      final isProfit = tx.profitLossAmount >= 0;

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                        leading: Icon(
                          isProfit ? Icons.arrow_circle_up : Icons.arrow_circle_down,
                          color: isProfit ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          tx.instrument,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${tx.entryDate.toString().substring(0, 10)} • ${tx.comment}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        trailing: Text(
                          '${isProfit ? '+' : ''}${tx.profitLossAmount.toStringAsFixed(2)} \$',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isProfit ? Colors.green : Colors.red,
                            fontSize: 15,
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color? color, bool isDark) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? (isDark ? Colors.white : Colors.black))),
      ],
    );
  }
}