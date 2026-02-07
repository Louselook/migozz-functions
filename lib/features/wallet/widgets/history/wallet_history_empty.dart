import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/assets_constants.dart';

class WalletHistoryEmpty extends StatelessWidget {
  const WalletHistoryEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(AssetsConstants.walletEmpty),
        SizedBox(height: 20),
        Text(style: TextStyle(fontSize: 15, color: Color(0xFF404040)), "wallet.textEmpty1".tr()),
        Text(style: TextStyle(fontSize: 15, color: Color(0xFF404040)), "wallet.textEmpty2".tr()),
        SizedBox(height: 20),
        Container(
          width: 140,
          height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF89A44),
                Color(0xFFD43AB6),
                Color(0xFF9321BD)
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(
              25,
            ),
          ),
          child: ElevatedButton(
            onPressed: () {
              context.pushNamed("buy-coins");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors
                  .transparent, // Fondo transparente para ver el degradado
              shadowColor: Colors.transparent, // Sin sombra para un look plano
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Buy coins',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
