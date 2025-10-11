import 'package:migozz_app/features/auth/models/user_dto.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';

UserDTO createTestUser({
  String? email,
  String? displayName,
  String? username,
  String? gender,
  String? lang,
  LocationDTO? location,
  String? avatarUrl,
  String? phone,
  List<String>? category,
  Map<String, List<String>>? interests,
  List<Map<String, Map<String, dynamic>>>? socialEcosystem,
}) {
  return UserDTO(
    email: email ?? "issamu382@gmail.com",
    lang: lang ?? "Español",
    displayName: displayName ?? "Samuel Obando",
    username: username ?? "Obanditto",
    gender: gender ?? "Macho",
    location:
        location ??
        LocationDTO(
          country: "Colombia",
          state: "Antioquia",
          city: "Medellín",
          lat: 6.1817477,
          lng: -75.6427398,
        ),
    avatarUrl:
        avatarUrl ??
        "https://storage.googleapis.com/migozz-e2a21.firebasestorage.app/users/issamu382%40gmail.com/avatar/c2b77958-6f20-446a-8f73-6136060c2e9a.jpg",
    phone: phone ?? "3195293490",
    category: category ?? ["Model", "Streamer", "Artist"],
    interests:
        interests ??
        {
          "Business": ["Marketing"],
          "Film & TV": ["Anime", "Sci-fi", "Comedy"],
          "Going Out": [
            "Museums & Galleries",
            "Comedy",
            "Theater",
            "Clubs",
            "Bars",
            "Karaoke",
          ],
          "Sports": ["Basketball", "Snowboarding"],
          "Staying In": ["Reading", "Board Games", "Video Games"],
          "Values & Traits": ["Intelligence", "Positivity", "Creativity"],
        },
    socialEcosystem:
        socialEcosystem ??
        [
          {
            "instagram": {
              "username": "solaratzo",
              "full_name": "Sam Obando",
              "followers": 67,
              "followees": 1561,
              "total_posts": 2,
              "profile_image_url":
                  "https://scontent-atl3-3.cdninstagram.com/v/t51.2885-19/495595875_18403507465097783_250818832121855530_n.jpg",
              "url": "https://www.instagram.com/solaratzo/",
            },
          },
        ],
  );
}

// Ejemplo de uso:
void main() {
  final testUser = createTestUser();

  print("Nombre: ${testUser.displayName}");
  print("Email: ${testUser.email}");
  print("Ciudad: ${testUser.location.city}");
  print("Avatar: ${testUser.avatarUrl}");
  print("Intereses: ${testUser.interests.keys.toList()}");
}
