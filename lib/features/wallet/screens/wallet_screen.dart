import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/wallet/cubit/wallet_cubit/wallet_cubit.dart';
import 'package:migozz_app/features/wallet/cubit/wallet_cubit/wallet_state.dart';
import 'package:migozz_app/features/wallet/widgets/wallet_actions.dart';
import 'package:migozz_app/features/wallet/widgets/wallet_balance.dart';
import 'package:migozz_app/features/wallet/widgets/history/wallet_history_wrapper.dart';

class GradientText extends StatelessWidget {
  final String text;
  final double size;

  const GradientText({super.key, required this.text, required this.size});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: [Color(0xFF9022BA), Color(0xFFDC44AA)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: Colors
              .white, // El color base debe ser blanco para que el degradado brille
        ),
      ),
    );
  }
}

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
                      "wallet.mainTitle".tr(),
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      textScaler: TextScaler.linear(1.7),
                    ),
                  ),
                  SizedBox(height: 20),

                  BlocBuilder<WalletCubit, WalletState>(
                    builder: (context, state) {
                      return (Expanded(
                        child: Column(
                          children: [
                            WalletBalance(),
                            SizedBox(height: 20),
                            WalletActions(),
                            SizedBox(height: 30),
                            WalletHistory(),
                          ],
                        ),
                      ));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
