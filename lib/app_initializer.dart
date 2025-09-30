import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/presentation/register/chat/components/chat_operation/chat_input/audio_recorder_manager.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:permission_handler/permission_handler.dart';
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

/// Widget que inicializa permisos/servicios antes de mostrar la app
class AppInitializer extends StatefulWidget {
  final Widget Function(BuildContext context, AppInitResult? result) builder;

  const AppInitializer({super.key, required this.builder});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer>
    with WidgetsBindingObserver {
  AppInitResult? _result;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _runInit() async {
    // 1) Pedir permiso de microphone
    final micStatus = await Permission.microphone.request();
    final microphoneGranted = micStatus.isGranted;

    // 2) Pedir permiso de ubicación (fine)
    final locStatus = await Permission.locationWhenInUse.request();
    final locationGranted = locStatus.isGranted;

    // 3) Si el usuario no concedió permiso de ubicación, puedes intentar solicitar el servicio
    LocationDTO? locationDto;
    if (locationGranted) {
      try {
        // Llama a tu LocationService para obtener city/state/country
        final svc = LocationService();
        locationDto = await svc.initAndFetchAddress();
      } catch (e) {
        // manejar error (log, fallback)
        debugPrint('Error al obtener ubicación: $e');
      }
    }

    // 4) Inicializar AudioRecorderManager y guardarlo en un singleton o provider
    final audioManager = AudioRecorderManager(
      onStateChanged: () {
        // si quieres, notifica a un Bloc o a un provider.
      },
    );
    // No arrancamos a grabar; sólo instanciamos y preparamos.
    // Si quieres preparar reproductor con un archivo por defecto, hazlo aquí.

    // Opcional: si quieres exponer audioManager globalmente, usa provider/get_it/bloc.

    // 5) Guardamos el resultado
    final result = AppInitResult(
      location: locationDto,
      microphoneGranted: microphoneGranted,
      locationGranted: locationGranted,
    );

    // Actualiza el estado en la UI principal
    if (!mounted) return;
    setState(() {
      _result = result;
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mientras inicializa, podes mostrar splash simple
    if (!_initialized) {
      return const Material(child: Center(child: CircularProgressIndicator()));
    }

    // Cuando ya inicializó, delega al builder para mostrar la app real (router)
    return widget.builder(context, _result);
  }
}
