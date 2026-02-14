import 'package:equatable/equatable.dart';
import 'package:migozz_app/features/wallet/model/pay_method_model.dart';

// Definimos el semáforo de la Wallet
enum ConversionStatus { initial, loading, initialized, error, empty }

class ConversionState extends Equatable {
  final ConversionStatus status;
  final double? conversion;
  final String? errorMessage;
  final List<PayMethodModel>? methods;

  const ConversionState({
    required this.status,
    required this.conversion,
    this.errorMessage,
    this.methods
  });

  const ConversionState.initial()
      : status = ConversionStatus.initial,
        conversion = null,
        methods = null,
        errorMessage = null;
        

  const ConversionState.loading()
      : status = ConversionStatus.loading,
        conversion = null,
        methods = null,
        errorMessage = null;


  const ConversionState.error(String message)
      : status = ConversionStatus.error,
        conversion = null,
        methods = null,
        errorMessage = message;

  ConversionState copyWith({
    ConversionStatus? status,
    double? conversion,
    String? errorMessage,
    List<PayMethodModel>? methods,
  }) {
    return ConversionState(
      status: status ?? this.status,
      conversion: conversion ?? this.conversion,
      methods: methods ?? this.methods,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => status == ConversionStatus.loading;
  bool get hasData => status == ConversionStatus.initialized && conversion != null;
  bool get errorLoading => status == ConversionStatus.error;

  @override
  List<Object?> get props => [status, conversion, errorMessage];
}