import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/wallet/cubit/buy_coins_cubit/buy_coins_cubit.dart';
import 'package:migozz_app/features/wallet/cubit/buy_coins_cubit/buy_coins_state.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_form/buy_coins_form.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_form/buy_coins_methods.dart';

class BuyCoinsWrapper extends StatelessWidget {
  const BuyCoinsWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BuyCoinsCubit, BuyCoinsState>(
      builder: (context, state) {
        if (state.inititialized) {
          return BuyCoinsForm();
        }

        if (state.inMethods) {
          return BuyCoinsMethods();
        }

        return Text("Loading...");
      },
    );
  }
}
