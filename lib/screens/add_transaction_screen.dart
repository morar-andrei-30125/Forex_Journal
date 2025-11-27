import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forex_journal_app/models/transaction.dart';
import 'package:forex_journal_app/models/strategy.dart';
import 'package:forex_journal_app/main.dart';

class AddTransactionScreen extends StatefulWidget {
  final String accountId;
  final Transaction? transactionToEdit;

  const AddTransactionScreen({
    super.key,
    required this.accountId,
    this.transactionToEdit,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  final _lotSizeController = TextEditingController();
  final _entryPriceController = TextEditingController();
  final _exitPriceController = TextEditingController();
  final _plAmountController = TextEditingController();
  final _plPipsController = TextEditingController();
  final _commentController = TextEditingController();
  final _swapController = TextEditingController();

  String? _selectedInstrument;
  bool isBuy = true;
  String? selectedStrategyName;
  Strategy? selectedStrategy;
  DateTime? entryDateTime;
  DateTime? exitDateTime;
  String selectedEmotion = 'Neutral';

  final List<String> emotions = ['Calm', 'Confident', 'Nervous', 'Fearful', 'Greedy', 'Bored'];
  List<Strategy> availableStrategies = [];

  final List<String> _pairsList = [
    'EURUSD', 'GBPUSD', 'USDJPY', 'USDCHF', 'USDCAD', 'AUDUSD', 'NZDUSD',
    'EURJPY', 'GBPJPY', 'AUDJPY', 'CADJPY', 'CHFJPY', 'NZDJPY',
    'EURGBP', 'GBPAUD', 'GBPCAD', 'GBPCHF', 'GBPNZD',
    'EURAUD', 'EURCAD', 'EURCHF', 'EURNZD',
    'AUDCAD', 'AUDCHF', 'AUDNZD', 'CADCHF', 'NZDCAD', 'NZDCHF',
    'XAUUSD', 'XAGUSD', 'USOIL', 'UKOIL',
    'US30', 'NAS100', 'SPX500', 'GER30', 'UK100', 'BTCUSD', 'ETHUSD'
  ];

  @override
  void initState() {
    super.initState();
    _initAllData();
  }

  Future<void> _initAllData() async {
    try {
      await _loadStrategies();
      _initControllers();
      _setupListeners();
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _initControllers() {
    final tx = widget.transactionToEdit;

    if (tx != null) {
      _selectedInstrument = tx.instrument;
      if (!_pairsList.contains(_selectedInstrument)) {
        _pairsList.add(_selectedInstrument!);
        _pairsList.sort();
      }
      isBuy = tx.comment == 'BUY';
      entryDateTime = tx.entryDate;
      exitDateTime = tx.exitDate;
      selectedEmotion = tx.emotion;
      _commentController.text = tx.comment;
      _swapController.text = tx.swap.toString();
    }

    _lotSizeController.text = tx?.lotSize.toString() ?? '';
    _entryPriceController.text = tx?.entryPrice.toString() ?? '';
    _exitPriceController.text = tx?.exitPrice.toString() ?? '';
    _plAmountController.text = tx?.profitLossAmount.toString() ?? '';
    _plPipsController.text = tx?.profitLossPips.toString() ?? '';
  }

  void _setupListeners() {
    _lotSizeController.addListener(_calculateAutoStats);
    _entryPriceController.addListener(_calculateAutoStats);
    _exitPriceController.addListener(_calculateAutoStats);
    _swapController.addListener(_calculateAutoStats);
  }

  void _calculateAutoStats() {
    final entry = double.tryParse(_entryPriceController.text) ?? 0.0;
    final exit = double.tryParse(_exitPriceController.text) ?? 0.0;
    final lots = double.tryParse(_lotSizeController.text) ?? 0.0;
    final swap = double.tryParse(_swapController.text) ?? 0.0;
    final instrument = _selectedInstrument?.toUpperCase() ?? '';

    if (entry == 0 || exit == 0 || instrument.isEmpty) return;

    double priceDiff = isBuy ? (exit - entry) : (entry - exit);
    double pipMultiplier = 10000;
    if (instrument.contains('JPY')) pipMultiplier = 100;
    else if (instrument.contains('XAU') || instrument.contains('GOLD') || instrument.contains('US30')) pipMultiplier = 10;

    double pips = priceDiff * pipMultiplier;
    double grossProfit = 0.0;

    if (instrument.endsWith('USD')) {
      grossProfit = priceDiff * 100000 * lots;
      if (instrument.contains('XAU')) grossProfit = priceDiff * 100 * lots;
    } else if (instrument.contains('JPY')) {
      grossProfit = (priceDiff * 100000 * lots) / exit;
    } else {
      grossProfit = priceDiff * 100000 * lots;
      if (instrument.startsWith('USD')) grossProfit /= exit;
    }

    double netProfit = grossProfit + swap;

    String newPips = pips.toStringAsFixed(1);
    String newProfit = netProfit.toStringAsFixed(2);

    if (_plPipsController.text != newPips) _plPipsController.text = newPips;
    _plAmountController.text = newProfit;
  }

  @override
  void dispose() {
    _lotSizeController.dispose();
    _entryPriceController.dispose();
    _exitPriceController.dispose();
    _plAmountController.dispose();
    _plPipsController.dispose();
    _commentController.dispose();
    _swapController.dispose();
    super.dispose();
  }

  Future<void> _loadStrategies() async {
    var strategies = await dbService.getAllStrategies();
    if (strategies.isEmpty) {
      await dbService.saveStrategy(Strategy(name: 'No Strategy', description: 'Standard'));
      strategies = await dbService.getAllStrategies();
    }
    if (mounted) {
      setState(() {
        availableStrategies = strategies;
        if (widget.transactionToEdit != null) {
          final oldName = widget.transactionToEdit!.strategyName;
          try {
            selectedStrategy = strategies.firstWhere((s) => s.name == oldName);
            selectedStrategyName = selectedStrategy?.name;
          } catch (e) {
            if (strategies.isNotEmpty) {
              selectedStrategy = strategies.first;
              selectedStrategyName = strategies.first.name;
            }
          }
        } else {
          if (strategies.isNotEmpty) {
            selectedStrategyName = strategies.first.name;
            selectedStrategy = strategies.first;
          }
        }
      });
    }
  }

  Future<DateTime?> _pickDateTime() async {
    final initial = entryDateTime ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (entryDateTime == null || exitDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select Date/Time')));
        return;
      }
      if (selectedStrategy == null || _selectedInstrument == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete all fields')));
        return;
      }

      setState(() => _isLoading = true);

      try {
        final profitLossAmount = double.tryParse(_plAmountController.text) ?? 0.0;
        final swapAmount = double.tryParse(_swapController.text) ?? 0.0;

        final transactionToSave = Transaction(
          accountId: widget.accountId,
          entryDate: entryDateTime!,
          exitDate: exitDateTime!,
          instrument: _selectedInstrument!,
          entryPrice: double.tryParse(_entryPriceController.text) ?? 0.0,
          exitPrice: double.tryParse(_exitPriceController.text) ?? 0.0,
          lotSize: double.tryParse(_lotSizeController.text) ?? 0.0,
          profitLossAmount: profitLossAmount,
          profitLossPips: double.tryParse(_plPipsController.text) ?? 0.0,
          comment: _commentController.text.isEmpty ? (isBuy ? 'BUY' : 'SELL') : _commentController.text,
          emotion: selectedEmotion,
          strategyName: selectedStrategy!.name,
          strategyId: selectedStrategy!.id,
          swap: swapAmount,
        );

        if (widget.transactionToEdit != null) transactionToSave.id = widget.transactionToEdit!.id;

        await dbService.saveTransaction(transactionToSave);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.transactionToEdit != null ? 'Updated!' : 'Saved!')),
          );
          if (widget.transactionToEdit != null) Navigator.of(context).pop(true); else { _resetForm(); }
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState!.reset();
      _lotSizeController.clear();
      _entryPriceController.clear();
      _exitPriceController.clear();
      _plAmountController.clear();
      _plPipsController.clear();
      _commentController.clear();
      _swapController.clear();
      entryDateTime = null;
      exitDateTime = null;
      isBuy = true;
      selectedEmotion = 'Neutral';
      if (availableStrategies.isNotEmpty) {
        selectedStrategyName = availableStrategies.first.name;
        selectedStrategy = availableStrategies.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transactionToEdit != null;
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: isEditing ? AppBar(title: const Text('Edit Transaction'), backgroundColor: Theme.of(context).colorScheme.inversePrimary) : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Instrument', border: OutlineInputBorder(), prefixIcon: Icon(Icons.currency_exchange)),
                value: _selectedInstrument,
                hint: const Text("Select"),
                items: _pairsList.map((pair) => DropdownMenuItem(value: pair, child: Text(pair))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedInstrument = val;
                    _calculateAutoStats();
                  });
                },
                validator: (value) => value == null ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: RadioListTile<bool>(title: const Text('Buy'), value: true, groupValue: isBuy, onChanged: (v) { setState(() { isBuy = v!; }); _calculateAutoStats(); })),
                Expanded(child: RadioListTile<bool>(title: const Text('Sell'), value: false, groupValue: isBuy, onChanged: (v) { setState(() { isBuy = v!; }); _calculateAutoStats(); })),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextFormField(controller: _lotSizeController, decoration: const InputDecoration(labelText: 'Lot Size', border: OutlineInputBorder()), keyboardType: TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _plPipsController, decoration: const InputDecoration(labelText: 'Pips (Auto)', border: OutlineInputBorder(), filled: true), keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextFormField(controller: _entryPriceController, decoration: const InputDecoration(labelText: 'Entry', border: OutlineInputBorder()), keyboardType: TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 10),
                Expanded(child: TextFormField(controller: _exitPriceController, decoration: const InputDecoration(labelText: 'Exit', border: OutlineInputBorder()), keyboardType: TextInputType.numberWithOptions(decimal: true))),
              ]),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(flex: 2, child: TextFormField(controller: _plAmountController, decoration: const InputDecoration(labelText: 'Net Profit (w/ Swap)', border: OutlineInputBorder(), filled: true, suffixIcon: Icon(Icons.attach_money)), keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true))),
                  const SizedBox(width: 10),
                  Expanded(flex: 1, child: TextFormField(controller: _swapController, decoration: const InputDecoration(labelText: 'Swap \$', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true))),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Emotion', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(spacing: 8.0, children: emotions.map((e) => ChoiceChip(label: Text(e), selected: selectedEmotion == e, onSelected: (s) => setState(() => selectedEmotion = e))).toList()),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Strategy', border: OutlineInputBorder()), value: selectedStrategyName, items: availableStrategies.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))).toList(), onChanged: (val) { setState(() { selectedStrategyName = val; selectedStrategy = availableStrategies.firstWhere((s) => s.name == val); }); }),
              const SizedBox(height: 20),
              TextFormField(controller: _commentController, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              ListTile(title: Text(entryDateTime == null ? 'Entry Date' : 'Entry: ${entryDateTime.toString().split('.')[0]}'), trailing: const Icon(Icons.calendar_today), onTap: () async { final d = await _pickDateTime(); if (d != null) setState(() => entryDateTime = d); }),
              ListTile(title: Text(exitDateTime == null ? 'Exit Date' : 'Exit: ${exitDateTime.toString().split('.')[0]}'), trailing: const Icon(Icons.calendar_today), onTap: () async { final d = await _pickDateTime(); if (d != null) setState(() => exitDateTime = d); }),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _saveTransaction, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)), child: Text(widget.transactionToEdit != null ? 'Update' : 'Save')),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}