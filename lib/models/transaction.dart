import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  String id;
  String accountId;
  String instrument;
  double entryPrice;
  double exitPrice;
  DateTime entryDate;
  DateTime exitDate;
  double lotSize;
  double profitLossAmount;
  double profitLossPips;
  double swap;
  String emotion;
  String comment;
  String strategyName;
  String strategyId;

  Transaction({
    this.id = '',
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
    this.emotion = 'Neutral',
    required this.strategyName,
    required this.strategyId,
    this.swap = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'accountId': accountId,
      'entryDate': Timestamp.fromDate(entryDate),
      'exitDate': Timestamp.fromDate(exitDate),
      'instrument': instrument,
      'entryPrice': entryPrice,
      'exitPrice': exitPrice,
      'lotSize': lotSize,
      'profitLossAmount': profitLossAmount,
      'profitLossPips': profitLossPips,
      'comment': comment,
      'emotion': emotion,
      'strategyName': strategyName,
      'strategyId': strategyId,
      'swap': swap,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> data, String id) {
    return Transaction(
      id: id,
      accountId: data['accountId'] ?? '',
      entryDate: (data['entryDate'] as Timestamp).toDate(),
      exitDate: (data['exitDate'] as Timestamp).toDate(),
      instrument: data['instrument'] ?? '',
      entryPrice: (data['entryPrice'] ?? 0.0).toDouble(),
      exitPrice: (data['exitPrice'] ?? 0.0).toDouble(),
      lotSize: (data['lotSize'] ?? 0.0).toDouble(),
      profitLossAmount: (data['profitLossAmount'] ?? 0.0).toDouble(),
      profitLossPips: (data['profitLossPips'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      emotion: data['emotion'] ?? 'Neutral',
      strategyName: data['strategyName'] ?? 'Unknown',
      strategyId: data['strategyId'] ?? '',
      swap: (data['swap'] ?? 0.0).toDouble(),
    );
  }
}