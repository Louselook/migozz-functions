import 'package:flutter/material.dart';
import 'dart:io';

class PlatformCard extends StatelessWidget {
  final Map<String, String> platform;
  final VoidCallback onTap;

  const PlatformCard({super.key, required this.platform, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SOLO EL LOGO - ocupa todo el card
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D3D3D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: platform['logo'] != null && platform['logo']!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(platform['logo']!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : const Icon(Icons.language, color: Colors.grey, size: 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
