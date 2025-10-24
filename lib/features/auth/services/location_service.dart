import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as loc; // rename para evitar conflicto
import 'package:geolocator/geolocator.dart';
import 'package:migozz_app/core/config/api/api_config.dart';
import 'package:migozz_app/features/auth/data/domain/models/location_dto.dart';

class LocationService {
  final loc.Location _location = loc.Location();

  Future<LocationDTO?> initAndFetchAddress() async {
    double? lat;
    double? lon;

    try {
      if (kIsWeb) {
        // 🌐 WEB: usar Geolocator
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
          debugPrint('🚫 Permiso de ubicación denegado permanentemente en web.');
          return null;
        }

        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        lat = pos.latitude;
        lon = pos.longitude;
      } else {
        // 📱 MÓVIL: usar paquete location
        bool serviceEnabled = await _location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await _location.requestService();
          if (!serviceEnabled) return null;
        }

        var permissionGranted = await _location.hasPermission();
        if (permissionGranted == loc.PermissionStatus.denied) {
          permissionGranted = await _location.requestPermission();
          if (permissionGranted != loc.PermissionStatus.granted) return null;
        }

        final locationData = await _location.getLocation();
        lat = locationData.latitude;
        lon = locationData.longitude;
      }

      if (lat == null || lon == null) return null;

      // 🔗 Llamar a tu API
      final uri = Uri.parse(
        "${ApiConfig.apiBase}/users/location?lat=$lat&lon=$lon",
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        debugPrint("⚠️ Error al obtener datos de la API: ${response.body}");
      }

      final data = jsonDecode(response.body);

      return LocationDTO(
        country: data['country'] ?? '',
        state: data['state'] ?? '',
        city: data['city'] ?? '',
        lat: lat,
        lng: lon,
      );
    } catch (e) {
      debugPrint('❌ Error en LocationService: $e');
      return null;
    }
  }
}
