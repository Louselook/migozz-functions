import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/atomics/text.dart';
import 'package:migozz_app/features/register/user_details/components/down_buttons.dart';

// va en eel chat
class PicAudioStep extends StatelessWidget {
  final PageController controller;
  const PicAudioStep({super.key, required this.controller});

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
            Container(
              width: 63,
              height: 63,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.pinkAccent, Colors.pink],
                ),
              ),
              child: IconButton(
                onPressed: () {
                  debugPrint("Mic pressed");
                },
                icon: const Icon(Icons.mic, color: Colors.white, size: 35),
              ),
            ),

            const SizedBox(height: 30),

            // ▶️ Botón Play
            Column(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      debugPrint("Play pressed");
                    },
                    icon: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const SecondaryText(
                  "Play me!",
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),

            const Spacer(),

            // Botones
            downButtons(controller: controller),
          ],
        ),
      ),
    );
  }
}
