import 'package:equatable/equatable.dart';

enum BuyCoinsStatus { initial, paymentMethod, successfull, failed }

class BuyCoinsState extends Equatable {
  final BuyCoinsStatus status;
  final double? amount;
  final double? total;
  final String? errorMessage;

  const BuyCoinsState({
    required this.status,
    this.amount,
    this.total,
    this.errorMessage,
  });

  const BuyCoinsState.initial()
      : status = BuyCoinsStatus.initial,
        amount = 0,
        total = 0,
        errorMessage = null;

  const BuyCoinsState.paymentMethod(double data)
      : status = BuyCoinsStatus.paymentMethod,
        amount = data,
        total = 0,
        errorMessage = null;

  const BuyCoinsState.successfull()
      : status = BuyCoinsStatus.successfull,
        amount = null,
        total = null,
        errorMessage = null;

  const BuyCoinsState.failed(String message)
      : status = BuyCoinsStatus.failed,
        total = null,
        amount = null,
        errorMessage = message;

  BuyCoinsState copyWith({
    BuyCoinsStatus? status,
    double? amount,
    double? total,
    String? errorMessage,
  }) {
    return BuyCoinsState(
      status: status ?? this.status,
      amount: amount ?? this.amount,
      total: total ?? this.total,
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