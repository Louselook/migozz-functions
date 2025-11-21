import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
// ignore: depend_on_referenced_packages
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class ProfileTutorial {
  static void showTutorial(
    BuildContext context,
    TutorialKeys keys, {
    VoidCallback? onFinish, // Agregar callback opcional
  }) {
    const tutorialTextStyle = TextStyle(color: Colors.white, fontSize: 16);
    final targets = <TargetFocus>[
      TargetFocus(
        identify: "search_screen",
        keyTarget: keys.searchScreenKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "profile.tutorial.searchStep".tr(),
                  style: tutorialTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "play_button",
        keyTarget: keys.playButtonKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "profile.tutorial.audioStep".tr(),
                  style: tutorialTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "share_button",
        keyTarget: keys.shareButtonKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("profile.tutorial.QRStep".tr(), style: tutorialTextStyle),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "home_button",
        keyTarget: keys.profileScreenKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "profile.tutorial.homeStep".tr(),
                  style: tutorialTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "stats_button",
        keyTarget: keys.statScreenKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "profile.tutorial.statsStep".tr(),
                  style: tutorialTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "config_button",
        keyTarget: keys.editScreenKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "profile.tutorial.settings".tr(),
                  style: tutorialTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black.withValues(alpha: 0.7),
      textSkip: "Skip",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        debugPrint("🎉 Tutorial finalizado");
        onFinish?.call(); // Llamar al callback si existe
      },
      onSkip: () {
        debugPrint("⏭️ Tutorial saltado");
        onFinish?.call(); // También marcar como completado si lo salta
        return true;
      },
      onClickTarget: (target) {
        debugPrint("👆 Click en: ${target.identify}");
      },
    ).show(context: context);
  }
}
