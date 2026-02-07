import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/assets_constants.dart';
import 'package:migozz_app/features/wallet/widgets/history/transaction_button.dart';

class WalletActions extends StatelessWidget {
  const WalletActions({super.key});

  @override
  Widget build(BuildContext context) {
    return(
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 40,
        children: [
        TransactionButton(icon: AssetsConstants.walletBuy, text: "wallet.buyText".tr(), route: "buy-coins"),
        TransactionButton(icon: AssetsConstants.walletUp, text: "wallet.sentText".tr(), route: "buy-coins"),
        TransactionButton(icon: AssetsConstants.walletDown, text: "wallet.withdraw".tr(), route: "buy-coins"),
      ],)
    );
  }
}