

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/wallet/cubit/wallet_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/wallet/model/wallet_model.dart';

class WalletCubit extends Cubit<WalletState> {
  final AuthCubit authCubit;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StreamSubscription? _userSubscription;
  StreamSubscription? _walletSubscription;

  WalletCubit({required this.authCubit}) : super(WalletState.initial()) {
    //Here i created a stream to listen the authCubit state, making sure wallet exists
    debugPrint("Wallet cubit");

    _userSubscription = authCubit.stream.listen((authState) {
      debugPrint("Wallet ${authState.status.name}");

      if (authState.status == AuthStatus.authenticated && authState.userProfile != null && authState.userProfile?.wallet != null) {
        debugPrint('[WalletCubit] Usuario detectado: ${authState.userProfile!.email}');
        _activateWalletSnapshot(authState.userProfile?.wallet);
      } 
    });
  }

  //This creates the snapshot to listen user's wallet document if exists
  void _activateWalletSnapshot(String? id) {
    emit(WalletState.loading());
    
    // close previous connection
    _walletSubscription?.cancel();

    //Snapshot creates
    _walletSubscription = _firestore
        .collection('wallets')
        .doc(id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        print(snapshot.data());
        final walletData = WalletModel.fromFirestore(snapshot.data()!);
        emit(WalletState.initialized(walletData));
      } else {
        print("Wallet doesn't exist");
      }
    }, onError: (error) {
      print(error.toString());
    });
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    _walletSubscription?.cancel();
    return super.close();
  }
}