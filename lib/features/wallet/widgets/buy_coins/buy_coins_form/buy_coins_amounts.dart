import 'package:flutter/material.dart';
import 'package:migozz_app/features/wallet/widgets/buy_coins/buy_coins_form/buy_default_value.dart';

class BuyCoinsAmounts extends StatelessWidget {
  static List<double> defaultValues = [5, 10, 25, 50, 100];
  const BuyCoinsAmounts({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 30),
        Text(
          style: TextStyle(color: Color(0xFFFFEFEF), fontSize: 20, fontWeight: FontWeight.w400),
          "Select Amount",
        ),
        SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 5,
          childAspectRatio: 0.9,
          mainAxisSpacing: 0,
          crossAxisSpacing: 10,
          shrinkWrap: true,
          children: [
            ...defaultValues.map((value) {
              return BuyDefaultValue(value: value);
            }),
          ],
        ),
      ],
    );
  }
}
