import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as loc; // rename para evitar conflicto
import 'package:geolocator/geolocator.dart';
import 'package:migozz_app/core/config/api/api_config.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/location_dto.dart';

class LocationService {
  final loc.Location _location = loc.Location();

  Future<LocationDTO?> initAndFetchAddress({required String lang}) async {
    double? lat;
    double? lon;

    try {
      if (kIsWeb) {
        // WEB: usar Geolocator
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          debugPrint('❌ Servicios de ubicación deshabilitados en web.');
          return null;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            debugPrint('❌ Permiso de ubicación denegado en web.');
            return null;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          debugPrint(
            '🚫 Permiso de ubicación denegado permanentemente en web.',
          );
          return null;
        }

        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        lat = pos.latitude;
        lon = pos.longitude;
      } else {
        // MÓVIL: usar paquete location
        debugPrint('📍 [LocationService] Iniciando obtención de ubicación móvil...');

        bool serviceEnabled = await _location.serviceEnabled();
        debugPrint('📍 [LocationService] Servicio habilitado: $serviceEnabled');

        if (!serviceEnabled) {
          serviceEnabled = await _location.requestService();
          debugPrint('📍 [LocationService] Servicio después de solicitar: $serviceEnabled');
          if (!serviceEnabled) {
            debugPrint('❌ [LocationService] Servicio de ubicación no disponible');
            return null;
          }
        }

        var permissionGranted = await _location.hasPermission();
        debugPrint('📍 [LocationService] Permiso actual: $permissionGranted');

        if (permissionGranted == loc.PermissionStatus.denied) {
          permissionGranted = await _location.requestPermission();
          debugPrint('📍 [LocationService] Permiso después de solicitar: $permissionGranted');
          if (permissionGranted != loc.PermissionStatus.granted) {
            debugPrint('❌ [LocationService] Permiso de ubicación denegado');
            return null;
          }
        }

        final locationData = await _location.getLocation();
        lat = locationData.latitude;
        lon = locationData.longitude;
        debugPrint('📍 [LocationService] Coordenadas obtenidas: lat=$lat, lon=$lon');
      }

      if (lat == null || lon == null) {
        debugPrint('❌ [LocationService] Coordenadas nulas: lat=$lat, lon=$lon');
        return null;
      }

      // Llamar a tu API
      debugPrint('📍 [LocationService] Llamando API con lat=$lat, lon=$lon, lang=$lang');
      final uri = Uri.parse(
        "${ApiConfig.apiBase}/users/location"
        "?lat=$lat"
        "&lon=$lon"
        "&lang=${lang == 'es' ? 'es' : 'en'}",
      );

      final response = await http.get(uri);
      debugPrint('📍 [LocationService] API response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint("⚠️ Error API (${response.statusCode}): ${response.body}");
        return null;
      }

      if (!response.body.trim().startsWith('{')) {
        debugPrint("❌ API devolvió HTML en vez de JSON");
        return null;
      }

      final data = jsonDecode(response.body);
      debugPrint('📍 [LocationService] API data: city=${data['city']}, state=${data['state']}, country=${data['country']}');

      final locationDto = LocationDTO(
        country: data['country'] ?? '',
        state: data['state'] ?? '',
        city: data['city'] ?? '',
        lat: lat,
        lng: lon,
      );

      debugPrint('📍 [LocationService] LocationDTO creado: ${locationDto.displayName}');
      return locationDto;
    } catch (e) {
      debugPrint('❌ Error en LocationService: $e');
      return null;
    }
  }
}
