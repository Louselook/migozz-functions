import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';

class UserDTO {
  // Parte 1
  final String email;
  final String lang;
  final String displayName;
  final String username;
  final String gender;
  List<Map<String, Map<String, dynamic>>>? socialEcosystem;
  final LocationDTO location;

  // new add
  final String? avatarUrl;
  final String? phone;
  final String? voiceNoteUrl;
  final List<String>? category;
  final Map<String, List<String>> interests;

  // Parte 2
  // final String birthday;
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

    // new add
    this.avatarUrl,
    this.phone,
    this.voiceNoteUrl,
    this.category,
    required this.interests,

    // Parte 2
    // required this.birthday,
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
    List<Map<String, Map<String, dynamic>>>? socialEcosystem,
    LocationDTO? location,

    // new add
    String? avatarUrl,
    String? phone,
    String? voiceNoteUrl,
    List<String>? category,
    Map<String, List<String>>? interests,

    // Parte 2
    // String? birthday,
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

      // add new
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      category: category ?? this.category,
      interests: interests ?? this.interests,

      // Parte 2
      // birthday: birthday ?? this.birthday,
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

      // add new
      'avatarUrl': avatarUrl,
      'phone': phone,
      'voiceNoteUrl': voiceNoteUrl,
      'category': category,
      'interests': interests,

      // Parte 2
      // 'birthday': birthday,

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
