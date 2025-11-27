// fisier: lib/screens/position_calculator_screen.dart

import 'package:flutter/material.dart';

// Clasa ajutătoare pentru perechi
class PairInfo {
  final String name;
  final String type; 
  final String? requiredRatePair; 

  const PairInfo(this.name, this.type, this.requiredRatePair);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PairInfo &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class PositionCalculatorScreen extends StatefulWidget {
  final double currentBalance; 

  const PositionCalculatorScreen({super.key, required this.currentBalance});

  @override
  State<PositionCalculatorScreen> createState() => _PositionCalculatorScreenState();
}

class _PositionCalculatorScreenState extends State<PositionCalculatorScreen> {
  final _balanceController = TextEditingController();
  final _riskPercentController = TextEditingController(text: '1.0');
  final _stopLossController = TextEditingController(text: '20');
  final _priceController = TextEditingController(); 

  final List<PairInfo> pairs = const [
    PairInfo('EUR/USD', 'fix', null),
    PairInfo('GBP/USD', 'fix', null),
    PairInfo('AUD/USD', 'fix', null),
    PairInfo('NZD/USD', 'fix', null),
    PairInfo('USD/CAD', 'divide_self', 'USD/CAD'),
    PairInfo('USD/CHF', 'divide_self', 'USD/CHF'),
    PairInfo('USD/JPY', 'divide_jpy', 'USD/JPY'), 
    PairInfo('EUR/JPY', 'divide_jpy', 'USD/JPY'),
    PairInfo('GBP/JPY', 'divide_jpy', 'USD/JPY'),
    PairInfo('AUD/JPY', 'divide_jpy', 'USD/JPY'),
    PairInfo('CAD/JPY', 'divide_jpy', 'USD/JPY'),
    PairInfo('CHF/JPY', 'divide_jpy', 'USD/JPY'),
    PairInfo('NZD/JPY', 'divide_jpy', 'USD/JPY'),
    PairInfo('EUR/GBP', 'multiply_base', 'GBP/USD'), 
    PairInfo('EUR/AUD', 'multiply_base', 'AUD/USD'),
    PairInfo('GBP/AUD', 'multiply_base', 'AUD/USD'),
    PairInfo('EUR/CAD', 'divide_base', 'USD/CAD'), 
    PairInfo('GBP/CAD', 'divide_base', 'USD/CAD'),
    PairInfo('EUR/CHF', 'divide_base', 'USD/CHF'),
    PairInfo('XAU/USD (Gold)', 'fix', null),
  ];

  late PairInfo _selectedPair;
  double _resultLots = 0.0;
  double _riskAmount = 0.0;
  double _calculatedPipValue = 0.0;

  @override
  void initState() {
    super.initState();
    _balanceController.text = widget.currentBalance.toStringAsFixed(2);
    _selectedPair = pairs.first;
    _calculatePositionSize();
  }

  void _calculatePositionSize() {
    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    final riskPercent = double.tryParse(_riskPercentController.text) ?? 0.0;
    final stopLoss = double.tryParse(_stopLossController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (balance <= 0 || riskPercent <= 0 || stopLoss <= 0) {
      setState(() { _resultLots = 0.0; _riskAmount = 0.0; });
      return;
    }

    double riskAmount = balance * (riskPercent / 100);
    double pipValue = 10.0;

    switch (_selectedPair.type) {
      case 'fix': pipValue = 10.0; break;
      case 'divide_self': if (price > 0) pipValue = 10.0 / price; break;
      case 'divide_jpy': if (price > 0) pipValue = 1000.0 / price; break;
      case 'multiply_base': if (price > 0) pipValue = 10.0 * price; break;
      case 'divide_base': if (price > 0) pipValue = 10.0 / price; break;
    }

    double lots = 0.0;
    if (pipValue > 0) {
      lots = riskAmount / (stopLoss * pipValue);
    }

    setState(() {
      _riskAmount = riskAmount;
      _calculatedPipValue = pipValue;
      _resultLots = lots;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator Poziție'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("1. Pereche & Cont", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<PairInfo>(
                      value: _selectedPair,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: pairs.map((pair) {
                        return DropdownMenuItem(value: pair, child: Text(pair.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedPair = val;
                            _priceController.clear();
                            _calculatePositionSize();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: _balanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sold Cont (\$)', border: OutlineInputBorder(), suffixIcon: Icon(Icons.account_balance)), onChanged: (_) => _calculatePositionSize()),
                    const SizedBox(height: 20),
                    const Text("2. Management Risc", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(children: [
                       Expanded(child: TextField(controller: _riskPercentController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Risc (%)', border: OutlineInputBorder(), suffixText: '%'), onChanged: (_) => _calculatePositionSize())),
                       const SizedBox(width: 16),
                       Expanded(child: TextField(controller: _stopLossController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stop Loss (Pips)', border: OutlineInputBorder()), onChanged: (_) => _calculatePositionSize())),
                    ]),
                    if (_selectedPair.requiredRatePair != null) 
                      Padding(padding: const EdgeInsets.only(top: 20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                             Text("3. Curs (${_selectedPair.requiredRatePair})", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.tealAccent : Colors.teal.shade800)),
                             const SizedBox(height: 10),
                             TextField(controller: _priceController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Preț ${_selectedPair.requiredRatePair}', hintText: 'ex: 1.0850', border: const OutlineInputBorder(), filled: true, fillColor: isDark ? Colors.grey.shade800 : Colors.teal.shade50), onChanged: (_) => _calculatePositionSize()),
                          ])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_resultLots > 0)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: isDark ? Colors.teal.withOpacity(0.15) : Colors.teal.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.teal, width: 2), boxShadow: isDark ? [] : [BoxShadow(color: Colors.teal.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]),
                child: Column(children: [
                   Text('DIMENSIUNE POZIȚIE (LOTS)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.teal.shade100 : Colors.black54)),
                   const SizedBox(height: 5),
                   Text(_resultLots.toStringAsFixed(2), style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: isDark ? Colors.tealAccent : Colors.teal)),
                   const Divider(),
                   Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        Column(children: [Text('Risc (\$)', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.black87)), Text('\$${_riskAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red))]),
                        Column(children: [Text('Valoare Pip', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.black87)), Text('\$${_calculatedPipValue.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))]),
                      ])
                ]),
              )
            else if (_selectedPair.requiredRatePair != null && _priceController.text.isEmpty)
               Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text("Introdu prețul curent.", style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade700))))
          ],
        ),
      ),
    );
  }
}