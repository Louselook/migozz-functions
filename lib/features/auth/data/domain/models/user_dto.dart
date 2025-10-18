import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:migozz_app/features/auth/data/domain/models/location_dto.dart';

class UserDTO {
  // Parte 1
  final String email;
  final String lang;
  final String displayName;
  final String username;
  final String gender;

  /// Más flexible: acepta distintos shapes como los que tienes en Firestore
  final List<Map<String, dynamic>>? socialEcosystem;

  final LocationDTO location;

  // new add
  final String? avatarUrl;
  final String? phone;
  final String? voiceNoteUrl;
  final List<String>? category;

  final Map<String, List<String>> interests;

  final DateTime createdAt;
  final DateTime updatedAt;

  UserDTO({
    required this.email,
    required this.lang,
    required this.displayName,
    required this.username,
    required this.gender,
    this.socialEcosystem,
    required this.location,
    this.avatarUrl,
    this.phone,
    this.voiceNoteUrl,
    this.category,
    Map<String, List<String>>? interests,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : interests = interests ?? <String, List<String>>{},
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  UserDTO copyWith({
    String? email,
    String? lang,
    String? displayName,
    String? username,
    String? gender,
    List<Map<String, dynamic>>? socialEcosystem,
    LocationDTO? location,
    String? avatarUrl,
    String? phone,
    String? voiceNoteUrl,
    List<String>? category,
    Map<String, List<String>>? interests,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserDTO(
      email: email ?? this.email,
      lang: lang ?? this.lang,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      gender: gender ?? this.gender,
      socialEcosystem: socialEcosystem ?? this.socialEcosystem,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      category: category ?? this.category,
      interests: interests ?? this.interests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'lang': lang,
      'displayName': displayName,
      'username': username,
      'gender': gender,
      'socialEcosystem': socialEcosystem,
      'location': location.toMap(),
      'avatarUrl': avatarUrl,
      'phone': phone,
      'voiceNoteUrl': voiceNoteUrl,
      'category': category,
      'interests': interests,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Factory defensivo para normalizar lo que venga de Firestore
  factory UserDTO.fromMap(Map<String, dynamic> map) {
    final email = (map['email'] ?? '').toString();
    final lang = (map['lang'] ?? 'es').toString();
    final displayName = (map['displayName'] ?? '').toString();
    final username = (map['username'] ?? '').toString();
    final gender = (map['gender'] ?? '').toString();
    final avatarUrl = map['avatarUrl']?.toString();
    final phone = map['phone']?.toString();
    final voiceNoteUrl = map['voiceNoteUrl']?.toString();

    // category
    List<String>? category;
    if (map['category'] is List) {
      try {
        category = List<String>.from(
          (map['category'] as List).map((e) => e?.toString() ?? ''),
        );
      } catch (_) {
        category = (map['category'] as List).map((e) => e.toString()).toList();
      }
    }

    // interests -> Map<String, List<String>>
    final Map<String, List<String>> interests = {};
    if (map['interests'] is Map) {
      final raw = Map<String, dynamic>.from(map['interests'] as Map);
      raw.forEach((k, v) {
        if (v is List) {
          interests[k.toString()] = List<String>.from(
            v.map((e) => e?.toString() ?? ''),
          );
        } else if (v != null) {
          interests[k.toString()] = [v.toString()];
        } else {
          interests[k.toString()] = <String>[];
        }
      });
    }

    // socialEcosystem -> List<Map<String,dynamic>>
    List<Map<String, dynamic>>? socialEcosystem;
    final rawSocial = map['socialEcosystem'];
    if (rawSocial != null) {
      if (rawSocial is List) {
        socialEcosystem = [];
        for (final item in rawSocial) {
          if (item is Map) {
            socialEcosystem.add(Map<String, dynamic>.from(item));
          } else {
            socialEcosystem.add({'value': item});
          }
        }
      } else if (rawSocial is Map) {
        socialEcosystem = [Map<String, dynamic>.from(rawSocial)];
      }
    }

    // location defensivo
    LocationDTO location;
    if (map['location'] is Map) {
      try {
        location = LocationDTO.fromMap(
          Map<String, dynamic>.from(map['location']),
        );
      } catch (_) {
        final lm = Map<String, dynamic>.from(map['location'] as Map);
        location = LocationDTO(
          country: lm['country']?.toString() ?? '',
          state: lm['state']?.toString() ?? '',
          city: lm['city']?.toString() ?? '',
          lat: (lm['lat'] is num) ? (lm['lat'] as num).toDouble() : 0.0,
          lng: (lm['lng'] is num) ? (lm['lng'] as num).toDouble() : 0.0,
        );
      }
    } else {
      location = LocationDTO(
        country: '',
        state: '',
        city: '',
        lat: 0.0,
        lng: 0.0,
      );
    }

    // createdAt / updatedAt defensivo
    DateTime createdAt = DateTime.now();
    DateTime updatedAt = DateTime.now();

    final ca = map['createdAt'];
    if (ca != null) {
      if (ca is Timestamp) {
        createdAt = ca.toDate();
      } else if (ca is DateTime) {
        createdAt = ca;
      } else if (ca is String) {
        createdAt = DateTime.tryParse(ca) ?? DateTime.now();
      } else if (ca is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(ca);
      }
    }

    final ua = map['updatedAt'];
    if (ua != null) {
      if (ua is Timestamp) {
        updatedAt = ua.toDate();
      } else if (ua is DateTime) {
        updatedAt = ua;
      } else if (ua is String) {
        updatedAt = DateTime.tryParse(ua) ?? DateTime.now();
      } else if (ua is int) {
        updatedAt = DateTime.fromMillisecondsSinceEpoch(ua);
      }
    }

    return UserDTO(
      email: email,
      lang: lang,
      displayName: displayName,
      username: username,
      gender: gender,
      socialEcosystem: socialEcosystem,
      location: location,
      avatarUrl: avatarUrl,
      phone: phone,
      voiceNoteUrl: voiceNoteUrl,
      category: category,
      interests: interests,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
