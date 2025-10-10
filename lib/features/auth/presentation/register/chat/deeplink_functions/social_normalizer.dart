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
