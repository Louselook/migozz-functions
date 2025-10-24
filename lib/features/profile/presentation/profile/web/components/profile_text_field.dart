import 'package:flutter/material.dart';

class ProfileTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool showArrow;

  const ProfileTextField({
    super.key,
    required this.label,
    required this.icon,
    this.initialValue,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: readOnly ? onTap : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: 4,
        ),
        leading: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.7),
          size: isSmallScreen ? 20 : 22,
        ),
        title: readOnly && initialValue != null && initialValue!.isNotEmpty
            ? Text(
                initialValue!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: isSmallScreen ? 14 : 15,
                ),
              )
            : readOnly
            ? Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: isSmallScreen ? 14 : 15,
                ),
              )
            : TextFormField(
                initialValue: initialValue,
                keyboardType: keyboardType,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: isSmallScreen ? 14 : 15,
                ),
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
        trailing: (readOnly && showArrow)
            ? Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.3),
                size: 14,
              )
            : null,
      ),
    );
  }
}
