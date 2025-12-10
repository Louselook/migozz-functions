// lib/features/auth/services/add_networks/add_network_service_direct.dart

import 'package:flutter/material.dart';

/// Servicio para agregar redes sociales directamente sin scraping
/// Usado para: Websites, Tiendas, Mensajería (WhatsApp, Telegram)
class AddNetworkServiceDirect {
  /// Crear datos de perfil directamente desde input del usuario
  /// No hace llamadas a APIs, solo valida y estructura los datos
  Future<Map<String, dynamic>> createDirectProfile({
    required String network,
    required String input,
  }) async {
    debugPrint('🔗 [$network] Creating direct profile with input: $input');

    try {
      final profileData = _buildProfileData(network, input);
      debugPrint('✅ [$network] Direct profile created successfully');
      return profileData;
    } catch (e) {
      debugPrint('❌ [$network] Error creating direct profile: $e');
      rethrow;
    }
  }

  /// Construir datos del perfil según el tipo de red
  Map<String, dynamic> _buildProfileData(String network, String input) {
    switch (network.toLowerCase()) {
      // ==================== WEBSITES & STORES ====================
      case 'website':
        return _buildWebsiteProfile(input);
      case 'shopify':
        return _buildShopifyProfile(input);
      case 'woocommerce':
        return _buildWooCommerceProfile(input);
      case 'etsy':
        return _buildEtsyProfile(input);

      // ==================== MESSAGING ====================
      case 'whatsapp':
        return _buildWhatsAppProfile(input);
      case 'telegram':
        return _buildTelegramProfile(input);

      default:
        throw Exception('Red social no soportada: $network');
    }
  }

  // ==================== WEBSITE BUILDERS ====================

  Map<String, dynamic> _buildWebsiteProfile(String url) {
    final cleanUrl = _cleanUrl(url);
    return {
      'url': cleanUrl,
      'type': 'website',
      'name': _extractDomainName(cleanUrl),
    };
  }

  Map<String, dynamic> _buildShopifyProfile(String url) {
    final cleanUrl = _cleanUrl(url);
    return {
      'url': cleanUrl,
      'type': 'shopify',
      'store_name': _extractDomainName(cleanUrl),
    };
  }

  Map<String, dynamic> _buildWooCommerceProfile(String url) {
    final cleanUrl = _cleanUrl(url);
    return {
      'url': cleanUrl,
      'type': 'woocommerce',
      'store_name': _extractDomainName(cleanUrl),
    };
  }

  Map<String, dynamic> _buildEtsyProfile(String url) {
    final cleanUrl = _cleanUrl(url);
    final shopName = _extractEtsyShopName(cleanUrl);
    return {
      'url': cleanUrl,
      'type': 'etsy',
      'shop_name': shopName,
      'username': shopName,
    };
  }

  // ==================== MESSAGING BUILDERS ====================

  Map<String, dynamic> _buildWhatsAppProfile(String input) {
    final cleanNumber = _cleanPhoneNumber(input);
    return {
      'phone': cleanNumber,
      'type': 'whatsapp',
      'url': 'https://wa.me/$cleanNumber',
    };
  }

  Map<String, dynamic> _buildTelegramProfile(String input) {
    // Si es un número, crear URL con número
    if (_isPhoneNumber(input)) {
      final cleanNumber = _cleanPhoneNumber(input);
      return {
        'phone': cleanNumber,
        'type': 'telegram',
        'url': 'https://t.me/$cleanNumber',
      };
    }

    // Si es un username
    final cleanUsername = input.replaceFirst('@', '').trim();
    return {
      'username': cleanUsername,
      'type': 'telegram',
      'url': 'https://t.me/$cleanUsername',
    };
  }

  // ==================== HELPERS ====================

  /// Limpiar URL (agregar https:// si falta)
  String _cleanUrl(String url) {
    var cleaned = url.trim();

    // Si no tiene protocolo, agregar https://
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'https://$cleaned';
    }

    // Remover slash final si existe
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }

    return cleaned;
  }

  /// Extraer nombre de dominio de una URL
  String _extractDomainName(String url) {
    try {
      final uri = Uri.parse(url);
      var domain = uri.host;

      // Remover www. si existe
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }

      // Remover extensión (.com, .net, etc.)
      final parts = domain.split('.');
      if (parts.length > 1) {
        return parts[0];
      }

      return domain;
    } catch (e) {
      return url;
    }
  }

  /// Extraer nombre de tienda de Etsy
  String _extractEtsyShopName(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // URL de Etsy: https://www.etsy.com/shop/ShopName
      if (pathSegments.length >= 2 && pathSegments[0] == 'shop') {
        return pathSegments[1];
      }

      return _extractDomainName(url);
    } catch (e) {
      return _extractDomainName(url);
    }
  }

  /// Limpiar número de teléfono (remover espacios, guiones, paréntesis)
  String _cleanPhoneNumber(String phone) {
    var cleaned = phone.trim();

    // Remover caracteres no numéricos excepto el + inicial
    if (cleaned.startsWith('+')) {
      cleaned = '+${cleaned.substring(1).replaceAll(RegExp(r'[^\d]'), '')}';
    } else {
      cleaned = cleaned.replaceAll(RegExp(r'[^\d]'), '');
    }

    return cleaned;
  }

  /// Verificar si el input es un número de teléfono
  bool _isPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    // Si tiene más de 7 dígitos y empieza con + o número, es teléfono
    return cleaned.length >= 7 && RegExp(r'^[\d+]').hasMatch(cleaned);
  }

  // ==================== VALIDATION ====================

  /// Validar URL
  bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(_cleanUrl(url));
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Validar número de teléfono
  bool isValidPhoneNumber(String phone) {
    final cleaned = _cleanPhoneNumber(phone);
    // Debe tener entre 7 y 15 dígitos
    return cleaned.length >= 7 && cleaned.length <= 15;
  }
}
