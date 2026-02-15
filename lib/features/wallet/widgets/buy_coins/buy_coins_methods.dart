import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:migozz_app/core/assets_constants.dart';
import 'package:migozz_app/features/wallet/cubit/buy_coins_cubit/buy_coins_cubit.dart';
import 'package:migozz_app/features/wallet/cubit/conversion_cubit/conversion_cubit.dart';
import 'package:migozz_app/features/wallet/cubit/wallet_cubit/wallet_cubit.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_form/buy_title.dart';
import 'package:migozz_app/features/wallet/widgets/history/gradient_button.dart';
import 'package:migozz_app/features/wallet/widgets/wallet_styles.dart';

//Nota Igor: Los métodos de pago ya estan guardados en el conversion_state.dart aquí solo se mapean
//Note Igor: The payment methods are already saved in conversion_state.dart; they are only mapped here.

class BuyCoinsMethods extends StatelessWidget {
  const BuyCoinsMethods({super.key});


  //Params for stripePayment(double amount, callBack: function to execute when payment is successfull)
  void _handleBuyCoins (BuildContext context){
    final amount = context.read<BuyCoinsCubit>().state.total;
    context.read<WalletCubit>().stripePayment(amount, () => 
      debugPrint("Payment successfull")
    );
  }

  @override
  Widget build(BuildContext context) {
    final buyState = context.watch<BuyCoinsCubit>().state;
    final conversionState = context.watch<ConversionCubit>().state;
    final methods = conversionState.methods ?? [];

    final double screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
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
                      TitleModel(title: "wallet.paymentText".tr(), gradient: true),
                      TitleModel(title: "wallet.methodText".tr()),
                    ],
                  ),
                  SizedBox(height: 55.h),
                  ...methods.map((method) {
                    final isSelected = buyState.selectedMethod == method.id;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 15.h),
                      child: GestureDetector(
                        onTap: method.active
                            ? () => context.read<BuyCoinsCubit>().selectMethod(method.id)
                            : null,
                        child: Container(
                          width: double.infinity,
                          decoration: WalletBoxStyles().containerBackground.copyWith(
                            border: isSelected && method.active
                                ? Border.all(color: const Color(0xFFDC44AA), width: 2)
                                : !method.active
                                    ? Border.all(color: const Color(0xFFFF0000))
                                    : null,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
                          child: Column(
                            spacing: 20,
                            children: [
                              SvgPicture.asset(
                                "${AssetsConstants.icons}/${method.icon}",
                                height: 50.h,
                              ),
                              Text(
                                method.active ? method.name : "Temporarily Unavailable",
                                style: TextStyle(
                                  color: method.active ? Colors.white : const Color(0xFFA51A40),
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),


          if (buyState.selectedMethod != null)
            Positioned(
              bottom: 20.h,
              left: 0,
              right: 0,
              child: WalletGradientButton(
                fontSize: 14,
                action: () => _handleBuyCoins(context),
                text: "Pay now",
              ),
            ),
        ],
      ),
    );
  }
}