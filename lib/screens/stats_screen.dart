import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:forex_journal_app/models/account.dart';
import 'package:forex_journal_app/models/transaction.dart';
import 'package:forex_journal_app/main.dart'; 
import 'package:forex_journal_app/models/strategy.dart';
import 'package:forex_journal_app/screens/transaction_detail_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class StatsScreen extends StatefulWidget {
  final String accountId; 
  const StatsScreen({super.key, required this.accountId});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  String _timeFilter = 'Tot Timpul';
  Strategy? _strategyFilter; 
  
  bool _isCalendarView = false; 
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _statsFuture = _loadStatsData(); 
  }
  
  Future<Map<String, dynamic>> _loadStatsData() async {
    try {
      final account = await dbService.getAccount(widget.accountId);
      final transactions = await dbService.getAllTransactions(widget.accountId);
      final currentBalance = await dbService.getCurrentBalance(widget.accountId);
      final strategies = await dbService.getAllStrategies(); 

      return {
        'account': account,
        'transactions': transactions,
        'strategies': strategies,
        'currentBalance': currentBalance,
      };
    } catch (e) {
      return {};
    }
  }

  void _refreshData() { setState(() { _statsFuture = _loadStatsData(); }); }

  List<Transaction> _applyFilters(List<Transaction> allTransactions) {
    final now = DateTime.now();
    return allTransactions.where((tx) {
      bool matchesTime = true;
      bool matchesStrategy = true;

      if (_timeFilter == 'Luna Aceasta') {
        matchesTime = tx.entryDate.month == now.month && tx.entryDate.year == now.year;
      } else if (_timeFilter == 'Săptămâna Aceasta') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        matchesTime = tx.entryDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && 
                      tx.entryDate.isBefore(endOfWeek);
      }

      if (_strategyFilter != null) {
        matchesStrategy = tx.strategyName == _strategyFilter!.name;
      }

      return matchesTime && matchesStrategy;
    }).toList();
  }

  List<Transaction> _getTransactionsForDay(List<Transaction> allTx, DateTime day) {
    return allTx.where((tx) => isSameDay(tx.entryDate, day)).toList();
  }
  
  double _calculateDailyProfit(List<Transaction> dailyTx) => dailyTx.fold(0.0, (sum, tx) => sum + tx.profitLossAmount);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) return const Center(child: Text('Nu s-au găsit date.'));
        
        final data = snapshot.data!;
        final account = data['account'] as Account?;
        if (account == null) return const Center(child: Text('Cont inexistent.'));

        final allTransactions = data['transactions'] as List<Transaction>;
        final strategies = data['strategies'] as List<Strategy>;
        final currentBalance = data['currentBalance'] as double;

        final filteredTransactions = _applyFilters(allTransactions);
        
        return RefreshIndicator(
          onRefresh: () async => _refreshData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(value: false, label: Text('Dashboard'), icon: Icon(Icons.bar_chart)),
                      ButtonSegment<bool>(value: true, label: Text('Calendar'), icon: Icon(Icons.calendar_month)),
                    ],
                    selected: {_isCalendarView},
                    onSelectionChanged: (s) => setState(() => _isCalendarView = s.first),
                    style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact),
                  ),
                ),
                const SizedBox(height: 20),
                
                if (!_isCalendarView) 
                  _buildDashboardView(currentBalance, filteredTransactions, strategies, account.initialBalance)
                else 
                  _buildCalendarView(allTransactions),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardView(double currentBalance, List<Transaction> transactions, List<Strategy> strategies, double initialBalance) {
    final equityData = _calculateEquityCurve(transactions, initialBalance);
    final filteredProfit = transactions.fold(0.0, (sum, tx) => sum + tx.profitLossAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFiltersBar(strategies),
        const SizedBox(height: 10),
        _buildBalanceCard(currentBalance, filteredProfit, initialBalance, transactions.length),
        const SizedBox(height: 20),
        
        Text('Indicatori de Performanță (KPIs)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        // AICI ESTE FUNCȚIA NOUĂ DE KPI
        _buildKPIGrid(transactions), 
        
        const SizedBox(height: 20),
        Text('Evoluție Equity', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _buildEquityChart(equityData),
        const SizedBox(height: 20),
        Text('Istoric (${transactions.length})', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        _buildTransactionsList(transactions),
      ],
    );
  }

  // --- CALENDAR VIEW ---
  Widget _buildCalendarView(List<Transaction> allTransactions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dailyTransactions = _getTransactionsForDay(allTransactions, _selectedDay ?? DateTime.now());
    final dailyProfit = _calculateDailyProfit(dailyTransactions);

    return Column(
      children: [
        Card(
          elevation: 2, 
          child: Padding(
            padding: const EdgeInsets.all(4.0), 
            child: TableCalendar(
              firstDay: DateTime.utc(2020), 
              lastDay: DateTime.utc(2030), 
              focusedDay: _focusedDay, 
              calendarFormat: _calendarFormat, 
              rowHeight: 85,
              headerStyle: HeaderStyle(
                titleCentered: true, 
                formatButtonVisible: false, 
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black), 
                leftChevronIcon: Icon(Icons.chevron_left, color: isDark ? Colors.white : Colors.black), 
                rightChevronIcon: Icon(Icons.chevron_right, color: isDark ? Colors.white : Colors.black)
              ),
              calendarStyle: const CalendarStyle(outsideDaysVisible: false), 
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (sel, foc) => setState(() { _selectedDay = sel; _focusedDay = foc; }), 
              onPageChanged: (foc) => _focusedDay = foc,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (ctx, day, foc) => _buildCalendarCell(day, allTransactions, isDark, false),
                todayBuilder: (ctx, day, foc) => _buildCalendarCell(day, allTransactions, isDark, true),
                selectedBuilder: (ctx, day, foc) => _buildCalendarCell(day, allTransactions, isDark, false, isSelected: true),
              ),
            )
          )
        ),
        const SizedBox(height: 20),
        if (dailyTransactions.isNotEmpty) 
           Card(
             color: dailyProfit >= 0 ? (isDark?Colors.green.withOpacity(0.2):Colors.green.shade50) : (isDark?Colors.red.withOpacity(0.2):Colors.red.shade50), 
             child: Padding(
               padding: const EdgeInsets.all(16.0), 
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                 children: [
                   Text(DateFormat('d MMM').format(_selectedDay!), style: const TextStyle(fontWeight: FontWeight.bold)), 
                   Text('${dailyProfit>=0?'+':''}${dailyProfit.toStringAsFixed(2)} \$', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: dailyProfit>=0 ? Colors.green : Colors.red))
                 ]
               )
             )
           ) 
        else 
           const SizedBox.shrink(),
        _buildTransactionsList(dailyTransactions),
      ],
    );
  }

  Widget _buildCalendarCell(DateTime day, List<Transaction> allTxs, bool isDark, bool isToday, {bool isSelected = false}) {
    final txs = _getTransactionsForDay(allTxs, day);
    final profit = _calculateDailyProfit(txs);
    Color txtCol = profit > 0 ? Colors.green : (profit < 0 ? Colors.red : (isDark ? Colors.grey[400]! : Colors.grey[600]!));
    Color bgCol = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    if (isSelected) bgCol = Colors.teal.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.all(2), padding: const EdgeInsets.all(4), 
      decoration: BoxDecoration(color: bgCol, border: Border.all(color: isSelected?Colors.teal:Colors.grey.withOpacity(0.3)), borderRadius: BorderRadius.circular(6)), 
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(day.day.toString(), style: TextStyle(fontSize: 12, color: isDark?Colors.white:Colors.black)),
          const Spacer(),
          if(txs.isNotEmpty) Center(child: Text(profit==0?'\$0':'${profit.toStringAsFixed(0)}', style: TextStyle(color: txtCol, fontWeight: FontWeight.w900, fontSize: 14))),
          const Spacer(),
        ])
    );
  }

  Widget _buildFiltersBar(List<Strategy> strategies) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, 
      child: Row(
        children: [
          DropdownButton<String>(value: _timeFilter, items: ['Tot Timpul', 'Luna Aceasta', 'Săptămâna Aceasta'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => _timeFilter = val!)),
          const SizedBox(width: 20), 
          DropdownButton<Strategy?>(value: _strategyFilter, hint: const Text('Toate Strategiile'), items: [const DropdownMenuItem<Strategy?>(value: null, child: Text('Toate Strategiile')), ...strategies.map((s) => DropdownMenuItem<Strategy?>(value: s, child: Text(s.name)))], onChanged: (val) => setState(() => _strategyFilter = val)),
        ]
      )
    );
  }
  
  Widget _buildBalanceCard(double total, double filtered, double initial, int count) {
    final isProfit = filtered >= 0;
    return Card(elevation: 4, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Sold Cont', style: TextStyle(color: Colors.grey)), Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))]),
          const Divider(), const SizedBox(height: 5), const Text('Rezultat Perioadă', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text('${isProfit ? '+' : ''}${filtered.toStringAsFixed(2)} \$', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isProfit ? Colors.green : Colors.red)),
          Text('$count tranzacții', style: const TextStyle(color: Colors.grey)),
        ])));
  }

 // --- KPI WIDGET (Compact - 3 Coloane) ---
  Widget _buildKPIGrid(List<Transaction> transactions) {
    if (transactions.isEmpty) return const Text('Fără date pentru KPI.');

    int wins = 0;
    int losses = 0;
    double grossProfit = 0;
    double grossLoss = 0;
    double netProfit = 0;

    for (var tx in transactions) {
      netProfit += tx.profitLossAmount;
      if (tx.profitLossAmount >= 0) {
        wins++;
        grossProfit += tx.profitLossAmount;
      } else {
        losses++;
        grossLoss += tx.profitLossAmount.abs();
      }
    }

    final total = wins + losses;
    final winRate = total > 0 ? (wins / total) * 100 : 0.0;
    // Dacă nu ai pierderi, profit factor e maxim (99.9)
    final profitFactor = grossLoss > 0 ? (grossProfit / grossLoss) : (grossProfit > 0 ? 99.9 : 0.0);
    
    final avgWin = wins > 0 ? grossProfit / wins : 0.0;
    final avgLoss = losses > 0 ? grossLoss / losses : 0.0;
    
    return GridView.count(
      crossAxisCount: 3, // <--- SCHIMBARE: 3 Coloane
      childAspectRatio: 1.6, // <--- Le facem puțin mai pătrate/compacte
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8, // Spațiu mai mic între ele
      crossAxisSpacing: 8,
      children: [
        _buildStatCard('Win Rate', '${winRate.toStringAsFixed(1)}%', winRate > 50 ? Colors.green : Colors.orange),
        _buildStatCard('Profit Factor', profitFactor.toStringAsFixed(2), profitFactor >= 1.5 ? Colors.green : (profitFactor < 1 ? Colors.red : Colors.orange)),
        _buildStatCard('Profit Net', '\$${netProfit.toStringAsFixed(0)}', netProfit >= 0 ? Colors.green : Colors.red), // Fără zecimale pt spațiu
        _buildStatCard('Tranzacții', '$total', Colors.blue),
        _buildStatCard('Avg Win', '\$${avgWin.toStringAsFixed(0)}', Colors.green.shade700),
        _buildStatCard('Avg Loss', '-\$${avgLoss.toStringAsFixed(0)}', Colors.red.shade700),
      ],
    );
  }
  
  Widget _buildStatCard(String title, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Padding redus
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title, 
            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey : Colors.black54), // Font mai mic
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value, 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color) // Font mai mic
          )
        ]
      )
    );
  }

  Widget _buildEquityChart(List<FlSpot> spots) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (spots.length < 2) return const SizedBox(height: 100, child: Center(child: Text("Grafic indisponibil")));
    return SizedBox(height: 200, child: LineChart(LineChartData(
       gridData: const FlGridData(show: false), titlesData: const FlTitlesData(show: false), borderData: FlBorderData(show: true, border: Border.all(color: isDark?Colors.grey[800]!:Colors.grey[300]!)),
       lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: Colors.teal, barWidth: 2, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: Colors.teal.withOpacity(0.1)))]
    )));
  }

  Widget _buildTransactionsList(List<Transaction> transactions) {
    final list = List.from(transactions.reversed);
    if (list.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Nimic găsit.")));
    return ListView.builder(physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, itemCount: list.length, itemBuilder: (context, index) {
        final tx = list[index] as Transaction;
        final sName = tx.strategyName.isNotEmpty ? tx.strategyName : 'N/A';
        return ListTile(
          title: Text('${tx.instrument} (${tx.lotSize})'),
          subtitle: Text('P/L: ${tx.profitLossAmount} | $sName'),
          trailing: Text(tx.entryDate.toString().substring(0, 10)),
          onTap: () async {
             final res = await Navigator.push(context, MaterialPageRoute(builder: (ctx) => TransactionDetailScreen(transaction: tx)));
             if(res == true) _refreshData();
          },
        );
    });
  }

  List<FlSpot> _calculateEquityCurve(List<Transaction> txs, double initial) {
    if (txs.isEmpty) return [];
    txs.sort((a, b) => a.entryDate.compareTo(b.entryDate));
    double current = initial; List<FlSpot> spots = [const FlSpot(0, 0)];
    for(int i=0; i<txs.length; i++) { current += txs[i].profitLossAmount; spots.add(FlSpot((i+1).toDouble(), current - initial)); }
    return spots;
  }
}