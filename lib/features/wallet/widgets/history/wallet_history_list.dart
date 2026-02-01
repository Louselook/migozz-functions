import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/wallet/cubit/transactions_cubit/transactions_cubit.dart';
import 'package:migozz_app/features/wallet/model/transaction_model.dart';
import 'package:migozz_app/features/wallet/widgets/history/transaction_tile.dart';

class WalletHistoryList extends StatelessWidget {
  const WalletHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<TransactionModel>? data = context.read<TransactionsCubit>().state.transactions;

    if (data != null) {
      return (Column(
        spacing: 10,
        children: data.map((transaction) {
          return TransactionTile(transaction: transaction);
        }).toList(),
      ));
    }

    return SizedBox.shrink();
  }
}
