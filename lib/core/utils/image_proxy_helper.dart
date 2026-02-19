import 'package:flutter/foundation.dart' show kIsWeb;

/// Helper class to handle image URLs with CORS proxy for web
class ImageProxyHelper {
  /// Proxy service to bypass CORS restrictions on web
  static const String _proxyUrl = 'https://images.weserv.nl/';

  /// Get the appropriate image URL based on platform
  /// For web: uses proxy to avoid CORS issues
  /// For mobile: returns original URL (unchanged)
  static String getProxiedUrl(String imageUrl) {
    // IMPORTANT: Only apply proxy on web platform
    if (!kIsWeb) {
      // On mobile (iOS/Android), ALWAYS return the original URL
      // Mobile apps don't have CORS restrictions
      return imageUrl;
    }

    // On web only: check if it's an external URL that might have CORS issues
    if (_needsProxy(imageUrl)) {
      final proxiedUrl = '$_proxyUrl?url=${Uri.encodeComponent(imageUrl)}';
      // Debug: Uncomment to see which URLs are being proxied
      // debugPrint('🌐 Proxying URL on web: $imageUrl -> $proxiedUrl');
      return proxiedUrl;
    }

    return imageUrl;
  }

  /// Check if URL needs proxy (external URLs like Instagram, Facebook, etc.)
  static bool _needsProxy(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false; // Not a network URL
    }

    // List of domains that typically have CORS issues
    final corsRestrictedDomains = [
      'cdninstagram.com',
      'fbcdn.net',
      'instagram.com',
      'facebook.com',
      'scontent',
      'twimg.com',
      'twitter.com',
      'x.com',
      'licdn.com', // LinkedIn
      'linkedin.com',
      'pinimg.com', // Pinterest
      'tiktokcdn.com', // TikTok
      'whatsapp.net', // WhatsApp
      'ytimg.com', // YouTube thumbnails
      'lh3.googleusercontent.com', // Google profile images
    ];

    final lowerUrl = url.toLowerCase();
    return corsRestrictedDomains.any((domain) => lowerUrl.contains(domain));
  }

  /// Get proxied URL with additional options
  /// [width] - resize width
  /// [height] - resize height
  /// [fit] - fit mode (cover, contain, fill, inside, outside)
  static String getProxiedUrlWithOptions({
    required String imageUrl,
    int? width,
    int? height,
    String? fit,
  }) {
    if (!kIsWeb || !_needsProxy(imageUrl)) {
      return imageUrl;
    }

    final params = <String>[];
    params.add('url=${Uri.encodeComponent(imageUrl)}');

    if (width != null) params.add('w=$width');
    if (height != null) params.add('h=$height');
    if (fit != null) params.add('fit=$fit');

    return '$_proxyUrl?${params.join('&')}';
  }
}
