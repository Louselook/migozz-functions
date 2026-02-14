import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:migozz_app/features/wallet/cubit/conversion_cubit/conversion_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/wallet/model/pay_method_model.dart';

class ConversionCubit extends Cubit<ConversionState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool initialized = false;

  StreamSubscription? _conversionSubscription;

  ConversionCubit() : super(ConversionState.initial()) {
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
          (snapshot)async{
            if (snapshot.exists) {
              final conversion = (snapshot.data()?['value'] ?? 0).toDouble();

              List<PayMethodModel> currentMethods = state.methods ?? [];
              if(!initialized){
                currentMethods = await _savePaymentMethods();
              }
              
              debugPrint("loaded methods: ${currentMethods.length.toString()}");

              emit(
                state.copyWith(
                  status: ConversionStatus.initialized,
                  conversion: conversion,
                  methods: currentMethods, // Aseguramos que los métodos se mantengan
                ),
              );

            } else {
              debugPrint("Conversion document doesn't exists");
            }
          },
          onError: (error) {
            debugPrint(error.toString());
          },
        );
  }

  //Save the payment methods

  Future<List<PayMethodModel>> _savePaymentMethods() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection("financial")
          .doc("payment_methods")
          .get();

      if (doc.exists) {
        final data = doc.data();
        final list = PayMethodModel.fromList(data?["methods"]);

        return list;
      }
    } catch (e) {
      debugPrint("Error loading methods: $e");
    }

    return [];
  }

  @override
  Future<void> close() {
    _conversionSubscription?.cancel();
    return super.close();
  }
}
