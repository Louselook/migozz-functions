import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_wrapper.dart';

class BuyCoinsScreen extends StatelessWidget {
  const BuyCoinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomGradientHeight = size.height;

    return Scaffold(
      // Mantenemos false para que el degradado de fondo no se mueva con el teclado
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          Container(color: const Color.fromARGB(237, 0, 0, 0)),
          TintesGradients(child: Container(height: bottomGradientHeight)),
          SafeArea(
            child: SingleChildScrollView( // 👈 El scroll ahora vive aquí
              padding: const EdgeInsets.symmetric(horizontal: 30),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10), // Un pequeño respiro arriba
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(), // Quita el padding interno del botón
                    alignment: Alignment.topLeft,
                    icon: const Icon(
                      Icons.arrow_back_outlined,
                      color: Color(0xFFFFFFFF),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 20),
                  const BuyCoinsWrapper(), // Ahora el Wrapper no necesita scroll interno
                  const SizedBox(height: 40), // Espacio para que el teclado no tape el final
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
