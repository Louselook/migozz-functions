import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/splash/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/auth/models/location_dto.dart';

/// Resultado de inicialización global
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

class AppInitializer extends StatefulWidget {
  final Widget Function(BuildContext context, AppInitResult? result) builder;

  const AppInitializer({super.key, required this.builder});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer>
    with WidgetsBindingObserver {
  AppInitResult? _result;

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationStatus();
    }
  }

  Future<void> _checkLocationStatus() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted && mounted) {
      await _runInit();
    }
  }

  Future<void> _runInit() async {
    // 1️⃣ Permiso de micrófono
    final micStatus = await Permission.microphone.request();
    final microphoneGranted = micStatus.isGranted;

    bool locationGranted = false;
    LocationDTO? locationDto;

    // 🔁 Bucle hasta obtener permiso válido
    while (!locationGranted && mounted) {
      final locStatus = await Permission.locationWhenInUse.request();

      bool permanentlyDenied = false;

      switch (locStatus) {
        case PermissionStatus.granted:
        case PermissionStatus.limited: // iOS: solo esta vez
          locationGranted = true;
          break;
        case PermissionStatus.denied:
          locationGranted = false;
          break;
        case PermissionStatus.permanentlyDenied:
          locationGranted = false;
          permanentlyDenied = true;
          break;
        default:
          break;
      }

      if (locationGranted) {
        try {
          final svc = LocationService();
          locationDto = await svc.initAndFetchAddress();
        } catch (e) {
          debugPrint('Error al obtener ubicación: $e');
        }
      } else {
        // Aquí llamamos a la versión "post-frame" del diálogo/modal
        await _showLocationDeniedDialog(permanentlyDenied);
        if (permanentlyDenied) {
          // Abrir ajustes (esto abrirá la pantalla de ajustes del sistema)
          await openAppSettings();
        }
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

  /// Mostrar el modal A DESPUÉS del primer frame para evitar error
  Future<void> _showLocationDeniedDialog(bool permanentlyDenied) {
    final completer = Completer<void>();

    // Ejecutar en el siguiente frame (ya habrá MaterialLocalizations si el build devolvió un MaterialApp)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        completer.complete();
        return;
      }

      try {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_off,
                  size: 60,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Permiso de ubicación requerido",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  permanentlyDenied
                      ? "Has bloqueado el permiso de ubicación permanentemente. "
                            "Por favor actívalo manualmente desde los ajustes del dispositivo."
                      : "Necesitamos tu ubicación para mostrarte información cerca de ti. "
                            "Por favor, concédela para continuar.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    permanentlyDenied ? "Abrir ajustes" : "Intentar de nuevo",
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
              ],
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error mostrando modal: $e');
      } finally {
        if (!completer.isCompleted) completer.complete();
      }
    });

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    // Mientras no haya permisos, muestra el splash
    if (_result == null ||
        context.read<AuthCubit>().state.status == AuthStatus.checking) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      );
    }

    // ✅ Solo avanza si ya tiene permiso de ubicación
    return widget.builder(context, _result);
  }
}
