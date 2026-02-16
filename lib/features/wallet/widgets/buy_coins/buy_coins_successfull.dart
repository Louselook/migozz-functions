import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:migozz_app/core/assets_constants.dart';
import 'package:migozz_app/features/wallet/cubit/wallet_cubit/wallet_cubit.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_form/buy_title.dart';
import 'package:migozz_app/features/wallet/widgets/wallet_styles.dart';

class BuyCoinsSuccessfull extends StatelessWidget {
  BuyCoinsSuccessfull({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final totalBalance = context
        .watch<WalletCubit>()
        .state
        .walletData
        ?.totalBalance;

    return (SizedBox(
      height: screenHeight * 0.8,
      child: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 100.h),
              child: Column(
                children: [
                  BuyTitle(
                    texts: [
                      TitleModel(title: "Successful", gradient: true),
                      TitleModel(title: "Payment"),
                    ],
                  ),

                  SvgPicture.asset(AssetsConstants.buySuccess),
                  GradientText(text: "Migozz coins", size: 14.sp),
                  Text("Added successfully", style: TextStyle(color: Color(0xFFFFFFFF))),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GradientText(text: "New Balance:", size: 12.sp),
                      Text(
                        style: TextStyle(color: Color(0xFFFFFFFF)),
                        "${totalBalance!.toStringAsFixed(2)} migozz",
                      ),
                    ],
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
