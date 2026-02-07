import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_form/buy_coins_amounts.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_form/buy_coins_input.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_form/buy_title.dart';

class BuyCoinsForm extends StatefulWidget {
  const BuyCoinsForm({super.key});

  @override
  State<BuyCoinsForm> createState() => _BuyCoinsFormState();
}

class _BuyCoinsFormState extends State<BuyCoinsForm> {
  final _amount = TextEditingController();

  @override
  dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BuyTitle(texts: [
            TitleModel(title: "wallet.buyText".tr()),
            TitleModel(title: "Migozz".tr(), gradient: true),
          ]),

          BuyCoinsAmounts(),
          SizedBox(height: 55),
          BuyCoinsInput()
        ],
      ),
    ));
  }
}
