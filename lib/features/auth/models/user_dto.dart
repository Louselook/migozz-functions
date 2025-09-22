import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';

class UserDTO {
  // Parte 1
  final String email;
  final String lang;
  final String displayName;
  final String username;
  final String gender;
  final List<String>? socialEcosystem;
  final LocationDTO location;

  // Parte 2
  // final String birthday;
  // final String? phone;
  // final String? category;
  // final Map<String, List<String>> interests;
  // final String? avatarUrl;
  // final String? voiceNoteUrl;
  // final int totalFollowers;
  // final int linksCount;
  // final ShareDTO? share;
  // final OnboardingDTO? onboarding;
  // final PrivacyDTO? privacy;

  final DateTime createdAt;
  final DateTime updatedAt;

  UserDTO({
    // Parte 1
    required this.email,
    required this.lang,
    required this.displayName,
    required this.username,
    required this.gender,
    this.socialEcosystem,
    required this.location,

    // Parte 2
    // required this.birthday,
    // this.phone,
    // this.category,
    // required this.interests,
    // this.avatarUrl,
    // this.voiceNoteUrl,
    // this.totalFollowers = 0,
    // this.linksCount = 0,
    // this.share,
    // this.onboarding,
    // this.privacy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Copia el objeto y permite sobrescribir campos específicos
  UserDTO copyWith({
    // Parte 1
    String? email,
    String? lang,
    String? displayName,
    String? username,
    String? gender,
    List<String>? socialEcosystem,
    LocationDTO? location,

    // Parte 2
    // String? birthday,
    // String? phone,
    // String? category,
    // Map<String, List<String>>? interests,
    // String? avatarUrl,
    // String? voiceNoteUrl,
    // int? totalFollowers,
    // int? linksCount,
    // ShareDTO? share,
    // OnboardingDTO? onboarding,
    // PrivacyDTO? privacy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserDTO(
      // Parte 1
      email: email ?? this.email,
      lang: lang ?? this.lang,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      gender: gender ?? this.gender,
      socialEcosystem: socialEcosystem ?? this.socialEcosystem,
      location: location ?? this.location,

      // Parte 2
      // birthday: birthday ?? this.birthday,
      // phone: phone ?? this.phone,
      // category: category ?? this.category,
      // interests: interests ?? this.interests,
      // avatarUrl: avatarUrl ?? this.avatarUrl,
      // voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      // totalFollowers: totalFollowers ?? this.totalFollowers,
      // linksCount: linksCount ?? this.linksCount,
      // share: share ?? this.share,
      // onboarding: onboarding ?? this.onboarding,
      // privacy: privacy ?? this.privacy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // Parte 1
      'email': email,
      'lang': lang,
      'displayName': displayName,
      'username': username,
      'gender': gender,
      'socialEcosystem': socialEcosystem,
      'location': location.toMap(),

      // Parte 2
      // 'birthday': birthday,
      // 'phone': phone,
      // 'category': category,
      // 'interests': interests,
      // 'avatarUrl': avatarUrl,
      // 'voiceNoteUrl': voiceNoteUrl,
      // 'totalFollowers': totalFollowers,
      // 'linksCount': linksCount,
      // 'share': share?.toMap(),
      // 'onboarding': onboarding?.toMap(),
      // 'privacy': privacy?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
