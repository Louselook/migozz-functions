import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

extension ContextUtils on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}


class WalletModel {
  final String id;
  final String user;
  final double totalBalance;
  final double totalGains;
  final double totalExpense;

  WalletModel({
    required this.id,
    required this.user,
    required this.totalBalance,
    required this.totalGains,
    required this.totalExpense,
  });

  //Transform firestore map to WalletModel
  factory WalletModel.fromFirestore(Map<String, dynamic> data) {
    return WalletModel(
      id: data['id'],
      user: data['user'],
      totalBalance: (data['totalBalance'] ?? 0).toDouble(),
      totalGains: (data['totalGains'] ?? 0).toDouble(),
      totalExpense: (data['totalExpense'] ?? 0).toDouble(),
    );
  }

  static formattedAmount(double? amount) {
    if(amount != null){
      final formatter = NumberFormat.simpleCurrency(decimalDigits: 2);
      return formatter.format(amount);
    }
    return "";
  }

  static getPercentage({double total = 0, double percentage = 0}){
    return percentage * total / 100;
  }
}
