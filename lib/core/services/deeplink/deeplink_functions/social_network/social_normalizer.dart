// lib/core/services/deeplink/deeplink_functions/social_network/social_normalizer.dart

/// Helper para convertir cualquier valor a int de forma segura
int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? 0;
  if (v is double) return v.toInt();
  return 0;
}

/// Helper para convertir cualquier valor a String de forma segura
String _toString(dynamic v, {String defaultValue = ''}) {
  if (v == null) return defaultValue;
  if (v is String) return v;
  return v.toString();
}

// ==================== TIKTOK ====================
Map<String, dynamic> normalizeTikTok(Map<String, dynamic> data) {
  return {
    'id': _toString(data['id']),
    'url': _toString(data['url']),
    'username': _toString(data['username']),
    'full_name': _toString(data['full_name']),
    'profile_image_url': _toString(data['profile_image_url']),
    'followers': _toInt(data['followers']),
    'following': _toInt(data['following']),
    'likes': _toInt(data['likes']),
    'videos': _toInt(data['videos']),
    'bio': _toString(data['bio']),
    'verified': data['verified'] ?? false,
  };
}

// ==================== INSTAGRAM ====================
Map<String, dynamic> normalizeInstagram(Map<String, dynamic> data) {
  return {
    'id': _toString(data['id']),
    'url': _toString(data['url']),
    'username': _toString(data['username']),
    'full_name': _toString(data['full_name']),
    'profile_image_url': _toString(data['profile_image_url']),
    'followers': _toInt(data['followers']),
    'following': _toInt(data['following']),
    'mediaCount': _toInt(data['mediaCount']),
    'bio': _toString(data['bio']),
    'verified': data['verified'] ?? false,

    // Campos opcionales de OAuth (solo vienen de instagram_auth)
    if (data.containsKey('account_type'))
      'account_type': _toString(data['account_type']),
    if (data.containsKey('access_token'))
      'access_token': _toString(data['access_token']),
    if (data.containsKey('expires_in'))
      'expires_in': _toInt(data['expires_in']),
    if (data.containsKey('expires_in_days'))
      'expires_in_days': _toInt(data['expires_in_days']),
    if (data.containsKey('recent_media'))
      'recent_media': (data['recent_media'] is List)
          ? List<Map<String, dynamic>>.from(
              (data['recent_media'] as List).map(
                (e) => Map<String, dynamic>.from(e as Map),
              ),
            )
          : <Map<String, dynamic>>[],
  };
}

// ==================== YOUTUBE ====================
Map<String, dynamic> normalizeYouTube(Map<String, dynamic> data) {
  return {
    'id': _toString(data['id']),
    'username': _toString(data['username']),
    'full_name': _toString(data['full_name'] ?? data['title']),
    'url': _toString(data['url']),
    'profile_image_url': _toString(data['profile_image_url']),
    'followers': _toInt(data['followers'] ?? data['subscriberCount']),
    'viewCount': _toInt(data['viewCount']),
    'mediaCount': _toInt(data['mediaCount'] ?? data['videoCount']),
    'hiddenSubscriberCount': data['hiddenSubscriberCount'] ?? false,
  };
}

// ==================== TWITTER ====================
Map<String, dynamic> normalizeTwitter(Map<String, dynamic> data) {
  return {
    'id': _toString(data['id']),
    'full_name': _toString(data['full_name'] ?? data['name']),
    'username': _toString(data['username']),
    'profile_image_url': _toString(data['profile_image_url']),
    'url': _toString(
      data['url'],
      defaultValue: 'https://twitter.com/${data['username'] ?? ''}',
    ),
    'followers': _toInt(data['followers']),
    'following': _toInt(data['following']),
    'likes_count': _toInt(data['likes_count']),
    'listed_count': _toInt(data['listed_count']),
    'mediaCount': _toInt(data['mediaCount']),
    'tweet_count': _toInt(data['tweet_count']),
  };
}

