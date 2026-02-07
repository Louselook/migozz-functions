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
      body: Stack(
        children: [
          Container(color: const Color.fromARGB(237, 0, 0, 0)),
          TintesGradients(child: Container(height: bottomGradientHeight)),
          SafeArea(
            child: Padding(
              padding: EdgeInsetsGeometry.directional(start: 30, end: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    alignment: AlignmentGeometry.topLeft,
                    icon: const Icon(
                      Icons.arrow_back_outlined,
                      color: Color(0xFFFFFFFF),
                    ),
                    onPressed: () {},
                  ),
                  BuyCoinsWrapper(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
