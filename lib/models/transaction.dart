import 'package:isar/isar.dart';
import 'strategy.dart'; 

part 'transaction.g.dart';

@Collection()
class Transaction {
  Id id = Isar.autoIncrement;

  @Index()
  late int accountId; 
  
  late String instrument;
  late double entryPrice;
  late double exitPrice;
  late DateTime entryDate;
  late DateTime exitDate;
  late double lotSize;
  late double profitLossAmount;
  late double profitLossPips;

  late String emotion; 
  final strategy = IsarLink<Strategy>(); 
  late String comment; 
  late String screenshotPath; 
  
  Transaction({
    required this.accountId,
    required this.entryDate,
    required this.exitDate,
    required this.instrument,
    required this.entryPrice,
    required this.exitPrice,
    required this.lotSize,
    required this.profitLossAmount,
    required this.profitLossPips,
    required this.comment,
    required this.screenshotPath,
    this.emotion = 'Neutru',
  });
}