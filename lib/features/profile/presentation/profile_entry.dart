// lib/features/profile/presentation/profile/profile_entry.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/utils/platform_utils.dart';
import 'package:migozz_app/features/profile/presentation/profile/mobile/profile_screen.dart'
    as mobile_v1;
// import 'package:migozz_app/features/profile/presentation/profile/mobile/v3/profile_screen_v3.dart'
//     as mobile_v3;
import 'package:migozz_app/features/profile/presentation/profile/shared/profile_wrapper.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/profile_page.dart'
    as web_v1;
import 'package:migozz_app/features/profile/presentation/profile/web/v2/profile_page_v2.dart'
    as web_v2;
import 'package:migozz_app/features/profile/presentation/profile/web/v3/profile_page_v3.dart'
    as web_v3;
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';
import 'package:migozz_app/features/tutorial/profile/profile_tutorial_keys.dart';

class ProfileEntry extends StatelessWidget {
  final TutorialKeys tutorialKeys;
  final ProfileTutorialKeys? profileTutorialKeys;

  const ProfileEntry({
    super.key,
    required this.tutorialKeys,
    this.profileTutorialKeys,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileWrapper(
      tutorialKeys: tutorialKeys,
      profileTutorialKeys: profileTutorialKeys,
      builder: (context, authState, receivedKeys, receivedProfileKeys) {
        final user = authState.userProfile;
        if (user == null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'profile.presentation.noAuthenticatedUser'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final profileVersion = 3;

        if (PlatformUtils.isWeb) {
          switch (profileVersion) {
            case 2:
              return web_v2.WebProfileContentV2(
                user: user,
                tutorialKeys: receivedKeys,
              );
            case 3:
              return web_v3.WebProfileContentV3(
                user: user,
                tutorialKeys: receivedKeys,
              );
            default:
              return web_v1.WebProfileContent(
                user: user,
                tutorialKeys: receivedKeys,
              );
          }
        } else {
          switch (profileVersion) {
            case 3:
              return mobile_v1.MobileProfileContent(
                user: user,
                tutorialKeys: receivedKeys,
                profileTutorialKeys: receivedProfileKeys,
              );
            default:
              return mobile_v1.MobileProfileContent(
                user: user,
                tutorialKeys: receivedKeys,
                profileTutorialKeys: receivedProfileKeys,
              );
          }
        }
      },
    );
  }
}
