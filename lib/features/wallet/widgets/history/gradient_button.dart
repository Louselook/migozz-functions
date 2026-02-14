import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WalletGradientButton extends StatelessWidget{
  final VoidCallback action;
  final String text;
  final double? fontSize;
  const WalletGradientButton({super.key, required this.action, required this.text, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return(
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
            onPressed: action,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors
                  .transparent, // Fondo transparente para ver el degradado
              shadowColor: Colors.transparent, // Sin sombra para un look plano
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize ?? 12.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        )
    );
  }

}