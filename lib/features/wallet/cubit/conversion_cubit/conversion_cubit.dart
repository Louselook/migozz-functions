import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:migozz_app/features/wallet/cubit/conversion_cubit/conversion_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConversionCubit extends Cubit<ConversionState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ///I created this bool to prevent the creation of multiple snapshots when the AuthState change
  bool initialized = false;

  StreamSubscription? _conversionSubscription;

  ConversionCubit()
    : super(ConversionState.initial()) {
    //Activate snapshot on creation
    _activateConversionSnapshot();
  }

  //This creates the snapshot to listen financial document if exists
  void _activateConversionSnapshot() {
    emit(ConversionState.loading());
    debugPrint("Conversion rate is Loading");
    // close previous connection
    _conversionSubscription?.cancel();

    //Snapshot creates
    _conversionSubscription = _firestore
        .collection('financial')
        .doc("conversion_rate")
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final conversion = (snapshot.data()?['value'] ?? 0).toDouble();
              initialized = true;
              emit(ConversionState.initialized(conversion));
              debugPrint("Conversion rate loaded");
            } else {
              debugPrint("Conversion document doesn't exists");
            }
          },
          onError: (error) {
            debugPrint(error.toString());
          },
        );
  }

  @override
  Future<void> close() {
    _conversionSubscription?.cancel();
    return super.close();
  }
}
