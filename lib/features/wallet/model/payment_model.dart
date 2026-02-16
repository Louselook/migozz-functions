class PaymentModel {
  final double? amount;
  final int transactionType;
  final int method;

  const PaymentModel({
    this.amount,
    required this.transactionType,
    required this.method
  });
}