import 'package:flutter/material.dart';

/// Keys globales para los elementos del tutorial del perfil principal
/// Organizado según el orden de pasos definido en Tutorial_Profile.md
class ProfileTutorialKeys {
  // === Navegación inferior (Bottom Nav) - Pasos 1.x ===
  /// Paso 1 - Home: Icono de inicio
  final homeNavKey = GlobalKey(debugLabel: 'homeNavKey');

  /// Paso 1.1 - Search: Icono de búsqueda
  final searchNavKey = GlobalKey(debugLabel: 'searchNavKey');

  /// Paso 1.2 - Messages: Icono de mensajes (centro)
  final messagesNavKey = GlobalKey(debugLabel: 'messagesNavKey');

  /// Paso 1.3 - Stats: Icono de estadísticas
  final statsNavKey = GlobalKey(debugLabel: 'statsNavKey');

  /// Paso 1.4 - Settings: Icono de configuración
  final settingsNavKey = GlobalKey(debugLabel: 'settingsNavKey');

  // === Contenido del perfil - Pasos 2 a 9 ===

  /// Paso 2 - Linked Networks: Sección de redes vinculadas (fotos e iconos)
  final linkedNetworksKey = GlobalKey(debugLabel: 'linkedNetworksKey');

  /// Paso 3 - Share QR: Botón de compartir QR
  final shareQrKey = GlobalKey(debugLabel: 'shareQrKey');

  /// Paso 4 - Community: Sección de comunidad/seguidores
  final communityKey = GlobalKey(debugLabel: 'communityKey');

  /// Paso 5 - Messages Icon (header): Icono de mensajes en la parte superior
  final messagesHeaderKey = GlobalKey(debugLabel: 'messagesHeaderKey');

  /// Paso 6 - Name Section: Sección de nombre, apodo y botón de audio
  final nameSectionKey = GlobalKey(debugLabel: 'nameSectionKey');

  /// Paso 7 - Notifications: Icono de notificaciones
  final notificationsKey = GlobalKey(debugLabel: 'notificationsKey');

  /// Paso 8 - QR Scanner: Icono del lector de QR
  final qrScannerKey = GlobalKey(debugLabel: 'qrScannerKey');

  /// Paso 9 - Edit Profile: Icono de edición/personalización
  final editProfileKey = GlobalKey(debugLabel: 'editProfileKey');
}
