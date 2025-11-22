// lib/features/auth/data/network_config.dart

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

  const NetworkConfig({
    required this.name,
    required this.displayName,
    required this.iconPath,
    required this.capability,
    this.isEnabled = true,
  });

  bool get supportsOAuth =>
      capability == NetworkAuthCapability.oauth ||
      capability == NetworkAuthCapability.both;

  bool get supportsManual =>
      capability == NetworkAuthCapability.manual ||
      capability == NetworkAuthCapability.both;
}

class SocialNetworks {
  // Configuración de capacidades por red (OAuth, Manual, o Ambos)
  static const Map<String, NetworkAuthCapability> _capabilities = {
    "tiktok": NetworkAuthCapability.manual,
    "instagram": NetworkAuthCapability.both,
    "facebook": NetworkAuthCapability.oauth,
    "youtube": NetworkAuthCapability.manual,
    "spotify": NetworkAuthCapability.oauth,
    "twitter": NetworkAuthCapability.oauth,
    "telegram": NetworkAuthCapability.manual,
    "whatsapp": NetworkAuthCapability.manual,
    "pinterest": NetworkAuthCapability.manual,
    "linkedin": NetworkAuthCapability.manual,
    "paypal": NetworkAuthCapability.manual,
    "xbox": NetworkAuthCapability.manual,
    "other": NetworkAuthCapability.manual,
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

      configMap[networkLower] = NetworkConfig(
        name: networkLower,
        displayName: network,
        iconPath: iconPath,
        capability: capability,
        isEnabled: true, // Si está en socials, está habilitada
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

      return NetworkConfig(
        name: networkLower,
        displayName: network,
        iconPath: iconPath,
        capability: capability,
        isEnabled: true,
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
