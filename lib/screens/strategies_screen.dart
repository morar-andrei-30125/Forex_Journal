import 'package:flutter/material.dart';
import 'package:forex_journal_app/models/strategy.dart';
import 'package:forex_journal_app/main.dart'; 

class StrategiesScreen extends StatefulWidget {
  const StrategiesScreen({super.key});
  @override
  State<StrategiesScreen> createState() => _StrategiesScreenState();
}

class _StrategiesScreenState extends State<StrategiesScreen> {
  final _nCtrl = TextEditingController(); final _dCtrl = TextEditingController();
  late Future<List<Strategy>> _fut;
  
  @override void initState() { super.initState(); _fut = dbService.getAllStrategies(); }
  void _refresh() { setState(() { _fut = dbService.getAllStrategies(); }); }

  void _show(Strategy? s) {
    if(s!=null) { _nCtrl.text=s.name; _dCtrl.text=s.description; } else { _nCtrl.clear(); _dCtrl.clear(); }
    showDialog(context: context, builder: (ctx)=>AlertDialog(content: Column(mainAxisSize: MainAxisSize.min, children: [
       TextField(controller: _nCtrl, decoration: const InputDecoration(labelText: 'Nume')),
       TextField(controller: _dCtrl, decoration: const InputDecoration(labelText: 'Descriere')),
    ]), actions: [
       ElevatedButton(onPressed: () async {
          final strat = Strategy(name: _nCtrl.text, description: _dCtrl.text);
          if(s!=null) strat.id = s.id;
          await dbService.saveStrategy(strat);
          _refresh(); Navigator.pop(ctx);
       }, child: const Text('Save'))
    ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: ()=>_show(null), child: const Icon(Icons.add)),
      body: FutureBuilder<List<Strategy>>(future: _fut, builder: (ctx, snp) {
         final list = snp.data ?? [];
         return ListView.builder(itemCount: list.length, itemBuilder: (ctx, i) {
            final s = list[i];
            return ListTile(title: Text(s.name), subtitle: Text(s.description), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () async { await dbService.deleteStrategy(s.id); _refresh(); }), onTap: ()=>_show(s));
         });
      })
    );
  }
}