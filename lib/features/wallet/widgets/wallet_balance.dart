import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/wallet/cubit/wallet_cubit.dart';
import 'package:migozz_app/features/wallet/cubit/wallet_state.dart';
import 'package:migozz_app/features/wallet/widgets/transaction_button.dart';

class WalletBalance extends StatelessWidget {
  const WalletBalance({super.key});

  @override
  Widget build(BuildContext context) {
    return (BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        final balance = state.walletData != null
            ? state.walletData!.totalBalance.toString()
            : "0";

        return (Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(12, 226, 226, 226),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color.fromARGB(76, 255, 255, 255),
              width: 0.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsetsGeometry.directional(
                  start: 24,
                  top: 24,
                  bottom: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Available Balance",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          balance,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "MigoCoins",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Fila de botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 6,
                children: [
                  TransactionButton(
                    icon: Icons.money_outlined,
                    text: "Deposit Funds",
                    colors: [Color.fromARGB(255, 87, 156, 235), Color.fromARGB(255, 13, 115, 173)],
                  ),

                  TransactionButton(
                    icon: Icons.account_balance_wallet_outlined,
                    text: "Withdraw Funds",
                    colors: [Color(0xFFE040FB), Color(0xFFF48FB1)],
                  ),
                  
                  TransactionButton(
                    icon: Icons.send,
                    text: "Send funds",
                    colors: [Color.fromARGB(255, 52, 160, 97), Color.fromARGB(255, 10, 117, 51)],
                  ),
                ],
              ),

              SizedBox(height: 20),
            ],
          ),
        ));
      },
    ));
  }
}
