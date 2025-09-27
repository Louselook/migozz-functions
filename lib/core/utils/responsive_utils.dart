import 'package:flutter/material.dart';

/// Utilidades para diseño responsive
class ResponsiveUtils {
  // Breakpoints de referencia
  static const double mobileBreakpoint = 360.0;
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 1024.0;

  /// Obtiene el factor de escala basado en el ancho de pantalla
  /// [screenWidth] - Ancho actual de la pantalla
  /// [baseWidth] - Ancho de referencia (por defecto 360dp)
  static double getScaleFactor(double screenWidth, {double baseWidth = mobileBreakpoint}) {
    return screenWidth / baseWidth;
  }

  /// Escala un valor con límites mínimos y máximos
  /// [baseValue] - Valor base a escalar
  /// [scaleFactor] - Factor de escala
  /// [minValue] - Valor mínimo permitido
  /// [maxValue] - Valor máximo permitido
  static double scaleValue(
    double baseValue, 
    double scaleFactor, {
    double? minValue, 
    double? maxValue
  }) {
    final scaledValue = baseValue * scaleFactor;
    if (minValue != null && maxValue != null) {
      return scaledValue.clamp(minValue, maxValue);
    } else if (minValue != null) {
      return scaledValue < minValue ? minValue : scaledValue;
    } else if (maxValue != null) {
      return scaledValue > maxValue ? maxValue : scaledValue;
    }
    return scaledValue;
  }

  /// Determina el tipo de dispositivo basado en el ancho de pantalla
  static DeviceType getDeviceType(double screenWidth) {
    if (screenWidth >= desktopBreakpoint) {
      return DeviceType.desktop;
    } else if (screenWidth >= tabletBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.mobile;
    }
  }

  /// Obtiene el número de columnas del grid según el tipo de dispositivo
  static int getGridColumns(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return 3;
      case DeviceType.tablet:
        return 4;
      case DeviceType.desktop:
        return 5;
    }
  }

  /// Obtiene padding horizontal responsive
  static double getHorizontalPadding(double scaleFactor) {
    return scaleValue(40.0, scaleFactor, minValue: 20.0, maxValue: 60.0);
  }

  /// Obtiene padding vertical responsive
  static double getVerticalPadding(double scaleFactor) {
    return scaleValue(20.0, scaleFactor, minValue: 16.0, maxValue: 32.0);
  }

  /// Obtiene tamaño de fuente responsive
  static double getResponsiveFontSize(double baseSize, double scaleFactor) {
    return scaleValue(baseSize, scaleFactor, minValue: baseSize * 0.8, maxValue: baseSize * 1.3);
  }
}

/// Tipos de dispositivo para responsive design
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Extension para facilitar el uso de responsive utils en BuildContext
extension ResponsiveExtension on BuildContext {
  /// Obtiene las dimensiones de la pantalla
  Size get screenSize => MediaQuery.of(this).size;
  
  /// Obtiene el factor de escala
  double get scaleFactor => ResponsiveUtils.getScaleFactor(screenSize.width);
  
  /// Obtiene el tipo de dispositivo
  DeviceType get deviceType => ResponsiveUtils.getDeviceType(screenSize.width);
  
  /// Verifica si es móvil
  bool get isMobile => deviceType == DeviceType.mobile;
  
  /// Verifica si es tablet
  bool get isTablet => deviceType == DeviceType.tablet;
  
  /// Verifica si es desktop
  bool get isDesktop => deviceType == DeviceType.desktop;
}