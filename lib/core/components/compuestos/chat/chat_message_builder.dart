import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/compuestos/chat/chat_model.dart';
import 'package:migozz_app/core/components/compuestos/chat/other_message.dart';
import 'package:migozz_app/core/components/compuestos/chat/user_message.dart';
import 'package:migozz_app/core/components/compuestos/chat/picture_options.dart';
import '../../../../features/auth/presentation/register/chat/components/social_card.dart';

class ChatMessageBuilder {
  static Widget buildMessage(Map<String, dynamic> message) {
    // 🔹 Mensajes de imagen (URL o local)
    if (message["type"] == MessageType.pictureCard) {
      final pics = List<Map<String, String>>.from(message["pictures"]);
      return PictureOptions(
        pictures: pics,
        time: message["time"],
        sender: message["other"],
      );
    }

    // 🔹 Mensajes de audio
    if (message["type"] == MessageType.audio) {
      debugPrint('Un audiooooo');
      final audioPath = message["audio"] as String;
      final other = message["other"] == true;
      final playerController = PlayerController();

      return StatefulBuilder(
        builder: (context, setState) {
          Duration currentDuration = Duration.zero;
          Duration maxDuration = Duration.zero;
          bool isPlaying = false;

          playerController.onCurrentDurationChanged.listen((durationMs) {
            setState(() {
              currentDuration = Duration(milliseconds: durationMs);
            });
          });

          playerController.onCompletion.listen((_) {
            setState(() {
              isPlaying = false;
              currentDuration = maxDuration;
            });
          });

          return Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(left: 130, bottom: 15),
            decoration: BoxDecoration(
              color: other ? Colors.grey[200] : Colors.blue[500],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    if (isPlaying) {
                      await playerController.stopPlayer();
                      setState(() => isPlaying = false);
                    } else {
                      await playerController.preparePlayer(
                        path: audioPath,
                        shouldExtractWaveform: true,
                      );
                      maxDuration = Duration(
                        milliseconds: playerController.maxDuration,
                      );
                      await playerController.startPlayer();
                      setState(() => isPlaying = true);
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: other ? Colors.blue[500] : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.stop : Icons.play_arrow,
                      color: other ? Colors.white : Colors.blue[500],
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AudioFileWaveforms(
                    playerController: playerController,
                    waveformType: WaveformType.fitWidth,
                    size: const Size(double.infinity, 30),
                    playerWaveStyle: PlayerWaveStyle(
                      fixedWaveColor: other
                          ? Colors.grey[400]!
                          : Colors.white.withValues(alpha: 0.5),
                      liveWaveColor: other ? Colors.blue[500]! : Colors.white,
                      waveThickness: 2.5,
                      spacing: 3,
                      showBottom: true,
                      showTop: true,
                      scaleFactor: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${currentDuration.inMinutes}:${(currentDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                  style: TextStyle(
                    fontSize: 12,
                    color: other ? Colors.grey[600] : Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // 🔹 Mensajes de texto y social cards
    if (message["other"] == true) {
      if (message["social"] == true) {
        return buildSocialCard(
          message["platform"],
          message["stats"],
          message["emoji"],
          message["time"],
        );
      }

      return OtherMessage(
        text: message["text"] ?? "",
        time: message["time"] ?? "",
      );
    } else {
      return UserMessage(text: message["text"] ?? "");
    }
  }
}
