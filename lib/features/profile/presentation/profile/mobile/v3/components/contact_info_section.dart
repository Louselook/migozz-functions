import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_contact_info_bottom_sheet.dart';
import 'package:migozz_app/features/profile/components/utils/alertGeneral.dart';

class ContactInfoSection extends StatelessWidget {
  final bool isOwnProfile;
  final UserDTO user;

  const ContactInfoSection({
    super.key,
    required this.isOwnProfile,
    required this.user,
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
          message: 'Contact info deleted successfully',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AlertGeneral.show(
          context,
          4,
          message: 'Error deleting contact info: $e',
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
            AlertGeneral.show(context, 4, message: 'Error: User not logged in');
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
                message: 'Contact info saved successfully',
              );
            }
          } catch (e) {
            if (context.mounted) {
              AlertGeneral.show(
                context,
                4,
                message: 'Error saving contact info: $e',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Contact Info',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+5 %',
                    style: TextStyle(
                      color: Colors.purple.shade400,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Toggle visibility
                  debugPrint('Toggle contact info visibility');
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
          const SizedBox(height: 10),
          _buildContactItem(
            context: context,
            icon: Icons.language,
            label: 'Website',
            value: user.contactWebsite,
            type: ContactType.website,
            isOwnProfile: isOwnProfile,
          ),
          const SizedBox(height: 8),
          _buildContactItem(
            context: context,
            icon: Icons.phone,
            label: 'Number',
            value: user.contactPhone,
            type: ContactType.phone,
            isOwnProfile: isOwnProfile,
          ),
          const SizedBox(height: 8),
          _buildContactItem(
            context: context,
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.contactEmail,
            type: ContactType.email,
            isOwnProfile: isOwnProfile,
          ),
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
