Map<String, dynamic> normalizeSpotify(Map<String, dynamic> params) => {
  'access_token': params['access_token'],
  'refresh_token': params['refresh_token'],
  'username': params['username'],
  'email': params['email'],
  'followers': int.tryParse(params['followers'] ?? '0') ?? 0,
  'pais': params['pais'],
  'plan': params['plan'],
};

Map<String, dynamic> normalizeTwitter(Map<String, dynamic> params) => {
  'id': params['id'],
  'full_name': params['full_name'],
  'username': params['username'],
  'profile_image_url': params['profile_image_url'],
  'followers': int.tryParse(params['followers'] ?? '0') ?? 0,
  'following': int.tryParse(params['following'] ?? '0') ?? 0,
  'likes_count': int.tryParse(params['likes_count'] ?? '0') ?? 0,
  'listed_count': int.tryParse(params['listed_count'] ?? '0') ?? 0,
  'mediaCount': int.tryParse(params['mediaCount'] ?? '0') ?? 0,
  'tweet_count': int.tryParse(params['tweet_count'] ?? '0') ?? 0,
};

Map<String, dynamic> normalizeFacebook(Map<String, dynamic> data) => {
  'id': data['id'],
  'username': data['username'],
  'email': data['email'],
  'profile_image_url': data['profile_image_url'],
  'pages': data['pages'],
};

Map<String, dynamic> normalizeTikTok(Map<String, dynamic> data) => {
  'id': data['id'],
  'username': data['username'],
  'full_name': data['full_name'],
  'profile_image_url': data['profile_image_url'],
  'followers': int.tryParse('${data['followers'] ?? 0}') ?? 0,
  'following': int.tryParse('${data['following'] ?? 0}') ?? 0,
  'likes_count': int.tryParse('${data['likes_count'] ?? 0}') ?? 0,
  'mediaCount': int.tryParse('${data['mediaCount'] ?? 0}') ?? 0,
};

Map<String, dynamic> normalizeInstagram(Map<String, dynamic> data) {
  int toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is double) return v.toInt();
    return 0;
  }

  return {
    'id': data['id'],
    'url': data['url'],
    'username': data['username'],
    'full_name': data['full_name'] ?? '',
    'account_type': data['account_type'] ?? '',
    'profile_image_url': data['profile_image_url'],
    'followers': toInt(data['followers']),
    'following': toInt(data['following']),
    'mediaCount': toInt(data['mediaCount']),
    'access_token': data['access_token'],
    'expires_in': toInt(data['expires_in']),
    'expires_in_days': toInt(data['expires_in_days']),
    // recent_media puede venir como List<dynamic> de maps
    'recent_media': (data['recent_media'] is List)
        ? List<Map<String, dynamic>>.from(
            (data['recent_media'] as List).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          )
        : <Map<String, dynamic>>[],
  };
}

Map<String, dynamic> normalizeYouTube(Map<String, dynamic> data) {
  int toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is double) return v.toInt();
    return 0;
  }

  return {
    'id': data['id'],
    'username': data['username'] ?? '',
    'full_name':
        data['full_name'] ??
        data['title'] ??
        '', // Ambos campos por compatibilidad
    'url': data['url'] ?? '',
    'profile_image_url': data['profile_image_url'],
    'followers': toInt(
      data['followers'] ?? data['subscriberCount'],
    ), // Soporta ambos nombres
    'viewCount': toInt(data['viewCount']),
    'mediaCount': toInt(data['mediaCount'] ?? data['videoCount']),
    'hiddenSubscriberCount': data['hiddenSubscriberCount'] ?? false,
  };
}
