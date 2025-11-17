import 'package:flutter/material.dart';

class PipCalculatorScreen extends StatefulWidget {
  const PipCalculatorScreen({super.key});
  @override
  State<PipCalculatorScreen> createState() => _PipCalculatorScreenState();
}

class _PipCalculatorScreenState extends State<PipCalculatorScreen> {
  final _lotSizeController = TextEditingController(text: '1.00');
  final _priceController = TextEditingController(); 
  PairInfo? _selectedPair; double _pipValue = 0.0;

  final List<PairInfo> pairs = [
    PairInfo('EUR/USD', 'fix', null), PairInfo('GBP/USD', 'fix', null), PairInfo('AUD/USD', 'fix', null), PairInfo('NZD/USD', 'fix', null),
    PairInfo('USD/CAD', 'divide_self', 'USD/CAD'), PairInfo('USD/CHF', 'divide_self', 'USD/CHF'), PairInfo('USD/JPY', 'divide_jpy', 'USD/JPY'), 
    PairInfo('EUR/JPY', 'divide_jpy', 'USD/JPY'), PairInfo('GBP/JPY', 'divide_jpy', 'USD/JPY'), PairInfo('AUD/JPY', 'divide_jpy', 'USD/JPY'),
    PairInfo('CAD/JPY', 'divide_jpy', 'USD/JPY'), PairInfo('CHF/JPY', 'divide_jpy', 'USD/JPY'), PairInfo('NZD/JPY', 'divide_jpy', 'USD/JPY'),
    PairInfo('EUR/GBP', 'multiply_base', 'GBP/USD'), PairInfo('EUR/AUD', 'multiply_base', 'AUD/USD'), PairInfo('GBP/AUD', 'multiply_base', 'AUD/USD'),
    PairInfo('EUR/CAD', 'divide_base', 'USD/CAD'), PairInfo('GBP/CAD', 'divide_base', 'USD/CAD'), PairInfo('EUR/CHF', 'divide_base', 'USD/CHF'),
    PairInfo('XAU/USD (Gold)', 'fix', null), PairInfo('XAG/USD (Silver)', 'silver', null),
  ];

  @override
  void initState() { super.initState(); _selectedPair = pairs.first; _calculatePipValue(); }

  void _calculatePipValue() {
    if (_selectedPair == null) return;
    final lots = double.tryParse(_lotSizeController.text) ?? 0.0;
    final rate = double.tryParse(_priceController.text) ?? 0.0;
    double val = 0.0;
    switch (_selectedPair!.type) {
      case 'fix': val = lots * 10.0; break;
      case 'silver': val = lots * 50.0; break;
      case 'divide_self': if (rate > 0) val = (10.0 / rate) * lots; break;
      case 'divide_jpy': if (rate > 0) val = (1000.0 / rate) * lots; break;
      case 'multiply_base': if (rate > 0) val = 10.0 * rate * lots; break;
      case 'divide_base': if (rate > 0) val = (10.0 / rate) * lots; break;
    }
    setState(() { _pipValue = val; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Calculator Valoare Pip'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Card(elevation: 4, child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Configurare Pereche", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 15),
                    DropdownButtonFormField<PairInfo>(value: _selectedPair, isExpanded: true, decoration: const InputDecoration(labelText: 'Tipul Perechii', border: OutlineInputBorder()), items: pairs.map((pair) => DropdownMenuItem(value: pair, child: Text(pair.name))).toList(), onChanged: (val) { setState(() { _selectedPair = val; _priceController.clear(); _calculatePipValue(); }); }),
                    const SizedBox(height: 20),
                    TextField(controller: _lotSizeController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Lot Size (Volum)', border: OutlineInputBorder()), onChanged: (_) => _calculatePipValue()),
                    if (_selectedPair != null && _selectedPair!.requiredRatePair != null) Padding(padding: const EdgeInsets.only(top: 20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Curs (${_selectedPair!.requiredRatePair})", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.tealAccent : Colors.teal.shade800)), const SizedBox(height: 10), TextField(controller: _priceController, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Preț ${_selectedPair!.requiredRatePair}', hintText: 'ex: 1.0850', border: const OutlineInputBorder(), filled: true, fillColor: isDark ? Colors.grey.shade800 : Colors.teal.shade50), onChanged: (_) => _calculatePipValue())])),
                ]))),
            const SizedBox(height: 30),
            if (_pipValue > 0) Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: isDark ? Colors.indigo.withOpacity(0.2) : Colors.indigo.shade50, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.indigo, width: 2), boxShadow: isDark ? [] : [BoxShadow(color: Colors.indigo.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]), child: Column(children: [Text('VALOARE 1 PIP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.indigo.shade100 : Colors.black54)), const SizedBox(height: 10), Text('\$${_pipValue.toStringAsFixed(2)}', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: isDark ? Colors.indigoAccent : Colors.indigo)), const Divider(), Text('Pentru ${_lotSizeController.text} loturi pe ${_selectedPair?.name}', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey : Colors.black87), textAlign: TextAlign.center)]))
            else if (_selectedPair?.requiredRatePair != null && _priceController.text.isEmpty) Center(child: Padding(padding: const EdgeInsets.all(10.0), child: Text("Introdu prețul curent pentru a calcula.", style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade700)))),
            const SizedBox(height: 20),
            if (_selectedPair?.type == 'multiply_base') Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isDark ? Colors.amber.withOpacity(0.15) : Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade700.withOpacity(0.5))), child: Row(children: [const Icon(Icons.info, color: Colors.orange), const SizedBox(width: 10), Expanded(child: Text("La Cross Pairs (ex: EURGBP), valoarea pip-ului depinde de cursul monedei secundare față de USD.", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.black87)))]))
          ])),
    );
  }
}
class PairInfo { final String name; final String type; final String? requiredRatePair; PairInfo(this.name, this.type, this.requiredRatePair); }