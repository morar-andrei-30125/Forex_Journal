import 'package:isar/isar.dart';

part 'strategy.g.dart';

@Collection()
class Strategy {
  Id id = Isar.autoIncrement; 

  @Index(unique: true)
  late String name; 
  
  String? description; 

  Strategy({
    required this.name,
    this.description,
  });
}