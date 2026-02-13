import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as loc; // rename para evitar conflicto
import 'package:geolocator/geolocator.dart';
import 'package:migozz_app/core/config/api/api_config.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/location_dto.dart';

class LocationService {
  final loc.Location _location = loc.Location();

  static const int _maxCoordAttempts = 3;
  static const int _maxApiAttempts = 2;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  bool _coordsLookInvalid(double? lat, double? lon) {
    if (lat == null || lon == null) return true;
    // Some providers may briefly return 0/0 right after permission grant.
    if (lat.abs() < 0.0001 && lon.abs() < 0.0001) return true;
    return false;
  }

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

        for (var attempt = 1; attempt <= _maxCoordAttempts; attempt++) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          lat = pos.latitude;
          lon = pos.longitude;
          if (!_coordsLookInvalid(lat, lon)) break;
          debugPrint(
            '⚠️ [LocationService] Coordenadas web inválidas (attempt $attempt/$_maxCoordAttempts): lat=$lat lon=$lon',
          );
          if (attempt < _maxCoordAttempts) {
            await Future.delayed(_retryDelay);
          }
        }
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

        for (var attempt = 1; attempt <= _maxCoordAttempts; attempt++) {
          final locationData = await _location.getLocation();
          lat = locationData.latitude;
          lon = locationData.longitude;
          debugPrint(
            '📍 [LocationService] Coordenadas obtenidas (attempt $attempt/$_maxCoordAttempts): lat=$lat, lon=$lon',
          );
          if (!_coordsLookInvalid(lat, lon)) break;
          if (attempt < _maxCoordAttempts) {
            await Future.delayed(_retryDelay);
          }
        }
      }

      if (_coordsLookInvalid(lat, lon)) {
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

      Map<String, dynamic>? data;
      int? status;
      String? rawBody;
      for (var attempt = 1; attempt <= _maxApiAttempts; attempt++) {
        final response = await http.get(uri);
        status = response.statusCode;
        rawBody = response.body;
        debugPrint(
          '📍 [LocationService] API response status (attempt $attempt/$_maxApiAttempts): $status',
        );

        if (status != 200) {
          debugPrint("⚠️ Error API ($status): $rawBody");
          if (attempt < _maxApiAttempts) {
            await Future.delayed(_retryDelay);
            continue;
          }
          return null;
        }

        if (!rawBody.trim().startsWith('{')) {
          debugPrint("❌ API devolvió HTML en vez de JSON");
          if (attempt < _maxApiAttempts) {
            await Future.delayed(_retryDelay);
            continue;
          }
          return null;
        }

        final decoded = jsonDecode(rawBody);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else {
          debugPrint('❌ API JSON inesperado: ${decoded.runtimeType}');
          if (attempt < _maxApiAttempts) {
            await Future.delayed(_retryDelay);
            continue;
          }
          return null;
        }

        final city = (data['city'] ?? '').toString().trim();
        final country = (data['country'] ?? '').toString().trim();
        debugPrint(
          '📍 [LocationService] API data: city=${data['city']}, state=${data['state']}, country=${data['country']}',
        );
        if (city.isNotEmpty && country.isNotEmpty) {
          break;
        }

        debugPrint(
          '⚠️ [LocationService] API devolvió ciudad/país vacío (attempt $attempt/$_maxApiAttempts).',
        );
        if (attempt < _maxApiAttempts) {
          await Future.delayed(_retryDelay);
          continue;
        }
      }

      if (data == null) return null;

      final locationDto = LocationDTO(
        country: (data['country'] ?? '').toString(),
        state: (data['state'] ?? '').toString(),
        city: (data['city'] ?? '').toString(),
        lat: lat!,
        lng: lon!,
      );

      debugPrint('📍 [LocationService] LocationDTO creado: ${locationDto.displayName}');
      // Si la API no pudo resolver ciudad/país, tratar como fallo.
      if (!locationDto.hasCityAndCountry) {
        debugPrint('❌ [LocationService] LocationDTO sin ciudad/país.');
        return null;
      }
      return locationDto;
    } catch (e) {
      debugPrint('❌ Error en LocationService: $e');
      return null;
    }
  }
}
