import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/wallet/cubit/transactions_cubit/transactions_cubit.dart';
import 'package:migozz_app/features/wallet/cubit/transactions_cubit/transactions_state.dart';
import 'package:migozz_app/features/wallet/cubit/wallet_cubit/wallet_cubit.dart';
import 'package:migozz_app/features/wallet/widgets/history/wallet_history_empty.dart';
import 'package:migozz_app/features/wallet/widgets/history/wallet_history_list.dart';
import 'package:migozz_app/features/wallet/widgets/history/wallet_history_loading.dart';

class WalletHistory extends StatelessWidget {
  const WalletHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final walletId = context.watch<WalletCubit>().state.walletData?.id;

    if(walletId == null){
      return WalletHistoryLoading();
    }

    return BlocProvider(
      create: (context) => TransactionsCubit(walletId: walletId),
      child: Container(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsetsGeometry.directional(
                top: 5,
                bottom: 5,
                start: 20,
              ),
              decoration: BoxDecoration(
                color: const Color.fromARGB(12, 226, 226, 226),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color.fromARGB(76, 255, 255, 255),
                  width: 0.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Text(
                "wallet.historyTitle".tr(),
                style: TextStyle(color: Color.fromARGB(209, 255, 255, 255), fontSize: 20),
              ),
            ),

            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                border: Border.all(
                  color: const Color.fromARGB(76, 255, 255, 255),
                  width: 0.5,
                  style: BorderStyle.solid,
                ),
              ),
              
              child: BlocBuilder<TransactionsCubit, TransactionsState>(
                builder: (context, state) {
                  if (state.isEmpty) {
                    return WalletHistoryEmpty();
                  }

                  if(state.hasData){
                    return WalletHistoryList();
                  }

                  return WalletHistoryLoading();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
