import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class ProfileStrengthIndicator extends StatelessWidget {
  final int percentage;

  const ProfileStrengthIndicator({
    super.key,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Profile Strength',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,

                ),
              ),SizedBox(width: 10,),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: Colors.purple.shade400,
                  fontSize: 11,

                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  // Fondo gris
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade800,
                  ),
                  // Barra de progreso con gradiente
                  FractionallySizedBox(
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.verticalPinkPurple,
                        ),

                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

