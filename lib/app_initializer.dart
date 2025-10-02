import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';

/// Resultado de la inicialización: guarda lo que necesites exponer globalmente
class AppInitResult {
  final LocationDTO? location;
  final bool microphoneGranted;
  final bool locationGranted;

  AppInitResult({
    required this.location,
    required this.microphoneGranted,
    required this.locationGranted,
  });
}

/// Widget que inicializa permisos antes de mostrar la app
class AppInitializer extends StatefulWidget {
  final Widget Function(BuildContext context, AppInitResult? result) builder;

  const AppInitializer({super.key, required this.builder});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  AppInitResult? _result;

  @override
  void initState() {
    super.initState();

    // Inicializa rápido con permisos "simulados" para que la UI se muestre
    _result = AppInitResult(
      location: null,
      microphoneGranted: true,
      locationGranted: true,
    );

    // Pedir permisos en segundo plano
    _runInit();
  }

  Future<void> _runInit() async {
    // 1️⃣ Solicitar permiso de micrófono
    final micStatus = await Permission.microphone.request();
    final microphoneGranted = micStatus.isGranted;

    // 2️⃣ Solicitar permiso de ubicación
    final locStatus = await Permission.locationWhenInUse.request();
    final locationGranted = locStatus.isGranted;

    // Obtener ubicación solo si hay permiso
    LocationDTO? locationDto;
    if (locationGranted) {
      try {
        final svc = LocationService();
        locationDto = await svc.initAndFetchAddress();
      } catch (e) {
        debugPrint('Error al obtener ubicación: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _result = AppInitResult(
        location: locationDto,
        microphoneGranted: microphoneGranted,
        locationGranted: locationGranted,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Muestra la app inmediatamente, el builder recibe los permisos actualizados después
    return widget.builder(context, _result);
  }
}
