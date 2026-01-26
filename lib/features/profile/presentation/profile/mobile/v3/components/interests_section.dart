import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/presentation/edit/modules/edit_my_interest.dart';
import 'section_percentage_header.dart';

class InterestsSection extends StatelessWidget {
  final bool isOwnProfile;
  final Map<String, List<String>> interests;
  final int sectionPercentage;
  final bool isCompleted;

  const InterestsSection({
    super.key,
    required this.isOwnProfile,
    required this.interests,
    this.sectionPercentage = 11,
    this.isCompleted = false,
  });

  Future<void> _editInterests(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditInterestsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasInterests = interests.isNotEmpty;

    return GestureDetector(
      onTap: isOwnProfile ? () => _editInterests(context) : null,
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
              title: 'edit.presentation.interest'.tr(),
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
                    hasInterests ? Icons.favorite : Icons.handshake_outlined,
                    color: hasInterests ? Colors.pink.shade400 : Colors.white70,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!hasInterests) ...[
                        Text(
                          'edit.editInterest.noInterests'.tr(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        if (isOwnProfile) ...[
                          const SizedBox(height: 2),
                          Text(
                            'edit.editInterest.tapToAdd'.tr(),
                            style: TextStyle(
                              color: Colors.purple.shade300,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                      if (hasInterests) ...[
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: interests.keys.take(3).map((category) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (isOwnProfile) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade400,
                                  Colors.pink.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'edit.editInterest.addMore'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

