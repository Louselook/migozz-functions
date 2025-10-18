import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/splash/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:migozz_app/features/auth/data/domain/models/location_dto.dart';

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
  bool _isInitializing = false; // ✅ Flag para evitar solicitudes concurrentes

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
    // ✅ Evitar llamadas concurrentes
    if (_isInitializing) {
      debugPrint('⚠️ Ya hay una inicialización en progreso, ignorando...');
      return;
    }

    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted && mounted) {
      await _runInit();
    }
  }

  Future<void> _runInit() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // 1️⃣ Permiso micro
      final micStatus = await Permission.microphone.request();
      final microphoneGranted = micStatus.isGranted;

      // 2️⃣ Intentar pedir ubicación UNA vez
      final locStatus = await Permission.locationWhenInUse.request();
      bool locationGranted = false;
      LocationDTO? locationDto;

      if (locStatus == PermissionStatus.granted ||
          locStatus == PermissionStatus.limited) {
        locationGranted = true;
        try {
          final svc = LocationService();
          locationDto = await svc.initAndFetchAddress();
        } catch (e) {
          debugPrint('❌ Error al obtener ubicación: $e');
        }
      } else {
        // Si no concedió, mostramos un modal INFORMANDO y continuamos sin bloquear
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showLocationDeniedDialog(
            locStatus == PermissionStatus.permanentlyDenied,
          );
        });
        locationGranted = false;
        locationDto = null;
      }

      if (!mounted) return;

      setState(() {
        _result = AppInitResult(
          location: locationDto,
          microphoneGranted: microphoneGranted,
          locationGranted: locationGranted,
        );
      });

      debugPrint('✅ Inicialización completada (no bloqueante)');
    } catch (e) {
      debugPrint('❌ Error durante inicialización: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// Mostrar el modal DESPUÉS del primer frame para evitar error
  Future<void> _showLocationDeniedDialog(bool permanentlyDenied) async {
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
            children: [
              const Icon(Icons.location_off, size: 60, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                permanentlyDenied
                    ? "Has bloqueado el permiso de ubicación permanentemente. Actívalo desde Ajustes si quieres usar funciones basadas en ubicación."
                    : "No concediste la ubicación. Algunas funciones podrían no estar disponibles.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(permanentlyDenied ? "Abrir ajustes" : "Cerrar"),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error mostrando modal: $e');
    }
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
