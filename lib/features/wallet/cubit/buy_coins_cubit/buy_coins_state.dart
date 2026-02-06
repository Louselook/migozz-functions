import 'package:equatable/equatable.dart';

enum BuyCoinsStatus { initial, paymentMethod, successfull, failed }

class BuyCoinsState extends Equatable {
  final BuyCoinsStatus status;
  final double? amount;
  final String? errorMessage;

  const BuyCoinsState({
    required this.status,
    this.amount,
    this.errorMessage,
  });

  const BuyCoinsState.initial()
      : status = BuyCoinsStatus.initial,
        amount = null,
        errorMessage = null;

  const BuyCoinsState.paymentMethod(double data)
      : status = BuyCoinsStatus.paymentMethod,
        amount = data,
        errorMessage = null;

  const BuyCoinsState.successfull()
      : status = BuyCoinsStatus.successfull,
        amount = null,
        errorMessage = null;

  const BuyCoinsState.failed(String message)
      : status = BuyCoinsStatus.failed,
        amount = null,
        errorMessage = message;

  BuyCoinsState copyWith({
    BuyCoinsStatus? status,
    double? amount,
    String? errorMessage,
  }) {
    return BuyCoinsState(
      status: status ?? this.status,
      amount: amount ?? this.amount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get inititialized => status == BuyCoinsStatus.initial;
  bool get inMethods => status == BuyCoinsStatus.paymentMethod;
  bool get failed => status == BuyCoinsStatus.failed;
  bool get successfull => status == BuyCoinsStatus.successfull;

  @override
  List<Object?> get props => [status, amount, errorMessage];
}