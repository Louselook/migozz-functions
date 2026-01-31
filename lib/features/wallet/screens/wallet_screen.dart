import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/wallet/widgets/wallet_balance.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomGradientHeight = size.height;

    return (Scaffold(
      body: Stack(
        children: [
          Container(color: const Color.fromARGB(237, 0, 0, 0)),
          TintesGradients(child: Container(height: bottomGradientHeight)),
          SafeArea(
            child: Padding(
              padding: EdgeInsetsGeometry.all(16),
              child: Column(
                children: [
                  SizedBox(height: 60),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      "My Wallet",
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      textScaler: TextScaler.linear(1.7),
                    ),
                  ),
                  SizedBox(height: 20),

                  Expanded(child: Column(children: [WalletBalance()])),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
