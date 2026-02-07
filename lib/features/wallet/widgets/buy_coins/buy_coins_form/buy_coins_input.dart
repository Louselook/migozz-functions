import 'package:flutter/material.dart';
import 'package:migozz_app/features/wallet/cubit/buy_coins_cubit/buy_coins_cubit.dart';
import 'package:migozz_app/features/wallet/cubit/buy_coins_cubit/buy_coins_state.dart';
import 'package:migozz_app/features/wallet/widgets/wallet_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BuyCoinsInput extends StatefulWidget {
  const BuyCoinsInput({super.key});

  @override
  State<BuyCoinsInput> createState() => _BuyCoinsInputState();
}

class _BuyCoinsInputState extends State<BuyCoinsInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final buyCoinsCubit = context.read<BuyCoinsCubit>();

    return BlocListener<BuyCoinsCubit, BuyCoinsState>(
      listenWhen: (prev, curr) => prev.amount != curr.amount,
      listener: (context, state) {
        if (_controller.text != state.amount.toString()) {
          _controller.text = state.amount!.toStringAsFixed(0);

          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        }
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: WalletBoxStyles().containerBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Custom Amount",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: WalletBoxStyles().inputBackgroud,
              child: TextField(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                keyboardType: TextInputType.number,
                controller: _controller,
                onChanged: (value) {
                  final doubleValue = double.tryParse(value) ?? 0;
                  buyCoinsCubit.updateAmount(doubleValue);
                },
                decoration: InputDecoration(
                  prefixText: r"$ ",
                  prefixStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  border: InputBorder.none,
                  hintText: "0",
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
