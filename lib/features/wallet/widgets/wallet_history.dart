import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/wallet/cubit/transactions_cubit/transactions_cubit.dart';
import 'package:migozz_app/features/wallet/cubit/wallet_cubit/wallet_cubit.dart';

class WalletHistory extends StatelessWidget {
  const WalletHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final walletCubit = context.read<WalletCubit>();
    final walletId = walletCubit.state.walletData?.id;

    return BlocProvider(
      lazy: false,
      create: (context) => TransactionsCubit(walletId: walletId),
      child: Container(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsetsGeometry.directional(
                top: 5,
                bottom: 5,
                start: 10,
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
                "Transaction History",
                style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16),
              ),
            ),

            Container(child: Column(children: [])),
          ],
        ),
      ),
    );
  }
}
