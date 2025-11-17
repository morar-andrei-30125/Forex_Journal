import 'package:isar/isar.dart';

part 'account.g.dart';

@Collection()
class Account {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String name;

  late double initialBalance;
  late String type; 

  Account({
    required this.name,
    required this.initialBalance,
    required this.type,
  });
}