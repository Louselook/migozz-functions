import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/assets_constants.dart';
import 'package:migozz_app/features/wallet/widgets/history/gradient_button.dart';

class WalletHistoryEmpty extends StatelessWidget {
  const WalletHistoryEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(AssetsConstants.walletEmpty),
        SizedBox(height: 20),
        Text(
          style: TextStyle(fontSize: 15, color: Color(0xFF404040)),
          "wallet.textEmpty1".tr(),
        ),
        Text(
          style: TextStyle(fontSize: 15, color: Color(0xFF404040)),
          "wallet.textEmpty2".tr(),
        ),
        SizedBox(height: 20),
        WalletGradientButton(
          text: 'Buy coins',
          action: () {
            context.pushNamed("buy-coins");
          },
        ),
      ],
    );
  }
}
