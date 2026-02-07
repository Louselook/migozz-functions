import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_form/buy_coins_amounts.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_form/buy_coins_details.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_form/buy_coins_input.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_form/buy_title.dart';

class BuyCoinsForm extends StatelessWidget {
  const BuyCoinsForm({super.key});

  @override
  Widget build(BuildContext context) {
    return (SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BuyTitle(
            texts: [
              TitleModel(title: "wallet.buyText".tr()),
              TitleModel(title: "Migozz".tr(), gradient: true),
            ],
          ),

          BuyCoinsAmounts(),
          SizedBox(height: 55),
          BuyCoinsInput(),
          SizedBox(height: 40),
          BuyCoinsDetails(),
        ],
      ),
    ));
  }
}



