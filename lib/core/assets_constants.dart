class AssetsConstants {
  static const String icons = 'assets/icons';
  static const String socialNetworksIcons = '$icons/social_networks';
  static const String socialBlackWhiteIcons =
      '$socialNetworksIcons/social_black_white_icons';

  static const String shareIcon = '$icons/Share_Icon.svg';
  static const String inboxIcon = '$icons/send.png';
  static const String migozIcon = '$icons/Migozz_Icon.svg';
  static const String placeholderIcon = '$icons/placeholder.svg';

  //black and white icons
  static const String instagramBlackIcon =
      '$socialBlackWhiteIcons/instagram_black.svg';
  static const String youtubeBlackIcon =
      '$socialBlackWhiteIcons/youtube_black.svg';

  static const String tiktokIcon = '$socialBlackWhiteIcons/TiktokIconNegro.svg';
  static const String facebookIcon = '$socialBlackWhiteIcons/FbNegro.svg';
  static const String telegramIcon = '$socialBlackWhiteIcons/TelegramNegro.svg';
  static const String whatsappIcon = '$socialBlackWhiteIcons/WhatsappNegro.svg';
  static const String pinterestIcon =
      '$socialBlackWhiteIcons/PinterestNegro.svg';
  static const String spotifyIcon = '$socialBlackWhiteIcons/SpotifyNegro.svg';
  static const String twitterIcon = '$socialBlackWhiteIcons/TwitterNegro.svg';
  static const String linkedinIcon = '$socialBlackWhiteIcons/LinkedInNe.svg';
}

class SocialIconResolver {
  static const Map<String, String> byKey = {
    'instagram': AssetsConstants.instagramBlackIcon,
    'youtube': AssetsConstants.youtubeBlackIcon,
    'tiktok': AssetsConstants.tiktokIcon,
    'facebook': AssetsConstants.facebookIcon,
    'telegram': AssetsConstants.telegramIcon,
    'whatsapp': AssetsConstants.whatsappIcon,
    'pinterest': AssetsConstants.pinterestIcon,
    'spotify': AssetsConstants.spotifyIcon,
    'twitter': AssetsConstants.twitterIcon,
    'linkedin': AssetsConstants.linkedinIcon,
    'global': AssetsConstants.migozIcon,
  };

  static String? resolve(String value) {
    return byKey[value.toLowerCase().trim()];
  }
}

// DiscordBlanco.svg
