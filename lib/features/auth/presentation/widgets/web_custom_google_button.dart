import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:migozz_app/core/assets_constants.dart';

class WebCustomGoogleButton extends StatelessWidget {
  final VoidCallback onPress;
  final String? icon;
  final String? text;
  const WebCustomGoogleButton({super.key, required this.onPress, this.icon, this.text});

  @override
  Widget build(BuildContext context) {
    return (TextButton(
      style: TextButton.styleFrom(
        side: BorderSide(color: Color.fromARGB(255, 141, 141, 141), width: 1),
        padding: EdgeInsetsGeometry.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.all(Radius.circular(30)),
        ),
      ),
      onPressed: onPress,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 10,
        children: [
          SizedBox(
            height: 16.h,
            width: 16.h,
            child: SvgPicture.asset(icon ?? AssetsConstants.googleIcon)
          ),
          Text(
            style: TextStyle(color: Color.fromARGB(255, 209, 209, 209)),
            text ?? "login.presentation.google".tr(),
          ),
        ],
      ),
    ));
  }
}
