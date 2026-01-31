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
}
