import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/presentation/edit/modules/edit_audio.dart';
import 'section_percentage_header.dart';

class AudioSection extends StatelessWidget {
  final bool isOwnProfile;
  final String? voiceNoteUrl;
  final int sectionPercentage;
  final bool isCompleted;

  const AudioSection({
    super.key,
    required this.isOwnProfile,
    this.voiceNoteUrl,
    this.sectionPercentage = 11,
    this.isCompleted = false,
  });

  Future<void> _editAudio(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditRecordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = voiceNoteUrl != null && voiceNoteUrl!.isNotEmpty;

    return GestureDetector(
      onTap: isOwnProfile ? () => _editAudio(context) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionPercentageHeader(
              title: 'edit.presentation.record'.tr(),
              percentage: sectionPercentage,
              isCompleted: isCompleted,
              trailing: isOwnProfile
                  ? Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Icon(
                    hasAudio ? Icons.play_circle_filled : Icons.mic_none,
                    color: hasAudio ? Colors.green.shade400 : Colors.white70,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasAudio
                            ? 'edit.editAudio.recorded'.tr()
                            : 'edit.editAudio.noRecording'.tr(),
                        style: TextStyle(
                          color: hasAudio ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: hasAudio ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                      if (!hasAudio && isOwnProfile) ...[
                        const SizedBox(height: 2),
                        Text(
                          'edit.editAudio.tapToRecord'.tr(),
                          style: TextStyle(
                            color: Colors.purple.shade300,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

