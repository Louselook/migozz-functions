import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_link_bottom_sheet.dart';
import 'package:migozz_app/features/profile/components/utils/alertGeneral.dart';

class FeaturedLinksSection extends StatelessWidget {
  final bool isOwnProfile;
  final UserDTO user;

  const FeaturedLinksSection({
    super.key,
    required this.isOwnProfile,
    required this.user,
  });

  Future<void> _addLink(BuildContext context) async {
    // Check if already has 2 links
    final currentLinks = user.featuredLinks ?? [];
    if (currentLinks.length >= 2) {
      AlertGeneral.show(context, 3, message: 'profile.customization.links.maximumLinks'.tr());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.customization.links.maximumLinks'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddLinkBottomSheet(
        onLinkAdded: (url, label) async {
          final authCubit = context.read<AuthCubit>();
          final editCubit = context.read<EditCubit>();
          final userId = authCubit.state.firebaseUser?.uid;

          if (userId == null) {
            AlertGeneral.show(context, 4, message: 'edit.validations.errorUserLogin'.tr());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('edit.validations.errorUserLogin'.tr()),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // Get current links
          final currentLinks = List<Map<String, dynamic>>.from(
            user.featuredLinks ?? [],
          );

          // Add new link
          currentLinks.add({'url': url, 'label': label});

          try {
            await editCubit.saveUserProfileField(
              userId: userId,
              updatedFields: {'featuredLinks': currentLinks},
            );

            if (context.mounted) {
              AlertGeneral.show(context, 1, message: 'profile.customization.links.successAdd'.tr());
            }
          } catch (e) {
            if (context.mounted) {
              AlertGeneral.show(context, 4, message: '${'profile.customization.links.errorAdd'.tr()}$e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('profile.customization.links.successAdd'.tr()),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _removeLink(BuildContext context, int index) async {
    final authCubit = context.read<AuthCubit>();
    final editCubit = context.read<EditCubit>();
    final userId = authCubit.state.firebaseUser?.uid;

    if (userId == null) return;

    final currentLinks = List<Map<String, dynamic>>.from(
      user.featuredLinks ?? [],
    );
    currentLinks.removeAt(index);

    try {
      await editCubit.saveUserProfileField(
        userId: userId,
        updatedFields: {'featuredLinks': currentLinks},
      );

      if (context.mounted) {
        AlertGeneral.show(context, 1, message: 'profile.customization.links.successAdd'.tr());
      }
    } catch (e) {
      if (context.mounted) {
        AlertGeneral.show(context, 4, message: '${'profile.customization.links.errorAdd'.tr()}$e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.customization.links.successAdd'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } 
  }

  @override
  Widget build(BuildContext context) {
    final links = user.featuredLinks ?? [];

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
          Text(
            'profile.customization.links.title'.tr(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),

          // Display existing links
          ...links.asMap().entries.map((entry) {
            final index = entry.key;
            final link = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LinkItem(
                link: link,
                isOwnProfile: isOwnProfile,
                onRemove: () => _removeLink(context, index),
              ),
            );
          }),

          // Add link button (only show if less than 2 links)
          if (isOwnProfile && (user.featuredLinks ?? []).length < 2)
            _AddLinkButton(text: 'profile.customization.links.add'.tr(), onTap: () => _addLink(context)),
        ],
      ),
    );
  }
}

class _LinkItem extends StatelessWidget {
  final Map<String, dynamic> link;
  final bool isOwnProfile;
  final VoidCallback onRemove;

  const _LinkItem({
    required this.link,
    required this.isOwnProfile,
    required this.onRemove,
  });

  Future<void> _launchLink() async {
    final url = link['url'] as String;
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = link['label'] as String;
    final url = link['url'] as String;

    return GestureDetector(
      onTap: _launchLink,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.language, color: Colors.white70, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isOwnProfile)
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddLinkButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _AddLinkButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
