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
  final int accountId;
  const StatsScreen({super.key, required this.accountId});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<Map<String, dynamic>> _statsFuture;
  String _timeFilter = 'Tot Timpul'; Strategy? _strategyFilter; 
  bool _isCalendarView = false; 
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now(); DateTime? _selectedDay;
  
  @override
  void initState() { super.initState(); _selectedDay = _focusedDay; _statsFuture = _loadStatsData(); }
  void _refreshData() { setState(() { _statsFuture = _loadStatsData(); }); }

  Future<Map<String, dynamic>> _loadStatsData() async {
    final account = await dbService.getAccount(widget.accountId);
    final transactions = await dbService.getAllTransactions(widget.accountId);
    final currentBalance = await dbService.getCurrentBalance(widget.accountId);
    final strategies = await dbService.getAllStrategies(); 
    return { 'account': account, 'transactions': transactions, 'strategies': strategies, 'currentBalance': currentBalance };
  }

  List<Transaction> _applyFilters(List<Transaction> allTransactions) {
    final now = DateTime.now();
    return allTransactions.where((tx) {
      bool matchesTime = true; bool matchesStrategy = true;
      if (_timeFilter == 'Luna Aceasta') matchesTime = tx.entryDate.month == now.month && tx.entryDate.year == now.year;
      else if (_timeFilter == 'Săptămâna Aceasta') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        matchesTime = tx.entryDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && tx.entryDate.isBefore(endOfWeek);
      }
      if (_strategyFilter != null) matchesStrategy = tx.strategy.value?.name == _strategyFilter!.name;
      return matchesTime && matchesStrategy;
    }).toList();
  }

  List<Transaction> _getTransactionsForDay(List<Transaction> allTx, DateTime day) => allTx.where((tx) => isSameDay(tx.entryDate, day)).toList();
  double _calculateDailyProfit(List<Transaction> dailyTx) => dailyTx.fold(0.0, (sum, tx) => sum + tx.profitLossAmount);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(future: _statsFuture, builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final account = snapshot.data!['account'] as Account?;
        final allTransactions = snapshot.data!['transactions'] as List<Transaction>;
        final strategies = snapshot.data!['strategies'] as List<Strategy>;
        final currentBalance = snapshot.data!['currentBalance'] as double;

        if (account == null) return const Center(child: Text('Cont indisponibil.'));
        final filteredTransactions = _applyFilters(allTransactions);
        
        return RefreshIndicator(onRefresh: () async => _refreshData(), child: SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: SegmentedButton<bool>(segments: const [ButtonSegment<bool>(value: false, label: Text('Dashboard'), icon: Icon(Icons.bar_chart)), ButtonSegment<bool>(value: true, label: Text('Calendar'), icon: Icon(Icons.calendar_month))], selected: {_isCalendarView}, onSelectionChanged: (s) => setState(() => _isCalendarView = s.first), style: ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap, visualDensity: VisualDensity.compact))),
                const SizedBox(height: 20),
                if (!_isCalendarView) _buildDashboardView(currentBalance, filteredTransactions, strategies, account.initialBalance)
                else _buildCalendarView(allTransactions),
              ])));
      });
  }

  Widget _buildDashboardView(double currentBalance, List<Transaction> transactions, List<Strategy> strategies, double initialBalance) {
    final equityData = _calculateEquityCurve(transactions, initialBalance);
    final filteredProfit = transactions.fold(0.0, (sum, tx) => sum + tx.profitLossAmount);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildFiltersBar(strategies), const SizedBox(height: 10),
        _buildBalanceCard(currentBalance, filteredProfit, initialBalance, transactions.length), const SizedBox(height: 20),
        Text('Indicatori de Performanță (KPIs)', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 10),
        _buildKPIGrid(transactions), const SizedBox(height: 20),
        Text('Evoluție Equity', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 10),
        _buildEquityChart(equityData), const SizedBox(height: 20),
        Text('Istoric (${transactions.length})', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 10),
        _buildTransactionsList(transactions),
      ]);
  }

  Widget _buildCalendarView(List<Transaction> allTransactions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dailyTransactions = _getTransactionsForDay(allTransactions, _selectedDay ?? DateTime.now());
    final dailyProfit = _calculateDailyProfit(dailyTransactions);
    return Column(children: [
        Card(elevation: 4, margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(4.0), child: TableCalendar(
              firstDay: DateTime.utc(2020), lastDay: DateTime.utc(2030), focusedDay: _focusedDay, calendarFormat: _calendarFormat, rowHeight: 85, daysOfWeekHeight: 30,
              headerStyle: HeaderStyle(titleCentered: true, formatButtonVisible: false, titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black), leftChevronIcon: Icon(Icons.chevron_left, color: isDark ? Colors.white : Colors.black), rightChevronIcon: Icon(Icons.chevron_right, color: isDark ? Colors.white : Colors.black)),
              calendarStyle: const CalendarStyle(outsideDaysVisible: false), selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (sel, foc) => setState(() { _selectedDay = sel; _focusedDay = foc; }), onPageChanged: (foc) => _focusedDay = foc,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (ctx, day, foc) => _buildCalendarCell(day, allTransactions, isDark, false),
                todayBuilder: (ctx, day, foc) => _buildCalendarCell(day, allTransactions, isDark, true),
                selectedBuilder: (ctx, day, foc) => _buildCalendarCell(day, allTransactions, isDark, false, isSelected: true),
              ),
            ))),
        const SizedBox(height: 20),
        if (dailyTransactions.isNotEmpty) Card(color: dailyProfit >= 0 ? (isDark?Colors.green.withOpacity(0.2):Colors.green.shade50) : (isDark?Colors.red.withOpacity(0.2):Colors.red.shade50), child: Padding(padding: const EdgeInsets.all(16.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(DateFormat('EEEE, d MMMM').format(_selectedDay!), style: const TextStyle(fontWeight: FontWeight.bold)), Text('${dailyProfit>=0?'+':''}${dailyProfit.toStringAsFixed(2)} \$', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: dailyProfit>=0 ? Colors.green : Colors.red))]))) else const Padding(padding: EdgeInsets.all(16), child: Text("Nicio tranzacție azi.", style: TextStyle(color: Colors.grey))),
        _buildTransactionsList(dailyTransactions),
      ]);
  }

  Widget _buildCalendarCell(DateTime day, List<Transaction> allTxs, bool isDark, bool isToday, {bool isSelected = false}) {
    final txs = _getTransactionsForDay(allTxs, day);
    final dailyProfit = _calculateDailyProfit(txs);
    Color textColor = dailyProfit > 0 ? Colors.green : (dailyProfit < 0 ? Colors.red : (isDark ? Colors.grey[400]! : Colors.grey[600]!));
    Color borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    if (isSelected) borderColor = Colors.teal; else if (isToday) borderColor = Colors.blue.withOpacity(0.5);
    return Container(margin: const EdgeInsets.all(2), padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, border: Border.all(color: borderColor, width: isSelected ? 2 : 1), borderRadius: BorderRadius.circular(6)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(day.day.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)), if (txs.isNotEmpty) Icon(Icons.description_outlined, size: 14, color: isDark ? Colors.white30 : Colors.grey)]),
          const Spacer(), if (txs.isNotEmpty) Center(child: Text(dailyProfit == 0 ? '\$0' : '${dailyProfit > 0 ? '+' : ''}${dailyProfit.toStringAsFixed(0)}', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 15))), const Spacer(),
          if (txs.isNotEmpty) Align(alignment: Alignment.bottomRight, child: Text('${txs.length} trades', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[500] : Colors.grey[600]))),
        ]));
  }

  Widget _buildFiltersBar(List<Strategy> strategies) {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          DropdownButton<String>(value: _timeFilter, items: ['Tot Timpul', 'Luna Aceasta', 'Săptămâna Aceasta'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => _timeFilter = val!)),
          const SizedBox(width: 20), DropdownButton<Strategy?>(value: _strategyFilter, hint: const Text('Toate Strategiile'), items: [const DropdownMenuItem<Strategy?>(value: null, child: Text('Toate Strategiile')), ...strategies.map((s) => DropdownMenuItem<Strategy?>(value: s, child: Text(s.name)))], onChanged: (val) => setState(() => _strategyFilter = val)),
        ]));
  }

  Widget _buildBalanceCard(double totalBalance, double filteredProfit, double initialBalance, int count) {
    return Card(elevation: 4, child: Padding(padding: const EdgeInsets.all(20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Sold Cont (Total)', style: TextStyle(color: Colors.grey)), Text('\$${totalBalance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))]),
          const Divider(), const SizedBox(height: 5), const Text('Rezultat Selecție', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text('${filteredProfit >= 0 ? '+' : ''}${filteredProfit.toStringAsFixed(2)} \$', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: filteredProfit >= 0 ? Colors.green : Colors.red)),
          Text('$count tranzacții găsite', style: const TextStyle(color: Colors.grey)),
        ])));
  }

  Widget _buildKPIGrid(List<Transaction> transactions) {
    if (transactions.isEmpty) return const Text('Fără date pentru KPI.');
    int wins = 0; int losses = 0; double grossProfit = 0; double grossLoss = 0; double maxWin = 0; double maxLoss = 0;
    for (var tx in transactions) {
      if (tx.profitLossAmount >= 0) { wins++; grossProfit += tx.profitLossAmount; if (tx.profitLossAmount > maxWin) maxWin = tx.profitLossAmount; } 
      else { losses++; grossLoss += tx.profitLossAmount.abs(); if (tx.profitLossAmount < maxLoss) maxLoss = tx.profitLossAmount; }
    }
    final total = wins + losses; final winRate = total > 0 ? (wins / total) * 100 : 0.0;
    final profitFactor = grossLoss > 0 ? (grossProfit / grossLoss) : (grossProfit > 0 ? 99.9 : 0.0);
    final avgWin = wins > 0 ? grossProfit / wins : 0.0; final avgLoss = losses > 0 ? grossLoss / losses : 0.0;
    return GridView.count(crossAxisCount: 2, childAspectRatio: 2.5, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 10, crossAxisSpacing: 10, children: [
        _buildStatCard('Win Rate', '${winRate.toStringAsFixed(1)}%', winRate > 50 ? Colors.green : Colors.orange),
        _buildStatCard('Profit Factor', profitFactor.toStringAsFixed(2), profitFactor > 1.5 ? Colors.green : (profitFactor < 1 ? Colors.red : Colors.orange)),
        _buildStatCard('Max Câștig', '+\$${maxWin.toStringAsFixed(0)}', Colors.teal),
        _buildStatCard('Max Pierdere', '-\$${maxLoss.abs().toStringAsFixed(0)}', Colors.red),
        _buildStatCard('Avg Câștig', '\$${avgWin.toStringAsFixed(2)}', Colors.green),
        _buildStatCard('Avg Pierdere', '-\$${avgLoss.toStringAsFixed(2)}', Colors.red),
      ]);
  }
  Widget _buildStatCard(String title, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(isDark ? 0.5 : 0.3)), boxShadow: isDark ? [] : [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 4)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey)), const SizedBox(height: 4), Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color))]));
  }

  Widget _buildEquityChart(List<FlSpot> spots) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (spots.length <= 1) return Container(height: 200, alignment: Alignment.center, decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: const Text('Nu sunt date suficiente.'));
    double minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b); double maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    minY = minY.floorToDouble() - 5; maxY = maxY.ceilToDouble() + 5;
    return Container(height: 250, padding: const EdgeInsets.only(top: 10, right: 10, bottom: 5), decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: isDark ? [] : [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3))]), child: LineChart(LineChartData(minX: 0, maxX: spots.length.toDouble() - 1, minY: minY, maxY: maxY, gridData: const FlGridData(show: false), titlesData: FlTitlesData(show: true, topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10)), reservedSize: 40))), borderData: FlBorderData(show: true, border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300)), lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: Colors.teal, barWidth: 3, isStrokeCapRound: true, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [Colors.teal.withOpacity(0.3), Colors.teal.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter))), LineChartBarData(spots: [FlSpot(0, 0), FlSpot(spots.length.toDouble() - 1, 0)], isCurved: false, color: Colors.grey, barWidth: 1, dotData: const FlDotData(show: false))])));
  }
  
  Widget _buildTransactionsList(List<Transaction> transactions) {
    final displayList = List.from(transactions.reversed);
    if (displayList.isEmpty) return _isCalendarView ? const SizedBox.shrink() : const Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text("Nicio tranzacție.")));
    return ListView.builder(physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, itemCount: displayList.length, itemBuilder: (context, index) {
        final tx = displayList[index] as Transaction; final isWin = tx.profitLossAmount >= 0; final strategyName = tx.strategy.value?.name ?? 'Necunoscută'; 
        return ListTile(leading: Icon(isWin ? Icons.arrow_upward : Icons.arrow_downward, color: isWin ? Colors.green : Colors.red), title: Text('${tx.instrument} (${tx.lotSize.toStringAsFixed(2)})'), subtitle: Text('P/L: \$${tx.profitLossAmount.toStringAsFixed(2)} | $strategyName'), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(tx.entryDate.toString().substring(0, 10), style: const TextStyle(color: Colors.grey, fontSize: 12)), Text(tx.emotion, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic))]), onTap: () async { final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => TransactionDetailScreen(transaction: tx))); if (result == true) _refreshData(); });
    });
  }

  List<FlSpot> _calculateEquityCurve(List<Transaction> filteredTransactions, double initialBalance) {
    if (filteredTransactions.isEmpty) return [];
    filteredTransactions.sort((a, b) => a.entryDate.compareTo(b.entryDate));
    double currentEquity = initialBalance; List<FlSpot> spots = [const FlSpot(0, 0)];
    for (int i = 0; i < filteredTransactions.length; i++) { currentEquity += filteredTransactions[i].profitLossAmount; spots.add(FlSpot((i + 1).toDouble(), currentEquity - initialBalance)); }
    return spots;
  }
}