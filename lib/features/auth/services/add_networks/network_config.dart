// lib/features/auth/services/add_networks/network_config.dart

import 'package:migozz_app/core/components/atomics/network_list.dart';

enum NetworkAuthCapability {
  oauth, // Autenticación con un click (deeplink)
  manual, // Entrada manual (username o link)
  both, // Ambos métodos disponibles
}

class NetworkConfig {
  final String name;
  final String displayName;
  final String iconPath;
  final NetworkAuthCapability capability;
  final bool isEnabled;
  final String? placeholder; // Placeholder para el campo de entrada

  const NetworkConfig({
    required this.name,
    required this.displayName,
    required this.iconPath,
    required this.capability,
    this.isEnabled = true,
    this.placeholder,
  });

  bool get supportsOAuth =>
      capability == NetworkAuthCapability.oauth ||
      capability == NetworkAuthCapability.both;

  bool get supportsManual =>
      capability == NetworkAuthCapability.manual ||
      capability == NetworkAuthCapability.both;
}

class SocialNetworks {
  // Configuración de capacidades por red
  static const Map<String, NetworkAuthCapability> _capabilities = {
    // Social Media
    "tiktok": NetworkAuthCapability.manual,
    // "instagram": NetworkAuthCapability.both,
    "instagram": NetworkAuthCapability.manual,
    // "facebook": NetworkAuthCapability.both,
    "facebook": NetworkAuthCapability.manual,
    "youtube": NetworkAuthCapability.manual,
    "twitter": NetworkAuthCapability.oauth,
    "x": NetworkAuthCapability.oauth,
    "linkedin": NetworkAuthCapability.manual,
    "snapchat": NetworkAuthCapability.manual,
    "pinterest": NetworkAuthCapability.manual,
    "threads": NetworkAuthCapability.manual,
    "reddit": NetworkAuthCapability.manual,

    // Streaming
    "twitch": NetworkAuthCapability.manual,
    "kick": NetworkAuthCapability.manual,
    "trovo": NetworkAuthCapability.manual,

    // Music
    "spotify": NetworkAuthCapability.oauth,
    "applemusic": NetworkAuthCapability.manual,
    "deezer": NetworkAuthCapability.manual,
    "soundcloud": NetworkAuthCapability.manual,

    // Websites & Stores (todos manual)
    "website": NetworkAuthCapability.manual,
    "shopify": NetworkAuthCapability.manual,
    "woocommerce": NetworkAuthCapability.manual,
    "etsy": NetworkAuthCapability.manual,

    // Messaging (todos manual)
    "whatsapp": NetworkAuthCapability.manual,
    "telegram": NetworkAuthCapability.manual,
    "discord": NetworkAuthCapability.manual,

    // Otros
    // "pinterest": NetworkAuthCapability.manual,
    "paypal": NetworkAuthCapability.manual,
    "xbox": NetworkAuthCapability.manual,
    "other": NetworkAuthCapability.manual,
  };

  // Placeholders personalizados por red
  static const Map<String, String> _placeholders = {
    // Social Media
    "tiktok": "Username or URL",
    "instagram": "Username or URL",
    "facebook": "Username or URL",
    "youtube": "Channel name or URL",
    "twitter": "Username",
    "linkedin": "Profile URL",
    "snapchat": "Username",
    "pinterest": "Username",
    "threads": "Username",
    "reddit": "Username",

    // Streaming
    "twitch": "Username or URL",
    "kick": "Username or URL",
    "trovo": "Username or URL",

    // Music
    "spotify": "Profile URL",
    "applemusic": "Profile URL",
    "deezer": "Profile URL",
    "soundcloud": "Profile URL",

    // Websites & Stores
    "website": "Your website URL",
    "shopify": "Your Shopify store URL",
    "woocommerce": "Your WooCommerce store URL",
    "etsy": "Your Etsy shop URL",

    // Messaging
    "whatsapp": "Phone number (with country code)",
    "telegram": "Username or phone number",
    "discord": "Username or URL",
  };

  // Genera configuraciones dinámicamente desde network_list.dart
  static Map<String, NetworkConfig> get configs {
    final Map<String, NetworkConfig> configMap = {};

    for (var network in socials) {
      final networkLower = network.toLowerCase();
      final capability =
          _capabilities[networkLower] ?? NetworkAuthCapability.manual;
      final iconPath =
          iconByLabel[network] ?? 'assets/icons/social_networks/Other.svg';
      final placeholder = _placeholders[networkLower] ?? "Username or URL";

      configMap[networkLower] = NetworkConfig(
        name: networkLower,
        displayName: network,
        iconPath: iconPath,
        capability: capability,
        isEnabled: true,
        placeholder: placeholder,
      );
    }

    return configMap;
  }

  // Lista de redes habilitadas (respeta el orden de socials)
  static List<NetworkConfig> get enabledNetworks {
    return socials.map((network) {
      final networkLower = network.toLowerCase();
      final capability =
          _capabilities[networkLower] ?? NetworkAuthCapability.manual;
      final iconPath =
          iconByLabel[network] ?? 'assets/icons/social_networks/Other.svg';
      final placeholder = _placeholders[networkLower] ?? "Username or URL";

      return NetworkConfig(
        name: networkLower,
        displayName: network,
        iconPath: iconPath,
        capability: capability,
        isEnabled: true,
        placeholder: placeholder,
      );
    }).toList();
  }

  // Obtener configuración por nombre
  static NetworkConfig? getConfig(String name) => configs[name.toLowerCase()];

  // Helper: Verificar si una red está habilitada
  static bool isEnabled(String network) {
    return socials.any((s) => s.toLowerCase() == network.toLowerCase());
  }
}
