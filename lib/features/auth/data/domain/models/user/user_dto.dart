import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/location_dto.dart';

class UserDTO {
  final String email;
  final String lang;
  final String displayName;
  final String username;
  final String? gender;
  String? bio;
  final DateTime? birthDate;

  final List<Map<String, dynamic>>? socialEcosystem;
  final List<Map<String, dynamic>>? featuredLinks;
  final LocationDTO location;

  final String? avatarUrl;
  final String? phone;
  final String? voiceNoteUrl;
  final String? wallet;
  final List<String>? category;
  final int profileVersion; // 1, 2 o 3 - versión del diseño de perfil

  // Contact info
  final String? contactWebsite;
  final String? contactPhone;
  final String? contactEmail;

  final Map<String, List<String>> interests;
  final bool complete;

  // Pre-registro: usuarios que reservaron username antes de registrarse
  final bool isPreRegistered;

  final DateTime createdAt;
  final DateTime updatedAt;

  // 🆕 Timestamp de la última sincronización de redes sociales (cada 15 días)
  final DateTime? lastSocialEcosystemSync;
  // 🆕 Mapa para rastrear la fecha en que cada red social fue agregada
  final Map<String, DateTime>? socialEcosystemAddedDates;

  UserDTO({
    required this.email,
    required this.lang,
    required this.displayName,
    required String username, // 👈 recibe el valor crudo
    this.gender,
    this.birthDate,
    this.bio,
    this.socialEcosystem,
    this.featuredLinks,
    required this.location,
    this.avatarUrl,
    this.phone,
    this.voiceNoteUrl,
    this.category,
    this.wallet,
    this.profileVersion = 1,
    this.contactWebsite,
    this.contactPhone,
    this.contactEmail,
    Map<String, List<String>>? interests,
    this.complete = true,
    this.isPreRegistered = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastSocialEcosystemSync,
    this.socialEcosystemAddedDates,
  }) : username = username.trim().toLowerCase(),
       interests = interests ?? <String, List<String>>{},
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  UserDTO copyWith({
    String? email,
    String? lang,
    String? displayName,
    String? username,
    String? gender,
    String? bio,
    DateTime? birthDate,
    List<Map<String, dynamic>>? socialEcosystem,
    List<Map<String, dynamic>>? featuredLinks,
    LocationDTO? location,
    String? avatarUrl,
    String? phone,
    String? voiceNoteUrl,
    List<String>? category,
    int? profileVersion,
    String? contactWebsite,
    String? contactPhone,
    String? contactEmail,
    Map<String, List<String>>? interests,
    bool? complete,
    bool? isPreRegistered,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSocialEcosystemSync,
    Map<String, DateTime>? socialEcosystemAddedDates,
  }) {
    return UserDTO(
      email: email ?? this.email,
      lang: lang ?? this.lang,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      birthDate: birthDate ?? this.birthDate,
      socialEcosystem: socialEcosystem ?? this.socialEcosystem,
      featuredLinks: featuredLinks ?? this.featuredLinks,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
      category: category ?? this.category,
      profileVersion: profileVersion ?? this.profileVersion,
      contactWebsite: contactWebsite ?? this.contactWebsite,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      interests: interests ?? this.interests,
      complete: complete ?? this.complete,
      isPreRegistered: isPreRegistered ?? this.isPreRegistered,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSocialEcosystemSync:
          lastSocialEcosystemSync ?? this.lastSocialEcosystemSync,
      socialEcosystemAddedDates:
          socialEcosystemAddedDates ?? this.socialEcosystemAddedDates,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'lang': lang,
      'displayName': displayName,
      'username': username,
      'gender': gender,
      'bio': bio,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'socialEcosystem': socialEcosystem,
      'featuredLinks': featuredLinks,
      'location': location.toMap(),
      'avatarUrl': avatarUrl,
      'phone': phone,
      'voiceNoteUrl': voiceNoteUrl,
      'category': category,
      'profileVersion': profileVersion,
      'contactWebsite': contactWebsite,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'interests': interests,
      'complete': complete,
      'isPreRegistered': isPreRegistered,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastSocialEcosystemSync': lastSocialEcosystemSync != null
          ? Timestamp.fromDate(lastSocialEcosystemSync!)
          : null,
      'socialEcosystemAddedDates': socialEcosystemAddedDates?.map(
        (k, v) => MapEntry(k, Timestamp.fromDate(v)),
      ),
    };
  }

  /// Converts to a JSON-serializable map (no Timestamps, uses ISO strings)
  /// Use this for HTTP API calls instead of toMap()
  Map<String, dynamic> toJsonMap() {
    return {
      'email': email,
      'lang': lang,
      'displayName': displayName,
      'username': username,
      'gender': gender,
      'bio': bio,
      'birthDate': birthDate?.toIso8601String(),
      'socialEcosystem': socialEcosystem,
      'featuredLinks': featuredLinks,
      'location': location.toMap(),
      'avatarUrl': avatarUrl,
      'phone': phone,
      'voiceNoteUrl': voiceNoteUrl,
      'category': category,
      'profileVersion': profileVersion,
      'contactWebsite': contactWebsite,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'interests': interests,
      'complete': complete,
      'isPreRegistered': isPreRegistered,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastSocialEcosystemSync': lastSocialEcosystemSync?.toIso8601String(),
      'socialEcosystemAddedDates': socialEcosystemAddedDates?.map(
        (k, v) => MapEntry(k, v.toIso8601String()),
      ),
    };
  }

