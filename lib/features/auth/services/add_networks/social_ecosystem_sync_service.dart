import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:migozz_app/core/config/api/api_config.dart';

/// Servicio para sincronizar datos de redes sociales
/// Permite sincronización manual y verifica el estado de sincronización
class SocialEcosystemSyncService {
  /// Sincroniza TODOS los usuarios (ejecutado por Cloud Scheduler automáticamente)
  /// Normalmente NO se llama desde la app, pero está disponible para testing
  Future<Map<String, dynamic>> syncAllUsers() async {
    final uri = Uri.parse('${ApiConfig.apiFuctions}/sync/all-users');

    debugPrint('🔄 [SyncService] Sincronizando todos los usuarios...');

    try {
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [SyncService] Sincronización completada');
        return Map<String, dynamic>.from(data);
      } else {
        debugPrint('❌ [SyncService] Error: ${response.body}');
        throw Exception('Error en sincronización: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [SyncService] Exception: $e');
      rethrow;
    }
  }

  /// Sincroniza las redes sociales de un usuario específico
  /// Útil para:
  /// - Botón "Actualizar ahora" en el perfil
  /// - Sincronización manual del usuario
  /// - Testing
  Future<Map<String, dynamic>> syncUserNetworks(String userId) async {
    final uri = Uri.parse('${ApiConfig.apiFuctions}/sync/user/$userId');

    debugPrint('🔄 [SyncService] Sincronizando redes de usuario: $userId');

    try {
      final response = await http.post(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [SyncService] Usuario sincronizado exitosamente');
        return Map<String, dynamic>.from(data);
      } else {
        debugPrint('❌ [SyncService] Error: ${response.body}');
        throw Exception('Error sincronizando usuario');
      }
    } catch (e) {
      debugPrint('❌ [SyncService] Exception: $e');
      rethrow;
    }
  }

  /// Verifica si un usuario necesita sincronización
  /// Retorna true si han pasado más de SYNC_INTERVAL_DAYS desde la última sincronización
  bool needsSyncByDays(DateTime? lastSync, {int intervalDays = 15}) {
    if (lastSync == null) {
      return true; // Nunca se ha sincronizado
    }

    final now = DateTime.now();
    final daysSince = now.difference(lastSync).inDays;

    return daysSince >= intervalDays;
  }

  /// Obtiene información de sincronización formateada para mostrar al usuario
  String getLastSyncFormattedText(DateTime? lastSync) {
    if (lastSync == null) {
      return 'Nunca sincronizado';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inSeconds < 60) {
      return 'Hace unos segundos';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minuto(s)';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} hora(s)';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} día(s)';
    } else if (difference.inDays < 30) {
      return 'Hace ${(difference.inDays / 7).toStringAsFixed(0)} semana(s)';
    } else {
      return 'Hace ${(difference.inDays / 30).toStringAsFixed(0)} mes(es)';
    }
  }

  /// Obtiene un mensaje amigable sobre el estado de sincronización
  String getSyncStatusMessage(DateTime? lastSync, {int intervalDays = 15}) {
    if (lastSync == null) {
      return '📊 Datos no sincronizados aún';
    }

    final daysSince = DateTime.now().difference(lastSync).inDays;
    final daysRemaining = intervalDays - daysSince;

    if (daysRemaining <= 0) {
      return '🔄 Necesita actualización';
    } else if (daysRemaining <= 3) {
      return '⏰ Se actualizará en $daysRemaining día(s)';
    } else {
      return '✅ Sincronizado hace $daysSince día(s)';
    }
  }

  /// Obtiene el estado del servicio de sincronización
  Future<Map<String, dynamic>> getSyncStatus() async {
    final uri = Uri.parse('${ApiConfig.apiFuctions}/sync/status');

    debugPrint('🔍 [SyncService] Obteniendo estado del servicio...');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ [SyncService] Estado obtenido');
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Error obteniendo estado');
      }
    } catch (e) {
      debugPrint('❌ [SyncService] Exception: $e');
      rethrow;
    }
  }

  /// Convierte el intervalo de días a texto legible
  String formatIntervalDays(int days) {
    if (days == 1) return 'diariamente';
    if (days == 7) return 'semanalmente';
    if (days == 30) return 'mensualmente';
    if (days == 15) return 'cada 15 días';
    return 'cada $days días';
  }
}
