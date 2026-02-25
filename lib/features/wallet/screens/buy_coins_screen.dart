import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/wallet/model/wallet_model.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_wrapper.dart';

class BuyCoinsScreen extends StatelessWidget {
  const BuyCoinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomGradientHeight = size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          Container(color: const Color.fromARGB(237, 0, 0, 0)),
          TintesGradients(child: Container(height: bottomGradientHeight)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: context.screenHeight * 0.01),
                  IconButton(
                    alignment: Alignment.topLeft,
                    icon: const Icon(
                      Icons.arrow_back_outlined,
                      color: Color(0xFFFFFFFF),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(height: context.screenHeight * 0.01),
                  const BuyCoinsWrapper(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
