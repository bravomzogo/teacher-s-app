import 'package:flutter/material.dart';

class Student {
  final int? id;
  final String firstName;
  final String middleName;
  final String lastName;
  final String? gender;
  final String? grade;
  final String? createdAt;

  Student({
    this.id,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    this.gender,
    this.grade,
    this.createdAt,
  });

  String get fullName => '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName';
  String get shortName => '$firstName $lastName';
  String get displayName => fullName;

  Map<String, dynamic> toMap() => {
    'id': id,
    'firstName': firstName,
    'middleName': middleName,
    'lastName': lastName,
    'gender': gender,
    'grade': grade,
    'createdAt': createdAt,
  };

  factory Student.fromMap(Map<String, dynamic> m) => Student(
    id: m['id'],
    firstName: m['firstName'] ?? '',
    middleName: m['middleName'] ?? '',
    lastName: m['lastName'] ?? '',
    gender: m['gender'],
    grade: m['grade'],
    createdAt: m['createdAt'],
  );

  String get avatarText {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    }
    return '?';
  }

  Color get avatarColor {
    final colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.pink.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.red.shade400,
    ];
    final index = (fullName.hashCode % colors.length).abs();
    return colors[index];
  }

  @override
  String toString() => '$fullName (${grade ?? "N/A"})';
}