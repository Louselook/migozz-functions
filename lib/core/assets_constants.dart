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
  static const String appleMusicIcon = '$socialBlackWhiteIcons/AppleMNegro.svg';
  static const String deezerIcon = '$socialBlackWhiteIcons/DeezerNegro.svg';
  static const String etsyIcon = '$socialBlackWhiteIcons/EtsyNegro.svg';
  static const String kickIcon = '$socialBlackWhiteIcons/KickNegro.svg';
  static const String redditIcon = '$socialBlackWhiteIcons/RedditNegro.svg';
  static const String snapchatIcon = '$socialBlackWhiteIcons/SnapchatNegro.svg';
  static const String soundCloudIcon =
      '$socialBlackWhiteIcons/SoundCloudNegro.svg';
  static const String shopifyIcon = '$socialBlackWhiteIcons/ShopifyNegro.svg';
  static const String threadsIcon = '$socialBlackWhiteIcons/ThreadsNegro.svg';
  static const String trovoIcon = '$socialBlackWhiteIcons/TrovoNegro.svg';
  static const String twitchIcon = '$socialBlackWhiteIcons/TwitchNegro.svg';
  static const String wooIcon = '$socialBlackWhiteIcons/WooNegro.svg';
  static const String discordIcon = '$socialBlackWhiteIcons/DiscordNegro.svg';
  static const String wrnsitePerIcon =
      '$socialBlackWhiteIcons/WrnsitePerNegro.svg';

  //Wallet and transfer
 
  static const String depositIcon = '$icons/deposit.svg';
  static const String sentIcon = '$icons/fund_transfer.svg';
  static const String walletBuy = '$icons/wallet_buy.svg';
  static const String walletUp = '$icons/wallet_up.svg';
  static const String walletDown = '$icons/wallet_down.svg';
  static const String walletEmpty = '$icons/wallet_empty.svg';
  static const String walletVisa = '$icons/visa.svg';
  static const String walletMaster = '$icons/master_card.svg';
  static const String walletMethods = '$icons/cards_banner.svg';
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
    'applemusic': AssetsConstants.appleMusicIcon,
    'deezer': AssetsConstants.deezerIcon,
    'etsy': AssetsConstants.etsyIcon,
    'kick': AssetsConstants.kickIcon,
    'reddit': AssetsConstants.redditIcon,
    'snapchat': AssetsConstants.snapchatIcon,
    'soundcloud': AssetsConstants.soundCloudIcon,
    'shopify': AssetsConstants.shopifyIcon,
    'threads': AssetsConstants.threadsIcon,
    'trovo': AssetsConstants.trovoIcon,
    'twitch': AssetsConstants.twitchIcon,
    'discord': AssetsConstants.discordIcon,
    'woocommerce': AssetsConstants.wooIcon,
    'enlace': AssetsConstants.wrnsitePerIcon,
    'global': AssetsConstants.migozIcon,
  };

  static String? resolve(String value) {
    return byKey[value.toLowerCase().trim()];
  }
}

// DiscordBlanco.svg
