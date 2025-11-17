import 'package:isar/isar.dart';

part 'user_profile.g.dart';

@Collection()
class UserProfile {
  Id id = Isar.autoIncrement;

  late String firstName;
  late String lastName;
  late DateTime? dateOfBirth;
  late String jobTitle;
  late String? profileImagePath; 

  UserProfile({
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    required this.jobTitle,
    this.profileImagePath,
  });
}