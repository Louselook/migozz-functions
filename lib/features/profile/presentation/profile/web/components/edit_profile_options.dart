import 'package:flutter/material.dart';

class EditProfileOptions extends StatelessWidget {
  final VoidCallback? onEditRecord;
  final VoidCallback? onEditInterest;
  final VoidCallback? onEditSocials;

  const EditProfileOptions({
    super.key,
    this.onEditRecord,
    this.onEditInterest,
    this.onEditSocials,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EditOptionItem(
          icon: Icons.play_circle_outline,
          text: 'Edit Record',
          onTap: onEditRecord,
        ),
        _EditOptionItem(
          icon: Icons.favorite_border,
          text: 'Edit My Interest',
          onTap: onEditInterest,
        ),
        _EditOptionItem(
          icon: Icons.add_box_outlined,
          text: 'Edit Socials',
          onTap: onEditSocials,
        ),
      ],
    );
  }
}

class _EditOptionItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _EditOptionItem({required this.icon, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 12 : 14,
          horizontal: 0,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.7),
              size: isSmallScreen ? 20 : 22,
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: isSmallScreen ? 14 : 15,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.3),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
