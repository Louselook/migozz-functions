import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para representar un seguidor o seguido
/// Se usa para almacenar en:
/// - users/{userId}/followerList/{followerId}
/// - users/{userId}/followingList/{followingId}
class FollowerDTO {
  /// El ID del usuario (email)
  final String oderId;

  /// Fecha en que comenzó a seguir
  final DateTime followingDate;

  /// Información adicional del usuario (para mostrar en listas)
  final String? displayName;
  final String? username;
  final String? avatarUrl;

  FollowerDTO({
    required this.oderId,
    required this.followingDate,
    this.displayName,
    this.username,
    this.avatarUrl,
  });

  /// Constructor para crear solo con el ID y timestamp
  factory FollowerDTO.create(String oderId) {
    return FollowerDTO(oderId: oderId, followingDate: DateTime.now());
  }

  /// Convierte a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {'followingDate': Timestamp.fromDate(followingDate)};
  }

  /// Constructor desde Map de Firestore
  factory FollowerDTO.fromMap(String oderId, Map<String, dynamic> map) {
    DateTime followingDate;
    final fd = map['followingDate'];
    if (fd is Timestamp) {
      followingDate = fd.toDate();
    } else if (fd is DateTime) {
      followingDate = fd;
    } else if (fd is String) {
      followingDate = DateTime.tryParse(fd) ?? DateTime.now();
    } else {
      followingDate = DateTime.now();
    }

    return FollowerDTO(
      oderId: oderId,
      followingDate: followingDate,
      displayName: map['displayName']?.toString(),
      username: map['username']?.toString(),
      avatarUrl: map['avatarUrl']?.toString(),
    );
  }

  /// Copia con información de usuario agregada
  FollowerDTO copyWithUserInfo({
    String? displayName,
    String? username,
    String? avatarUrl,
  }) {
    return FollowerDTO(
      oderId: oderId,
      followingDate: followingDate,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  String toString() {
    return 'FollowerDTO(oderId: $oderId, followingDate: $followingDate, '
        'displayName: $displayName, username: $username)';
  }
}
