import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  String id;
  String firstName;
  String lastName;
  DateTime? dateOfBirth;
  String jobTitle;
  String? profileImagePath;

  UserProfile({
    this.id = '',
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    required this.jobTitle,
    this.profileImagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'jobTitle': jobTitle,
      'profileImagePath': profileImagePath,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> data, String id) {
    return UserProfile(
      id: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      dateOfBirth: data['dateOfBirth'] != null ? (data['dateOfBirth'] as Timestamp).toDate() : null,
      jobTitle: data['jobTitle'] ?? '',
      profileImagePath: data['profileImagePath'],
    );
  }
}