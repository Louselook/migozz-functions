import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:migozz_app/core/config/api/api_config.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';

class LocationService {
  final Location _location = Location();

  Future<LocationDTO?> initAndFetchAddress() async {
    // Verificar si el servicio de ubicación está habilitado
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return null;
    }

    // Verificar permisos
    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return null;
    }

    // Obtener ubicación actual
    final locationData = await _location.getLocation();
    final lat = locationData.latitude;
    final lon = locationData.longitude;

    if (lat == null || lon == null) return null;

    // Llamar a tu API para obtener city/state/country
    final uri = Uri.parse(
      "${ApiConfig.apiBase}/users/location?lat=$lat&lon=$lon",
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      // throw Exception("Error en la API de ubicación: ${response.body}");
    }

    final data = jsonDecode(response.body);

    return LocationDTO(
      country: data['country'] ?? '',
      state: data['state'] ?? '',
      city: data['city'] ?? '',
      lat: lat,
      lng: lon,
    );
  }
}
