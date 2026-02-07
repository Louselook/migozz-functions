import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/wallet/cubit/buy_coins_cubit/buy_coins_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/wallet/cubit/conversion_cubit/conversion_cubit.dart';
import 'package:migozz_app/features/wallet/cubit/wallet_cubit/wallet_cubit.dart';
import 'package:migozz_app/features/wallet/model/buy_coins_model.dart';

class BuyCoinsCubit extends Cubit<BuyCoinsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WalletCubit walletCubit;
  final ConversionCubit conversionCubit;

  BuyCoinsCubit({required this.walletCubit, required this.conversionCubit}) : super(BuyCoinsState.initial());

  Future<void> buyCoinsRequest(double amount) async{
    final walletData = walletCubit.state.walletData;
    BuyCoinsModel data = BuyCoinsModel(amount: amount, wallet: walletData!.id, user: walletData.user);
    debugPrint(data.amount.toString());
    debugPrint(data.user);
    debugPrint(data.wallet);
  }

  void updateAmount(double value){
    final total = value * conversionCubit.state.conversion!;
    emit(state.copyWith(amount: value, total: total));
  }

}
