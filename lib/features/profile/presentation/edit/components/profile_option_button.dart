import 'package:flutter/material.dart';

class ProfileOptionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const ProfileOptionButton({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: width * 0.02),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withAlpha(200), size: width * 0.055),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: width * 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
