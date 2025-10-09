import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String? displayName;
  final String? username;
  final String? email;
  final String? phone;
  final String? gender;
  final String? city;
  final String? state;
  final String? country;
  final String? avatarUrl;
  final DateTime? dob;
  final double? lat;
  final double? lng;

  UserProfile({
    required this.id,
    this.displayName,
    this.username,
    this.email,
    this.phone,
    this.gender,
    this.city,
    this.state,
    this.country,
    this.avatarUrl,
    this.dob,
    this.lat,
    this.lng,
  });

  /// Crea un objeto UserProfile a partir de un documento de Firestore.
  factory UserProfile.fromFirestore(String id, Map<String, dynamic>? data) {
    if (data == null) return UserProfile(id: id);

    final rawDob = data['dob'];
    DateTime? parsedDob;

    if (rawDob is Timestamp) {
      parsedDob = rawDob.toDate().toUtc();
    } else if (rawDob is String && rawDob.isNotEmpty) {
      final parts = rawDob.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          parsedDob = DateTime.utc(y, m, d);
        }
      }
    }

    // 🔹 Extraemos correctamente el bloque de ubicación
    final location = (data['location'] as Map?) ?? const {};

    return UserProfile(
      id: id,
      displayName: data['displayName'],
      username: data['username'],
      email: data['email'],
      phone: data['phone'],
      gender: data['gender'],
      city: location['city'],
      state: location['state'],
      country: location['country'],
      avatarUrl: data['avatarUrl'],
      dob: parsedDob,
      lat: (location['lat'] as num?)?.toDouble(),
      lng: (location['lng'] as num?)?.toDouble(),
    );
  }

  /// Convierte este objeto en un mapa para guardar en Firestore.
  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'username': username,
        'email': email,
        'phone': phone,
        'gender': gender,
        'avatarUrl': avatarUrl,
        if (dob != null) 'dob': Timestamp.fromDate(dob!),
        'location': {
          'city': city,
          'state': state,
          'country': country,
          'lat': lat,
          'lng': lng,
        },
      };

  /// Crea una copia modificada del perfil.
  UserProfile copyWith({
    String? displayName,
    String? username,
    String? email,
    String? phone,
    String? gender,
    String? city,
    String? state,
    String? country,
    String? avatarUrl,
    DateTime? dob,
    double? lat,
    double? lng,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dob: dob ?? this.dob,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

