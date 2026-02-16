class PaymentModel {
  final double? amount;
  final int transactionType;

  const PaymentModel({
    this.amount,
    required this.transactionType,
  });
}