import 'package:flutter/material.dart';
import 'package:forex_journal_app/models/strategy.dart';
import 'package:forex_journal_app/main.dart'; 

class StrategiesScreen extends StatefulWidget {
  const StrategiesScreen({super.key});
  @override
  State<StrategiesScreen> createState() => _StrategiesScreenState();
}

class _StrategiesScreenState extends State<StrategiesScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  late Future<List<Strategy>> _strategiesFuture;

  @override
  void initState() {
    super.initState();
    _refreshStrategies();
  }
  void _refreshStrategies() { setState(() { _strategiesFuture = dbService.getAllStrategies(); }); }

  void _showStrategyDialog({Strategy? strategyToEdit}) {
    if (strategyToEdit != null) { _nameController.text = strategyToEdit.name; _descController.text = strategyToEdit.description ?? ''; } 
    else { _nameController.clear(); _descController.clear(); }

    showDialog(context: context, builder: (ctx) {
        return AlertDialog(title: Text(strategyToEdit == null ? 'Adaugă' : 'Editează'), content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nume')),
              TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Descriere')),
            ]), actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')),
            ElevatedButton(onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  final strategy = Strategy(name: _nameController.text, description: _descController.text);
                  if (strategyToEdit != null) strategy.id = strategyToEdit.id;
                  await dbService.saveStrategy(strategy);
                  _refreshStrategies();
                  if (mounted) Navigator.pop(ctx);
                }
              }, child: const Text('Salvează')),
          ]);
      });
  }

  void _deleteStrategy(Strategy s) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Șterge'), content: const Text('Sigur?'), actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Nu')),
          TextButton(onPressed: () async { Navigator.pop(ctx); await dbService.deleteStrategy(s.id); _refreshStrategies(); }, child: const Text('Da', style: TextStyle(color: Colors.red))),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: () => _showStrategyDialog(), child: const Icon(Icons.add)),
      body: FutureBuilder<List<Strategy>>(future: _strategiesFuture, builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data ?? [];
          if (list.isEmpty) return const Center(child: Text('Nicio strategie.'));
          return ListView.builder(padding: const EdgeInsets.all(10), itemCount: list.length, itemBuilder: (context, index) {
              final s = list[index];
              return Card(child: ListTile(
                  title: Text(s.name), subtitle: Text(s.description ?? ''),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showStrategyDialog(strategyToEdit: s)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteStrategy(s)),
                  ]),
                ));
            });
        }),
    );
  }
}