// ==================== SPOTIFY ====================
Map<String, dynamic> normalizeSpotify(Map<String, dynamic> data) {
  return {
    'username': _toString(data['username'] ?? data['display_name']),
    'email': _toString(data['email']),
    'followers': _toInt(data['followers']),
    'pais': _toString(data['pais'] ?? data['country']),
    'plan': _toString(data['plan'] ?? data['product']),
    'profile_image_url': _toString(data['profile_image_url']),
    'url': _toString(data['url'] ?? data['external_urls']?['spotify']),

    // Campos OAuth
    if (data.containsKey('access_token'))
      'access_token': _toString(data['access_token']),
    if (data.containsKey('refresh_token'))
      'refresh_token': _toString(data['refresh_token']),
  };
}

// ==================== FACEBOOK ====================
Map<String, dynamic> normalizeFacebook(Map<String, dynamic> data) {
  return {
    'id': _toString(data['id']),
    'username': _toString(data['username'] ?? data['name']),
    'email': _toString(data['email']),
    'profile_image_url': _toString(data['profile_image_url']),
    'url': _toString(
      data['url'],
      defaultValue: 'https://www.facebook.com/${data['id'] ?? ''}',
    ),
    'followers': _toInt(data['followers']),

    // Páginas asociadas
    if (data.containsKey('pages')) 'pages': data['pages'],
  };
}

// ==================== LINKEDIN ====================
Map<String, dynamic> normalizeLinkedIn(Map<String, dynamic> data) {
  return {
    'id': _toString(data['id']),
    'url': _toString(data['url']),
    'username': _toString(data['username']),
    'full_name': _toString(data['full_name']),
    'headline': _toString(data['headline']),
    'profile_image_url': _toString(data['profile_image_url']),
    'connections': _toInt(data['connections']),
    'followers': _toInt(data['followers']),
    'location': _toString(data['location']),
    'about': _toString(data['about']),

    // Datos opcionales
    if (data.containsKey('current_company'))
      'current_company': _toString(data['current_company']),
    if (data.containsKey('current_position'))
      'current_position': _toString(data['current_position']),
  };
}

// ==================== TWITCH ====================
Map<String, dynamic> normalizeTwitch(Map<String, dynamic> data) {
  return {
    'username': _toString(data['username']),
    'followers': _toInt(data['followers']),
    'profile_image_url': _toString(data['profile_image_url']),
    'url': _toString(
      data['url'],
      defaultValue: 'https://www.twitch.tv/${data['username'] ?? ''}',
    ),
  };
}

// ==================== KICK ====================
Map<String, dynamic> normalizeKick(Map<String, dynamic> data) {
  return {
    'username': _toString(data['username']),
    'followers': _toInt(data['followers']),
    'profile_image_url': _toString(data['profile_image_url']),
    'url': _toString(
      data['url'],
      defaultValue: 'https://kick.com/${data['username'] ?? ''}',
    ),
  };
}

// ==================== TROVO ====================
Map<String, dynamic> normalizeTrovo(Map<String, dynamic> data) {
  return {
    'username': _toString(data['username']),
    'followers': _toInt(data['followers']),
    'profile_image_url': _toString(data['profile_image_url']),
    'url': _toString(
      data['url'],
      defaultValue: 'https://trovo.live/s/${data['username'] ?? ''}',
    ),
  };
}

// ==================== PINTEREST ====================
Map<String, dynamic> normalizePinterest(Map<String, dynamic> data) {
  return {
    'username': _toString(data['username']),
    'followers': _toInt(data['followers']),
    'following': _toInt(data['following']),
    'profile_image_url': _toString(data['profile_image_url']),
    'url': _toString(
      data['url'],
      defaultValue: 'https://www.pinterest.com/${data['username'] ?? ''}',
    ),
    'bio': _toString(data['bio']),
  };
}

// ==================== REDDIT ====================
Map<String, dynamic> normalizeReddit(Map<String, dynamic> data) {
  return {
    'username': _toString(data['username']),
    'followers': _toInt(data['followers'] ?? data['subscribers']),
    'profile_image_url': _toString(
      data['profile_image_url'] ?? data['icon_img'],
    ),
    'url': _toString(
      data['url'],
      defaultValue: 'https://www.reddit.com/user/${data['username'] ?? ''}',
    ),
    'karma': _toInt(data['karma'] ?? data['total_karma']),
  };
}

