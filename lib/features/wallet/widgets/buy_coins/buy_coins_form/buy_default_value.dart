import 'package:flutter/material.dart';

class BuyDefaultValue extends StatelessWidget {
  final double value;
  final bool isSelected;

  const BuyDefaultValue({
    super.key, 
    required this.value, 
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
   
    return Container(

      padding: const EdgeInsets.all(2), 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF9022BA), Color(0xFFDC44AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9022BA).withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            value.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}