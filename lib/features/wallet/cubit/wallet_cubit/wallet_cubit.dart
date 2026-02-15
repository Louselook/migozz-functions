import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_state.dart';
import 'package:migozz_app/features/wallet/cubit/wallet_cubit/wallet_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/wallet/model/wallet_model.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class WalletCubit extends Cubit<WalletState> {
  final AuthCubit authCubit;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ///I created this bool to prevent the creation of multiple snapshots when the AuthState change
  bool initialized = false;

  StreamSubscription? _userSubscription;
  StreamSubscription? _walletSubscription;

  WalletCubit({required this.authCubit}) : super(WalletState.initial()) {
    //Here i created a stream to listen the authCubit state, making sure wallet exists
    _userSubscription = authCubit.stream.listen((authState) {
      if (authState.status == AuthStatus.authenticated &&
          authState.userProfile != null) {
        if (authState.userProfile!.wallet != null && !initialized) {
          debugPrint(
            "Creating wallet snapshot: ${authState.userProfile!.wallet}",
          );
          _activateWalletSnapshot(authState.userProfile?.wallet);
        }
      }
    });
  }

  //This creates the snapshot to listen user's wallet document if exists
  void _activateWalletSnapshot(String? id) {
    emit(WalletState.loading());
    debugPrint("Wallet is Loading");
    // close previous connection
    _walletSubscription?.cancel();

    //Snapshot creates
    _walletSubscription = _firestore
        .collection('wallets')
        .doc(id)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final walletData = WalletModel.fromFirestore(snapshot.data()!);
              initialized = true;
              emit(WalletState.initialized(walletData));
              debugPrint("Wallet information updated");
            } else {
              debugPrint("Wallet doesn't exist");
            }
          },
          onError: (error) {
            debugPrint(error.toString());
          },
        );
  }

  //Initilialize the payment
  Future<void> stripePayment(double? amount, VoidCallback? onNext) async {
    debugPrint("Amount before send: ${amount?.toInt()}");
    try {
      final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('createStripePayment')
          .call({'amount': amount?.toInt(), 'currency': 'usd'});

      final clientSecret = result.data['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Migozz App',
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(),
          ),
        ),
      );

      await displayPaymentSheet();

      if(onNext != null){
        onNext();
      }
      
    } on FirebaseFunctionsException catch (e) {
      debugPrint("Código: ${e.code}");
      debugPrint("Mensaje: ${e.message}");
    }
  }

  //Wait for the payment result in the instance of stripe, here we decide what to do next
  Future<void> displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();

      debugPrint("¡Pago completado con éxito!");
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        debugPrint("El usuario canceló el pago");
      } else {
        debugPrint("Error de Stripe: ${e.error.localizedMessage}");
      }
    } catch (e) {
      debugPrint("Error inesperado: $e");
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    _walletSubscription?.cancel();
    return super.close();
  }
}
