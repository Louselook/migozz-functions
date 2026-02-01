import 'package:equatable/equatable.dart';

// Definimos el semáforo de la Wallet
enum ConversionStatus { initial, loading, initialized, error, empty }

class ConversionState extends Equatable {
  final ConversionStatus status;
  final double? conversion;
  final String? errorMessage;

  const ConversionState({
    required this.status,
    required this.conversion,
    this.errorMessage,
  });

  const ConversionState.initial()
      : status = ConversionStatus.initial,
        conversion = null,
        errorMessage = null;

  const ConversionState.loading()
      : status = ConversionStatus.loading,
        conversion = null,
        errorMessage = null;

  const ConversionState.initialized(double value)
      : status = ConversionStatus.initialized,
        conversion = value,
        errorMessage = null;

  const ConversionState.error(String message)
      : status = ConversionStatus.error,
        conversion = null,
        errorMessage = message;

  ConversionState copyWith({
    ConversionStatus? status,
    double? conversion,
    String? errorMessage,
  }) {
    return ConversionState(
      status: status ?? this.status,
      conversion: conversion ?? this.conversion,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isLoading => status == ConversionStatus.loading;
  bool get hasData => status == ConversionStatus.initialized && conversion != null;
  bool get errorLoading => status == ConversionStatus.error;

  @override
  List<Object?> get props => [status, conversion, errorMessage];
}