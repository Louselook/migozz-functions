import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_contact_info_bottom_sheet.dart';
import 'package:migozz_app/features/profile/components/utils/alert_general.dart';
import 'section_percentage_header.dart';

class ContactInfoSection extends StatelessWidget {
  final bool isOwnProfile;
  final UserDTO user;
  final int sectionPercentage;
  final bool isCompleted;

  const ContactInfoSection({
    super.key,
    required this.isOwnProfile,
    required this.user,
    this.sectionPercentage = 0,
    this.isCompleted = false,
  });

  String _getFieldName(ContactType type) {
    switch (type) {
      case ContactType.website:
        return 'contactWebsite';
      case ContactType.phone:
        return 'contactPhone';
      case ContactType.email:
        return 'contactEmail';
    }
  }

  Future<void> _deleteContactInfo(
    BuildContext context,
    ContactType type,
  ) async {
    final authCubit = context.read<AuthCubit>();
    final editCubit = context.read<EditCubit>();
    final userId = authCubit.state.firebaseUser?.uid;

    if (userId == null) return;

    try {
      await editCubit.saveUserProfileField(
        userId: userId,
        updatedFields: {_getFieldName(type): null},
      );

      if (context.mounted) {
        AlertGeneral.show(
          context,
          1,
          message: 'profile.customization.contact.infodeleted'.tr(),
        );
      }
    } catch (e) {
      if (context.mounted) {
        AlertGeneral.show(
          context,
          4,
          message: 'profile.customization.contact.infoDeleteError'.tr(),
        );
      }
    }
  }

  Future<void> _addOrEditContactInfo(
    BuildContext context,
    ContactType type,
    String? currentValue,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddContactInfoBottomSheet(
        type: type,
        currentValue: currentValue,
        onDelete: currentValue != null && currentValue.isNotEmpty
            ? () => _deleteContactInfo(context, type)
            : null,
        onSave: (value) async {
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
              updatedFields: {_getFieldName(type): value},
            );

            if (context.mounted) {
              AlertGeneral.show(
                context,
                1,
                message: 'profile.customization.contact.infoAdded'.tr(),
              );
            }
          } catch (e) {
            if (context.mounted) {
              AlertGeneral.show(
                context,
                4,
                message: 'profile.customization.contact.infoAddError'.tr(),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _launchContact(String? value, ContactType type) async {
    if (value == null || value.isEmpty) return;

    Uri? uri;
    switch (type) {
      case ContactType.website:
        uri = Uri.parse(value);
        break;
      case ContactType.phone:
        uri = Uri.parse('tel:$value');
        break;
      case ContactType.email:
        uri = Uri.parse('mailto:$value');
        break;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if any contact info is filled
    final hasAnyContact =
        (user.contactWebsite != null && user.contactWebsite!.isNotEmpty) ||
        (user.contactPhone != null && user.contactPhone!.isNotEmpty) ||
        (user.contactEmail != null && user.contactEmail!.isNotEmpty);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionPercentageHeader(
            title: 'profile.customization.contact.title'.tr(),
            percentage: sectionPercentage,
            isCompleted: isCompleted,
            trailing: GestureDetector(
              onTap: () {
                // TODO: Toggle visibility
                debugPrint('Toggle contact info visibility');
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
          const SizedBox(height: 4),
          Text(
            'profile.customization.contact.helperText'.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 10),
          _buildContactItem(
            context: context,
            icon: Icons.language,
            label: 'profile.customization.contact.website'.tr(),
            value: user.contactWebsite,
            type: ContactType.website,
            isOwnProfile: isOwnProfile,
          ),
          const SizedBox(height: 8),
          _buildContactItem(
            context: context,
            icon: Icons.phone,
            label: 'profile.customization.contact.number'.tr(),
            value: user.contactPhone,
            type: ContactType.phone,
            isOwnProfile: isOwnProfile,
          ),
          const SizedBox(height: 8),
          _buildContactItem(
            context: context,
            icon: Icons.email_outlined,
            label: 'profile.customization.contact.email'.tr(),
            value: user.contactEmail,
            type: ContactType.email,
            isOwnProfile: isOwnProfile,
          ),
          // Show CTA if no contact info and is own profile
          if (isOwnProfile && !hasAnyContact) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () =>
                  _addOrEditContactInfo(context, ContactType.email, null),
              child: Text(
                'profile.customization.contact.addCta'.tr(),
                style: TextStyle(
                  color: Colors.purple.shade300,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String? value,
    required ContactType type,
    required bool isOwnProfile,
  }) {
    final hasValue = value != null && value.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: hasValue && !isOwnProfile
                ? () => _launchContact(value, type)
                : null,
            child: Row(
              children: [
                Icon(icon, color: Colors.grey.shade400, size: 15),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    hasValue ? value : label,
                    style: TextStyle(
                      color: hasValue ? Colors.white : Colors.white70,
                      fontSize: 11,
                      fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isOwnProfile)
          GestureDetector(
            onTap: () => _addOrEditContactInfo(context, type, value),
            child: Icon(
              hasValue ? Icons.edit : Icons.add,
              color: Colors.white,
              size: 15,
            ),
          ),
      ],
    );
  }
}
