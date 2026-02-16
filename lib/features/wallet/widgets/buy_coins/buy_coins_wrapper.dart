import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/wallet/cubit/buy_coins_cubit/buy_coins_cubit.dart';
import 'package:migozz_app/features/wallet/cubit/buy_coins_cubit/buy_coins_state.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_form/buy_coins_form.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_methods.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_successfull.dart';

class BuyCoinsWrapper extends StatelessWidget {
  const BuyCoinsWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BuyCoinsCubit, BuyCoinsState>(
      builder: (context, state) {
        return PopScope(
          canPop: state.inititialized, 
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;

            final cubit = context.read<BuyCoinsCubit>();

            if (state.inMethods) {
              cubit.nextStep(() => BuyCoinsState.initial(amount: state.amount ?? 0, total: state.total ?? 0)); 
            } else if (state.successfull) {
              Navigator.of(context).pop();
            }
          },
          child: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(BuyCoinsState state) {
    if (state.successfull) {
      return BuyCoinsSuccessfull();
    }

    if (state.inMethods) {
      return const BuyCoinsMethods();
    }

    if (state.inititialized) {
      return const BuyCoinsForm();
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}