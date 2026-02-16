import 'package:equatable/equatable.dart';

enum BuyCoinsStatus { initial, paymentMethod, successfull, failed }

class BuyCoinsState extends Equatable {
  final BuyCoinsStatus status;
  final double? amount;
  final double? total;
  final String? errorMessage;
  final int? selectedMethod;
  final bool loadingPayment;

  const BuyCoinsState({
    required this.status,
    this.amount,
    this.total,
    this.selectedMethod,
    this.errorMessage,
    required this.loadingPayment
  });

  const BuyCoinsState.initial({double this.total = 0, double this.amount = 0})
      : status = BuyCoinsStatus.initial,
        selectedMethod = null,
        loadingPayment = false,
        errorMessage = null;

  const BuyCoinsState.paymentMethod({double totalValue = 0, double? amount})
      : status = BuyCoinsStatus.paymentMethod,
        amount = amount ?? totalValue,
        total = totalValue,
        selectedMethod = null,
        loadingPayment = false,
        errorMessage = null;

  const BuyCoinsState.successfull({double this.total = 0})
      : status = BuyCoinsStatus.successfull,
        amount = null,
        loadingPayment = false,
        selectedMethod = null,
        errorMessage = null;

  const BuyCoinsState.failed()
      : status = BuyCoinsStatus.failed,
        total = null,
        amount = null,
        loadingPayment = false,
        selectedMethod = null,
        errorMessage = null;

  BuyCoinsState copyWith({
    BuyCoinsStatus? status,
    double? amount,
    double? total,
    String? errorMessage,
    int? selectedMethod,
    bool? loadingPayment
  }) {
    return BuyCoinsState(
      loadingPayment: loadingPayment ?? this.loadingPayment,
      status: status ?? this.status,
      selectedMethod: selectedMethod ?? this.selectedMethod,
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
  List<Object?> get props => [status, amount, errorMessage, selectedMethod, loadingPayment];
}