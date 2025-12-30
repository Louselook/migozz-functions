import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/location_dto.dart';
import 'package:migozz_app/features/splash/splash_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:migozz_app/features/auth/services/location_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:location/location.dart' as loc;

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
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      _runInit();
    }
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
      final location = loc.Location();
      final status = await location.hasPermission();
      if (status != loc.PermissionStatus.granted &&
          status != loc.PermissionStatus.grantedLimited &&
          mounted) {
        await _runInit();
      }
    }
  }

  Future<void> _runInit() async {
    if (_isInitializing) {
      debugPrint('⚠️ [AppInit] Ya hay inicialización en curso, omitiendo');
      return;
    }
    _isInitializing = true;
    debugPrint('🚀 [AppInit] Iniciando permisos y ubicación...');

    try {
      bool microphoneGranted = false;
      bool locationGranted = false;
      LocationDTO? locationDto;
      final lang = context.locale.languageCode == 'es' ? 'es' : 'en';

      if (!kIsWeb) {
        // Request microphone permission
        final micStatus = await Permission.microphone.request();
        microphoneGranted = micStatus.isGranted;

        // Use location package for permission handling
        final location = loc.Location();

        // Check if location service is enabled
        bool serviceEnabled = await location.serviceEnabled();
        debugPrint('📍 [LocationPermission] Service enabled: $serviceEnabled');

        if (!serviceEnabled) {
          serviceEnabled = await location.requestService();
          debugPrint('📍 [LocationPermission] Service after request: $serviceEnabled');
        }

        if (serviceEnabled) {
          // Check location permission
          var permissionStatus = await location.hasPermission();
          debugPrint('📍 [LocationPermission] Current status: $permissionStatus');

          // If denied, request permission
          if (permissionStatus == loc.PermissionStatus.denied) {
            debugPrint('🔔 [LocationPermission] Requesting permission...');
            permissionStatus = await location.requestPermission();
            debugPrint('📍 [LocationPermission] Request result: $permissionStatus');
          }

          // Handle the result with timeout
          if (permissionStatus == loc.PermissionStatus.granted ||
              permissionStatus == loc.PermissionStatus.grantedLimited) {
            locationGranted = true;
            try {
              final svc = LocationService();
              locationDto = await svc.initAndFetchAddress(lang: lang)
                  .timeout(const Duration(seconds: 10), onTimeout: () {
                debugPrint('⏱️ [LocationService] Timeout obteniendo ubicación');
                return null;
              });
            } catch (e) {
              debugPrint('❌ Error al obtener ubicación: $e');
            }
          } else if (permissionStatus == loc.PermissionStatus.deniedForever) {
            debugPrint('⛔ [LocationPermission] Permission permanently denied');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _showLocationDeniedDialog(true);
            });
          } else {
            debugPrint('⚠️ [LocationPermission] Permission denied by user');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _showLocationDeniedDialog(false);
            });
          }
        } else {
          debugPrint('❌ [LocationPermission] Location service not available');
        }
      } else {
        // En web — permisos simulados o usando otra API
        debugPrint('🌐 Web detectada — simulando permisos');

        microphoneGranted = true; // si no los necesitas realmente
        locationGranted = true;

        try {
          final svc = LocationService();
          locationDto = await svc.initAndFetchAddress(lang: lang);
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
    // Solo espera a que se obtengan los permisos
    // El AuthCubit ya se está inicializando en paralelo y el router maneja la navegación
    if (_result == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      );
    }

    // Avanza solo cuando se obtuvieron los permisos
    return widget.builder(context, _result);
  }
}
