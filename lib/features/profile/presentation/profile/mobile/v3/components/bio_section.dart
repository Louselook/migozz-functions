import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'edit_bio_bottom_sheet.dart';
import 'package:migozz_app/features/profile/components/utils/alertGeneral.dart';

class BioSection extends StatelessWidget {
  final String bio;
  final bool isOwnProfile;

  const BioSection({super.key, required this.bio, required this.isOwnProfile});

  Future<void> _editBio(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditBioBottomSheet(
        currentBio: bio,
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
                message:
                    '${'profile.customization.bio.errorUpdate'.tr()}$e',
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
      onTap: isOwnProfile ? () => _editBio(context) : null,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'profile.customization.bio.label'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.verticalPinkPurple,
                      ),
                      child: Icon(Icons.edit, color: Colors.white, size: 7),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: Toggle visibility
                    debugPrint('Toggle bio visibility');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.remove_red_eye_outlined,
                      color: Colors.white70,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              bio.isEmpty ? 'profile.customization.bio.add'.tr() : bio,
              style: TextStyle(
                color: bio.isEmpty ? Colors.white38 : Colors.white70,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
