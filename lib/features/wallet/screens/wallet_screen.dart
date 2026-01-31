import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomGradientHeight = size.height * 0.22;

    return (Scaffold(
      body: Stack(
        children: [
          Container(color: const Color.fromARGB(223, 0, 0, 0)),
          TintesGradients(child: Container(height: bottomGradientHeight)),
          SafeArea(
            child: Text(
              "My Wallet",
              textAlign: TextAlign.center,
              textScaler: TextScaler.linear(1.7),
              textWidthBasis: TextWidthBasis.longestLine,
            ),
          ),
        ],
      ),
    ));
  }
}
