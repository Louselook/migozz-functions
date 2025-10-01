import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/components/user_details_button.dart';

// va en eel chat
class PicAudioStep extends StatelessWidget {
  // final PageController controller;
  // const PicAudioStep({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const PrimaryText("Add Profile Pic"),
            const SizedBox(height: 20),

            // 📸 Contenedor para foto
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.secondaryText.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_outline_sharp,
                  size: 100,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SecondaryText(
              "Record Your Voicenote",
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            const SizedBox(height: 18),

            // 🎤 Botón micrófono
            Column(
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryPink,
                  ),
                  child: IconButton(
                    onPressed: () {
                      debugPrint("Mic pressed");
                    },
                    icon: const Icon(Icons.mic, color: Colors.white, size: 130),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),

            const SizedBox(height: 30),

            // ▶️ Botón Play
            Container(
              constraints: const BoxConstraints(
                maxWidth: 250,
                minHeight: 120,
                maxHeight: 180,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: const Color.fromARGB(96, 50, 50, 50),
                border: Border.all(
                  color: const Color.fromARGB(255, 63, 63, 63),
                  width: 0.7,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SecondaryText(
                    "Listen to your audio",
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    height: MediaQuery.of(context).size.width * 0.25,
                    constraints: const BoxConstraints(
                      minWidth: 100,
                      maxWidth: 300,
                      minHeight: 100,
                      maxHeight: 300,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryPink,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        debugPrint("Play pressed");
                      },
                      icon: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width * 0.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Botones
            // userDetailsButton(
            // controller: controller,
            //   context: context,
            //   action: UserDetailsAction.next,
            // ),
          ],
        ),
      ),
    );
  }
}
