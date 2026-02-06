class BuyCoinsModel {
  double amount;
  String wallet;
  String user;

  BuyCoinsModel({
    required this.amount, 
    required this.user, 
    required this.wallet
  });


  Map<String, dynamic> modelToMap(BuyCoinsModel data){
    return {
      "amount": data.amount,
      "wallet": data.wallet,
      "user": data.user,
    };
  }
  
}