// ==================== THREADS ====================
Map<String, dynamic> normalizeThreads(Map<String, dynamic> data) {
  return {
    'username': _toString(data['username']),
    'followers': _toInt(data['followers']),
    'following': _toInt(data['following']),
    'profile_image_url': _toString(data['profile_image_url']),
    'url': _toString(
      data['url'],
      defaultValue: 'https://www.threads.net/@${data['username'] ?? ''}',
    ),
    'bio': _toString(data['bio']),
  };
}

// ==================== SOUNDCLOUD ====================
Map<String, dynamic> normalizeSoundCloud(Map<String, dynamic> data) {
  return {
    'username': _toString(data['username']),
    'followers': _toInt(data['followers']),
    'following': _toInt(data['following']),
    'profile_image_url': _toString(
      data['profile_image_url'] ?? data['avatar_url'],
    ),
    'url': _toString(
      data['url'],
      defaultValue: 'https://soundcloud.com/${data['username'] ?? ''}',
    ),
    'track_count': _toInt(data['track_count']),
  };
}

// ==================== DISCORD ====================
Map<String, dynamic> normalizeDiscord(Map<String, dynamic> data) {
  return {
    'username': _toString(data['username']),
    'discriminator': _toString(data['discriminator']),
    'profile_image_url': _toString(data['profile_image_url'] ?? data['avatar']),
    'url': _toString(data['url']),
    'id': _toString(data['id']),
  };
}

// ==================== SNAPCHAT ====================
Map<String, dynamic> normalizeSnapchat(Map<String, dynamic> data) {
  return {
    'username': _toString(data['username']),
    'profile_image_url': _toString(
      data['profile_image_url'] ?? data['bitmoji_avatar'],
    ),
    'url': _toString(
      data['url'],
      defaultValue: 'https://www.snapchat.com/add/${data['username'] ?? ''}',
    ),
    'display_name': _toString(data['display_name']),
  };
}

// ==================== WEBSITES & STORES ====================

Map<String, dynamic> normalizeWebsite(Map<String, dynamic> data) {
  return {
    'url': _toString(data['url']),
    'type': _toString(data['type'], defaultValue: 'website'),
    'name': _toString(data['name']),
  };
}

Map<String, dynamic> normalizeShopify(Map<String, dynamic> data) {
  return {
    'url': _toString(data['url']),
    'type': _toString(data['type'], defaultValue: 'shopify'),
    'store_name': _toString(data['store_name']),
  };
}

Map<String, dynamic> normalizeWooCommerce(Map<String, dynamic> data) {
  return {
    'url': _toString(data['url']),
    'type': _toString(data['type'], defaultValue: 'woocommerce'),
    'store_name': _toString(data['store_name']),
  };
}

Map<String, dynamic> normalizeEtsy(Map<String, dynamic> data) {
  return {
    'url': _toString(data['url']),
    'type': _toString(data['type'], defaultValue: 'etsy'),
    'shop_name': _toString(data['shop_name']),
    'username': _toString(data['username'] ?? data['shop_name']),
  };
}

// ==================== MESSAGING ====================

Map<String, dynamic> normalizeWhatsApp(Map<String, dynamic> data) {
  return {
    'phone': _toString(data['phone']),
    'type': _toString(data['type'], defaultValue: 'whatsapp'),
    'url': _toString(
      data['url'],
      defaultValue: 'https://wa.me/${data['phone'] ?? ''}',
    ),
  };
}

Map<String, dynamic> normalizeTelegram(Map<String, dynamic> data) {
  final hasPhone = data.containsKey('phone') && data['phone'] != null;
  final hasUsername = data.containsKey('username') && data['username'] != null;

  return {
    if (hasPhone) 'phone': _toString(data['phone']),
    if (hasUsername) 'username': _toString(data['username']),
    'type': _toString(data['type'], defaultValue: 'telegram'),
    'url': _toString(
      data['url'],
      defaultValue: hasUsername
          ? 'https://t.me/${data['username']}'
          : 'https://t.me/${data['phone'] ?? ''}',
    ),
  };
}
