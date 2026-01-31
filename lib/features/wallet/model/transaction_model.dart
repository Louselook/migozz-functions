import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String? walletFrom;
  final String walletTo;
  final double amount;
  final int type;
  final DateTime created;

  TransactionModel({
    required this.id,
    this.walletFrom,
    required this.walletTo,
    required this.amount,
    required this.type,
    required this.created,
  });

  //Transform firestore map to WalletModel
  static List<TransactionModel> fromList(List<Map<String, dynamic>> data) {
    return data.map(
      (transaction) => TransactionModel(
        id: transaction['id'],
        walletTo: transaction['walletTo'],
        amount: (transaction['amount'] ?? 0).toDouble(),
        type: transaction['type'],
        created: (transaction['created'] as Timestamp).toDate(),
      ),
    ).toList();
  }
}
