import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/location_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/splash/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  bool _isInitializing = false; //  Flag para evitar solicitudes concurrentes

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
    //  Evitar llamadas concurrentes
    if (_isInitializing) {
      debugPrint('⚠️ Ya hay una inicialización en progreso, ignorando...');
      return;
    }

    if (!kIsWeb) {
      final status = await Permission.locationWhenInUse.status;
      if (!status.isGranted && mounted) {
        await _runInit();
      }
    }
  }

  Future<void> _runInit() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      bool microphoneGranted = false;
      bool locationGranted = false;
      LocationDTO? locationDto;

      if (!kIsWeb) {
        //  Solo en móvil o desktop

        // Request microphone permission
        final micStatus = await Permission.microphone.request();
        microphoneGranted = micStatus.isGranted;

        // Check location permission status first
        final locStatus = await Permission.locationWhenInUse.status;
        debugPrint('📍 [LocationPermission] Current status: $locStatus');

        PermissionStatus finalLocStatus;

        // If already granted, use location directly
        if (locStatus.isGranted || locStatus.isLimited) {
          finalLocStatus = locStatus;
        }
        // If permanently denied or restricted, show settings dialog
        else if (locStatus.isPermanentlyDenied || locStatus.isRestricted) {
          debugPrint('⛔ [LocationPermission] Permission permanently denied or restricted');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _showLocationDeniedDialog(true);
          });
          finalLocStatus = locStatus;
        }
        // If denied (including notDetermined), request permission (shows native dialog)
        else if (locStatus.isDenied) {
          debugPrint('🔔 [LocationPermission] Requesting permission (status: denied/notDetermined)');
          finalLocStatus = await Permission.locationWhenInUse.request();
          debugPrint('📍 [LocationPermission] Request result: $finalLocStatus');

          // If user denied the permission, show dialog
          if (finalLocStatus.isDenied) {
            debugPrint('⚠️ [LocationPermission] Permission denied by user');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _showLocationDeniedDialog(false);
            });
          } else if (finalLocStatus.isPermanentlyDenied) {
            debugPrint('⛔ [LocationPermission] Permission permanently denied after request');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _showLocationDeniedDialog(true);
            });
          }
        }
        // Fallback: request permission
        else {
          debugPrint('🔔 [LocationPermission] Fallback - requesting permission');
          finalLocStatus = await Permission.locationWhenInUse.request();
          debugPrint('📍 [LocationPermission] Request result: $finalLocStatus');
        }

        // If permission granted or limited, get location
        if (finalLocStatus.isGranted || finalLocStatus.isLimited) {
          locationGranted = true;
          try {
            final svc = LocationService();
            locationDto = await svc.initAndFetchAddress();
          } catch (e) {
            debugPrint('❌ Error al obtener ubicación: $e');
          }
        }
      } else {
        // En web — permisos simulados o usando otra API
        debugPrint('🌐 Web detectada — simulando permisos');

        microphoneGranted = true; // si no los necesitas realmente
        locationGranted = true;

        try {
          final svc = LocationService();
          locationDto = await svc.initAndFetchAddress();
        } catch (e) {
          debugPrint('❌ Error obteniendo ubicación en web: $e');
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

      debugPrint(' Inicialización completada');
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
              if (permanentlyDenied)
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await openAppSettings();
                  },
                  child: const Text("Abrir ajustes"),
                )
              else
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cerrar"),
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

    //  Solo avanza si ya tiene permiso de ubicación
    return widget.builder(context, _result);
  }
}
