import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/assets_constants.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:migozz_app/features/wallet/model/wallet_model.dart';

class TransactionModel {
  final String id;
  final String? walletFrom;
  final String? fromName;
  final String? toName;
  final String walletTo;
  final double amount;
  final int type;
  final DateTime created;

  TransactionModel({
    required this.id,
    this.walletFrom,
    this.fromName,
    this.toName,
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
        walletFrom: transaction['walletFrom'],
        fromName: transaction["fromName"],
        toName: transaction["toName"],
        amount: (transaction['amount'] ?? 0).toDouble(),
        type: transaction['type'],
        created: (transaction['created'] as Timestamp).toDate(),
      ),
    ).toList();
  }


    static Map<int, dynamic> icons = {
    1: AssetsConstants.depositIcon,
    2: AssetsConstants.sentIcon,
  };

  static titleRender(type, String? from, String? to) {
    switch (type) {
      case 2:
      return "${"wallet.sent".tr()} $to";

      default:
      return "${"wallet.deposit".tr()} $from";
    }
  }

  static amountRender(type, double amount) {
    switch (type) {
      case 2:
      return "-${WalletModel.formattedAmount(amount)}";
      
      default:
      return "+${WalletModel.formattedAmount(amount)}";
    }
  }

  static colorRender(type) {
    switch (type) {
      case 2:
      return Color(0xFFA51A40);

      default:
      return Color(0xFF08A915);
    }
  }
}
