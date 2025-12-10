import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../../core/color.dart';
import 'add_link_bottom_sheet.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 2 links allowed'),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: User not logged in'),
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
          currentLinks.add({
            'url': url,
            'label': label,
          });

          try {
            await editCubit.saveUserProfileField(
              userId: userId,
              updatedFields: {'featuredLinks': currentLinks},
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error adding link: $e'),
                  backgroundColor: Colors.red,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing link: $e'),
            backgroundColor: Colors.red,
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.greyBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Links',
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
            _AddLinkButton(
              text: '+Add link',
              onTap: () => _addLink(context),
            ),
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
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
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
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
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

  const _AddLinkButton({
    required this.text,
    required this.onTap,
  });

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
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

