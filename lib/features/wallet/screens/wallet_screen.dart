import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/wallet/cubit/wallet_cubit/wallet_cubit.dart';
import 'package:migozz_app/features/wallet/cubit/wallet_cubit/wallet_state.dart';
import 'package:migozz_app/features/wallet/widgets/wallet_actions.dart';
import 'package:migozz_app/features/wallet/widgets/wallet_balance.dart';
import 'package:migozz_app/features/wallet/widgets/history/wallet_history_wrapper.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isShortDevice = screenSize.height < 850;

    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color.fromARGB(237, 0, 0, 0)),
          TintesGradients(child: SizedBox.expand()), 
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenSize.width * 0.05, 
                vertical: 10
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      SizedBox(height: isShortDevice ? 0 : 40),
                      
                      Text(
                        "wallet.mainTitle".tr(),
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontWeight: FontWeight.w600,
                          fontSize: constraints.maxWidth * 0.07, 
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: constraints.maxHeight * 0.03),

                      Expanded(
                        child: BlocBuilder<WalletCubit, WalletState>(
                          builder: (context, state) {
                            return SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  WalletBalance(),
                                  SizedBox(height: 20),
                                  WalletActions(),
                                  SizedBox(height: 30),
                                  WalletHistory(),
                                  SizedBox(height: 20),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}