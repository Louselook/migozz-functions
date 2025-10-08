import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String? displayName;
  final String? username;
  final String? email;
  final String? phone;
  final String? gender;
  final String? city;
  final String? avatarUrl;
  final DateTime? dob;

  UserProfile({
    required this.id,
    this.displayName,
    this.username,
    this.email,
    this.phone,
    this.gender,
    this.city,
    this.avatarUrl,
    this.dob,
  });

  factory UserProfile.fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) return UserProfile(id: id);
    final rawDob = data['dob'];
    DateTime? parsedDob;

    if (rawDob is Timestamp) {
      parsedDob = rawDob.toDate().toUtc();
    } else if (rawDob is String && rawDob.isNotEmpty) {
      final parts = rawDob.split('-');
      if (parts.length == 3) {
        parsedDob = DateTime.utc(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    }

    final location = (data['location'] as Map?) ?? const {};
    return UserProfile(
      id: id,
      displayName: data['displayName'],
      username: data['username'],
      email: data['email'],
      phone: data['phone'],
      gender: data['gender'],
      city: location['city'],
      avatarUrl: data['avatarUrl'],
      dob: parsedDob,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'username': username,
        'email': email,
        'phone': phone,
        'gender': gender,
        'avatarUrl': avatarUrl,
        'dob': dob?.toIso8601String(),
        'location': {'city': city},
      };

  UserProfile copyWith({
    String? displayName,
    String? username,
    String? email,
    String? phone,
    String? gender,
    String? city,
    String? avatarUrl,
    DateTime? dob,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dob: dob ?? this.dob,
    );
  }
}
