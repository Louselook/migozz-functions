import 'package:flutter/material.dart';

class BuyCoinsInput extends StatelessWidget {
  const BuyCoinsInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), // Fondo de la tarjeta principal
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color.fromARGB(43, 255, 255, 255)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Custom Amount",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(31, 255, 255, 255), // Fondo más oscuro para el input
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: r"$ ", // El símbolo de dólar fijo
                prefixStyle: const TextStyle(color: Colors.white, fontSize: 24),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                border:
                    InputBorder.none, // Quitamos la línea de abajo por defecto
                hintText: "0",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
