import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'edit_bio_bottom_sheet.dart';
import 'package:migozz_app/features/profile/components/utils/alert_general.dart';
import 'section_percentage_header.dart';

class BioSection extends StatefulWidget {
  final String bio;
  final bool isOwnProfile;
  final int profilePercentage;
  final int sectionPercentage;
  final bool isCompleted;

  const BioSection({
    super.key,
    required this.bio,
    required this.isOwnProfile,
    this.profilePercentage = 100,
    this.sectionPercentage = 20,
    this.isCompleted = false,
  });

  @override
  State<BioSection> createState() => _BioSectionState();
}

class _BioSectionState extends State<BioSection> {
  Future<void> _editBio(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditBioBottomSheet(
        currentBio: widget.bio,
        onSave: (newBio) async {
          final authCubit = context.read<AuthCubit>();
          final editCubit = context.read<EditCubit>();
          final userId = authCubit.state.firebaseUser?.uid;

          if (userId == null) {
            AlertGeneral.show(
              context,
              4,
              message: 'edit.validations.errorUserLogin'.tr(),
            );
            return;
          }

          try {
            await editCubit.saveUserProfileField(
              userId: userId,
              updatedFields: {'bio': newBio},
            );

            if (context.mounted) {
              AlertGeneral.show(
                context,
                1,
                message: 'profile.customization.bio.success'.tr(),
              );
            }
          } catch (e) {
            if (context.mounted) {
              AlertGeneral.show(
                context,
                4,
                message: '${'profile.customization.bio.errorUpdate'.tr()}$e',
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isOwnProfile ? () => _editBio(context) : null,
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
              title: 'profile.customization.bio.label'.tr(),
              percentage: widget.sectionPercentage,
              isCompleted: widget.isCompleted,
              showEditIcon: true,
              onEditTap: () => _editBio(context),
              trailing: GestureDetector(
                onTap: () {
                  // TODO: Toggle visibility
                  debugPrint('Toggle bio visibility');
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove_red_eye_outlined,
                    color: Colors.white70,
                    size: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.bio.isEmpty
                  ? 'profile.customization.bio.add'.tr()
                  : widget.bio,
              style: TextStyle(
                color: widget.bio.isEmpty ? Colors.white38 : Colors.white70,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _editBio(context),
              child: Text(
                'profile.customization.bio.editCta'.tr(),
                style: TextStyle(
                  color: Colors.purple.shade300,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
