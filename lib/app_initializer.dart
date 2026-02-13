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
    // Ya no solicitamos permisos globales al reanudar.
  }

  Future<void> _runInit() async {
    if (_isInitializing) {
      debugPrint('⚠️ [AppInit] Ya hay inicialización en curso, omitiendo');
      return;
    }
    _isInitializing = true;
    debugPrint(
      '🚀 [AppInit] Inicializando (sin solicitar permisos globales)...',
    );

    try {
      bool microphoneGranted = false;
      bool locationGranted = false;
      LocationDTO? locationDto;
      final lang = context.locale.languageCode == 'es' ? 'es' : 'en';

      // Nota:
      // - Ya NO pedimos permisos aquí.
      // - Los permisos se solicitan en el flujo de registro cuando corresponda.
      // - Aun así, si el usuario YA dio permisos previamente, podemos detectar estado y (opcionalmente)
      //   precargar ubicación sin mostrar diálogos.

      if (!kIsWeb) {
        try {
          final micStatus = await Permission.microphone.status;
          microphoneGranted = micStatus.isGranted;
        } catch (e) {
          debugPrint('⚠️ [AppInit] No se pudo leer permiso de micrófono: $e');
        }

        try {
          final location = loc.Location();
          final serviceEnabled = await location.serviceEnabled();
          final permissionStatus = await location.hasPermission();
          locationGranted =
              serviceEnabled &&
              (permissionStatus == loc.PermissionStatus.granted ||
                  permissionStatus == loc.PermissionStatus.grantedLimited);

          if (locationGranted) {
            final svc = LocationService();
            locationDto = await svc
                .initAndFetchAddress(lang: lang)
                .timeout(
                  const Duration(seconds: 10),
                  onTimeout: () {
                    debugPrint(
                      '⏱️ [LocationService] Timeout obteniendo ubicación',
                    );
                    return null;
                  },
                );
          }
        } catch (e) {
          debugPrint('⚠️ [AppInit] No se pudo precargar ubicación: $e');
        }
      } else {
        // Web: no bloqueamos el arranque con permisos.
        microphoneGranted = true;
        locationGranted = false;
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
      if (mounted) {
        setState(() {
          _result = AppInitResult(
            location: null,
            microphoneGranted: false,
            locationGranted: false,
          );
        });
      }
    } finally {
      _isInitializing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Siempre mostrar splash mientras se inicializa
    if (_result == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      );
    }

    // Pasar el splash screen al builder para que lo use como fallback
    return widget.builder(context, _result);
  }
}
