import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/wallet/cubit/conversion_cubit/conversion_cubit.dart';
import 'package:migozz_app/features/wallet/cubit/conversion_cubit/conversion_state.dart';
import 'package:migozz_app/features/wallet/cubit/wallet_cubit/wallet_cubit.dart';
import 'package:migozz_app/features/wallet/model/wallet_model.dart';

class WalletBalance extends StatelessWidget {
  const WalletBalance({super.key});

  @override
  Widget build(BuildContext context) {
    final walletState = context.read<WalletCubit>().state;
    double balance = 0;
    if(walletState.walletData != null){
      balance = walletState.walletData!.totalBalance;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(12, 226, 226, 226),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color.fromARGB(76, 255, 255, 255),
          width: 0.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsetsGeometry.directional(
              start: 24,
              top: 24,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "wallet.title".tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 3),

                BlocBuilder<ConversionCubit, ConversionState>(
                  builder: (context, state) {
                    final conversion = state.conversion ?? 1;
                    final migozzCoins = balance * conversion;

                    return (Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              WalletModel.formattedAmount(balance),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            const SizedBox(width: 8),
                            Text(
                              "USD",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),

                        Row(
                          spacing: 5,
                          children: [
                            Text(
                              WalletModel.formattedAmount(migozzCoins),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),

                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  colors: [
                                    Color(0xFF9022BA),
                                    Color(0xFFDC44AA),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(bounds);
                              },
                              child: const Text(
                                'migozz coins',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors
                                      .white, // El color base debe ser blanco para que el degradado brille
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ));
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
