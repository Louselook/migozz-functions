import 'package:migozz_app/features/profile/presentation/profile_stats.dart';

final Map<String, String> fieldRules = {
  "friends": "followers",
  "fans": "followers",
  "subscribers": "followers",
  "subscriber": "followers",
  "subscriberCount": "followers",
  "followersCount": "followers",
  "hearts": "likes",
  "likes_count": "likes",
  "favorites": "likes",
  "videos": "media",
  "videoCount": "media",
};

String normalizeStatKey(String key) {
  final lower = key.toLowerCase();
  return fieldRules[lower] ?? lower;
}

Map<String, int> calculateUnifiedTotals(List<SocialStats> socials) {
  final Map<String, int> totals = {};
  for (final s in socials) {
    final stats = {
      'followers': s.followers,
      'likes': s.likes,
      'views': s.viewCount,
      'shares': s.shares,
      'media': s.mediaCount,
      'following': s.followingCount,
      'subscribers': s.subscribers,
    };

    for (final entry in stats.entries) {
      final normalized = normalizeStatKey(entry.key);
      totals[normalized] = (totals[normalized] ?? 0) + entry.value;
    }
  }
  return totals;
}