import 'package:flutter/material.dart';

/// Widget para mostrar la ubicación del usuario con icono
class LocationDisplay extends StatelessWidget {
  final String? city;
  final String? state;
  final String? country;
  final double fontSize;
  final double scale;

  const LocationDisplay({
    super.key,
    this.city,
    this.state,
    this.country,
    required this.fontSize,
    required this.scale,
  });

  String get locationLine {
    final parts = <String>[];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    if (locationLine.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 4 * scale),
      child: Row(
        children: [
          Icon(Icons.location_on, size: fontSize, color: Colors.white54),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              locationLine,
              style: TextStyle(
                color: Colors.white54,
                fontSize: fontSize - 1,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
