import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class TitleModel {
  final String title;
  final bool? gradient;
  const TitleModel({required this.title, this.gradient});
}

class BuyTitle extends StatelessWidget {
  final List<TitleModel> texts;
  const BuyTitle({super.key, required this.texts});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 5,
      children: [
        ...texts.map((text) {
          if (text.gradient == true) {
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [Color(0xFF9022BA), Color(0xFFDC44AA)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ).createShader(bounds);
              },
              child: Text(
                text.title,
                style: TextStyle(
                  fontSize: 26,
                  color: Colors
                      .white, // El color base debe ser blanco para que el degradado brille
                ),
              ),
            );
          }

          return Text(
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 26,

            ),
            text.title,
          );
        }),
      ],
    );
  }
}
