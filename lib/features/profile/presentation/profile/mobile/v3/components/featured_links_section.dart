import 'package:flutter/material.dart';

import '../../../../../../../core/color.dart';

class FeaturedLinksSection extends StatelessWidget {
  final bool isOwnProfile;

  const FeaturedLinksSection({
    super.key,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
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
          _AddLinkButton(
            text: '+Add no thumbnail link',
            onTap: () {

              debugPrint('Agregar link sin thumbnail');
            },
          ),
          const SizedBox(height: 12),
          _AddLinkButton(
            text: '+Add no thumbnail link',
            onTap: () {

              debugPrint('Agregar link sin thumbnail');
            },
          ),
        ],
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

