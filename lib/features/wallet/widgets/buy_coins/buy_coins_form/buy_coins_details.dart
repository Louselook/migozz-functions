import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:migozz_app/features/wallet/cubit/buy_coins_cubit/buy_coins_cubit.dart';
import 'package:migozz_app/features/wallet/cubit/buy_coins_cubit/buy_coins_state.dart';
import 'package:migozz_app/features/wallet/cubit/conversion_cubit/conversion_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/wallet/model/wallet_model.dart';
import 'package:migozz_app/features/wallet/widgets/history/gradient_button.dart';
import 'package:migozz_app/features/wallet/widgets/wallet_styles.dart';

//Inferior totalities labels
class BuyLabelItem extends StatelessWidget {
  final String text;
  final String label;

  const BuyLabelItem({super.key, required this.text, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: Text(style: TextStyle(color: Color(0xFFFFEFEF)), label),
        ),
        Expanded(
          flex: 4,
          child: Container(
            decoration: WalletBoxStyles().containerBackground,
            padding: EdgeInsets.symmetric(vertical: 3, horizontal: 5),
            child: Text(
              style: TextStyle(
                color: Color(0xFFFFEFEF),
                fontWeight: FontWeight.bold,
              ),
              text,
            ),
          ),
        ),
      ],
    );
  }
}

class BuyCoinsDetails extends StatelessWidget {
  const BuyCoinsDetails({super.key});

  void _handleContinue(BuildContext context) {
    final cubit = context.read<BuyCoinsCubit>();
    cubit.nextStep(
      () => BuyCoinsState.paymentMethod(
        totalValue: cubit.state.total ?? 0,
        amount: cubit.state.amount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buyCoinsState = context.watch<BuyCoinsCubit>().state;
    final conversion = context.watch<ConversionCubit>().state.conversion;

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: context.screenWidth * 0.03, 
        vertical: context.screenHeight * 0.015
      ),
      decoration: WalletBoxStyles().containerBackground,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: WalletBoxStyles().inputBackgroud,
            padding: EdgeInsetsDirectional.symmetric(vertical: 2),
            child: Text(
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFFFEFEF)),
              "Summary",
            ),
          ),

          Container(
            width: double.infinity,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: context.screenWidth * 0.05,
              vertical: 25,
            ),
            child: Column(
              spacing: 15,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style: TextStyle(color: Color(0xFFFFEFEF)),
                  "Coins to Receive",
                ),

                Container(
                  decoration: WalletBoxStyles().containerBackground,
                  width: double.infinity,
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Row(
                    spacing: 5,
                    children: [
                      Text(
                        style: TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontWeight: FontWeight.bold,
                        ),
                        "\$${buyCoinsState.amount!.toStringAsFixed(2)}",
                      ),

                      GradientText(text: 'miggoz coins', size: 14),
                    ],
                  ),
                ),

                BuyLabelItem(
                  text: "1 migozz coins = \$$conversion USD",
                  label: "Rate:",
                ),
                BuyLabelItem(text: '\$0', label: "Fee:"),
                BuyLabelItem(
                  text: '\$${buyCoinsState.total!.toStringAsFixed(2)} USD',
                  label: "Total:",
                ),
              ],
            ),
          ),

          WalletGradientButton(
            action: () => _handleContinue(context),
            text: "Continue",
          ),
        ],
      ),
    );
  }
}