  factory UserDTO.fromMap(Map<String, dynamic> map) {
    final email = (map['email'] ?? '').toString();
    final lang = (map['lang'] ?? 'es').toString();
    final displayName = (map['displayName'] ?? '').toString();
    final username = (map['username'] ?? '').toString();
    final gender = (map['gender'] ?? '').toString();
    final bio = map['bio']?.toString();
    final avatarUrl = map['avatarUrl']?.toString();
    final phone = map['phone']?.toString();
    final voiceNoteUrl = map['voiceNoteUrl']?.toString();
    final contactWebsite = map['contactWebsite']?.toString();
    final contactPhone = map['contactPhone']?.toString();
    final contactEmail = map['contactEmail']?.toString();
    final wallet = map['wallet']?.toString();

    // ✅ birthDate defensivo
    DateTime? birthDate;
    final bd = map['birthDate'];
    if (bd != null) {
      if (bd is Timestamp) {
        birthDate = bd.toDate();
      } else if (bd is DateTime) {
        birthDate = bd;
      } else if (bd is String) {
        birthDate = DateTime.tryParse(bd);
      } else if (bd is int) {
        birthDate = DateTime.fromMillisecondsSinceEpoch(bd);
      }
    }

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

    // interests
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

    // socialEcosystem
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

    // featuredLinks
    List<Map<String, dynamic>>? featuredLinks;
    final rawLinks = map['featuredLinks'];
    if (rawLinks != null) {
      if (rawLinks is List) {
        featuredLinks = [];
        for (final item in rawLinks) {
          if (item is Map) {
            featuredLinks.add(Map<String, dynamic>.from(item));
          }
        }
      }
    }

    // location
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

    // createdAt / updatedAt
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

    // complete defensivo
    bool complete = false;
    final c = map['complete'];
    if (c is bool) {
      complete = c;
    } else if (c is String) {
      complete = c.toLowerCase() == 'true';
    } else if (c is num) {
      complete = c != 0;
    }

    // isPreRegistered defensivo
    bool isPreRegistered = false;
    final ipr = map['isPreRegistered'];
    if (ipr is bool) {
      isPreRegistered = ipr;
    } else if (ipr is String) {
      isPreRegistered = ipr.toLowerCase() == 'true';
    } else if (ipr is num) {
      isPreRegistered = ipr != 0;
    }

    // profileVersion defensivo
    int profileVersion = 1; // Por defecto versión 1
    final pv = map['profileVersion'];
    if (pv is int) {
      profileVersion = pv;
    } else if (pv is String) {
      profileVersion = int.tryParse(pv) ?? 1;
    } else if (pv is num) {
      profileVersion = pv.toInt();
    }
    // Validar que esté entre 1 y 3
    if (profileVersion < 1 || profileVersion > 3) {
      profileVersion = 1;
    }

    // 🆕 lastSocialEcosystemSync defensivo
    DateTime? lastSocialEcosystemSync;
    final lses = map['lastSocialEcosystemSync'];
    if (lses != null) {
      if (lses is Timestamp) {
        lastSocialEcosystemSync = lses.toDate();
      } else if (lses is DateTime) {
        lastSocialEcosystemSync = lses;
      } else if (lses is String) {
        lastSocialEcosystemSync = DateTime.tryParse(lses);
      } else if (lses is int) {
        lastSocialEcosystemSync = DateTime.fromMillisecondsSinceEpoch(lses);
      }
    }

    // 🆕 socialEcosystemAddedDates defensivo
    Map<String, DateTime>? socialEcosystemAddedDates;
    final sead = map['socialEcosystemAddedDates'];
    if (sead is Map) {
      socialEcosystemAddedDates = {};
      final rawDates = Map<String, dynamic>.from(sead);
      rawDates.forEach((k, v) {
        if (v is Timestamp) {
          socialEcosystemAddedDates![k] = v.toDate();
        } else if (v is DateTime) {
          socialEcosystemAddedDates![k] = v;
        } else if (v is String) {
          final parsed = DateTime.tryParse(v);
          if (parsed != null) {
            socialEcosystemAddedDates![k] = parsed;
          }
        } else if (v is int) {
          socialEcosystemAddedDates![k] = DateTime.fromMillisecondsSinceEpoch(
            v,
          );
        }
      });
    }

    return UserDTO(
      email: email,
      lang: lang,
      displayName: displayName,
      username: username,
      gender: gender,
      bio: bio,
      birthDate: birthDate,
      socialEcosystem: socialEcosystem,
      featuredLinks: featuredLinks,
      location: location,
      avatarUrl: avatarUrl,
      phone: phone,
      voiceNoteUrl: voiceNoteUrl,
      category: category,
      profileVersion: profileVersion,
      contactWebsite: contactWebsite,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      interests: interests,
      complete: complete,
      isPreRegistered: isPreRegistered,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastSocialEcosystemSync: lastSocialEcosystemSync,
      socialEcosystemAddedDates: socialEcosystemAddedDates,
      wallet: wallet
    );
  }
}
