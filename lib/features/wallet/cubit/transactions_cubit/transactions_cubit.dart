

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:migozz_app/features/wallet/cubit/transactions_cubit/transactions_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/wallet/model/transaction_model.dart';

class TransactionsCubit extends Cubit<TransactionsState> {
  final String? walletId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ///I created this bool to prevent the creation of multiple snapshots when the AuthState change
  bool initialized = false;
  
  StreamSubscription? _transactionsSubscription;

  TransactionsCubit({required this.walletId}) : super(TransactionsState.initial()) {
    debugPrint("Transactions");
    _activateTransactionsSnapshot();
  }

  //create the snapshot with the wallet id provided
  void _activateTransactionsSnapshot() {
    emit(TransactionsState.loading());
    debugPrint("Getting wallet transactions $walletId");
    // close previous connection
    _transactionsSubscription?.cancel();

    //Snapshot creates
    _transactionsSubscription = _firestore
        .collection('wallets')
        .doc(walletId)
        .collection("transactions")
        .orderBy("created", descending: true)
        .limit(3)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.map((trans) => trans.data()).toList();
        final transactions = TransactionModel.fromList(data);
        initialized = true;
        emit(TransactionsState.initialized(transactions));
        debugPrint("Transactions updated");
      } else {
        debugPrint("No transactions avaliable");
        emit(TransactionsState.empty());
      }
    }, onError: (error) {
      debugPrint("Transactions error: ${error.toString()}");
    });
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}