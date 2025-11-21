import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';
import 'package:migozz_app/core/components/atomics/text.dart';

class LayoutStep extends StatelessWidget {
  final PageController controller;
  const LayoutStep({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          //  Contenido scrolleable
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const PrimaryText("Edit your profile layout"),
                const SizedBox(height: 5),

                // Imagen principal
                imageContainer(),
                const SizedBox(height: 4),

                // Grid
                layerDesing(),

                // espacio para que el scroll no tape el botón
                const SizedBox(height: 50),
              ],
            ),
          ),

          // Botón fijo abajo
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: GradientButton(
              width: double.infinity,
              radius: 19,
              onPressed: () => controller.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
              child: const SecondaryText('Continue', fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget imageContainer() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[700], // mock color
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fondo de imagen mock
          Container(decoration: BoxDecoration(color: Colors.grey[800])),

          // Info encima
          const Positioned(
            bottom: 20,
            child: Column(
              children: [
                SecondaryText(
                  "User Name",
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
                SecondaryText("1M", fontSize: 14, color: Colors.white),
                SecondaryText("Community", fontSize: 14, color: Colors.white),
                SizedBox(height: 8),
                Icon(Icons.share, size: 20, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget layerDesing() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(), // Evita scroll interno
        shrinkWrap: true, // Se ajusta al contenido
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1, // Mantiene cuadrados perfectos
        ),
        itemBuilder: (context, index) {
          bool isAddBox =
              index % 3 == 1 || index == 6 || index == 8; // Más cajas de "+"
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12), // Bordes más redondeados
              gradient: isAddBox
                  ? const LinearGradient(
                      colors: [
                        Color(0xFFE91E63),
                        Color(0xFF9C27B0),
                      ], // Rosa a morado
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isAddBox ? null : Colors.grey[600],
            ),
            child: isAddBox
                ? const Center(
                    child: Icon(Icons.add, color: Colors.white, size: 24),
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      // Aquí podrías añadir imágenes mock o colores diferentes
                      color: Colors.grey[600],
                    ),
                  ),
          );
        },
      ),
    );
  }
}
