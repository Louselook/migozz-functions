import 'package:flutter/material.dart';

class EditProfileNavigationBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onClose;

  const EditProfileNavigationBar({
    super.key,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Positioned(
      top: isSmallScreen ? 100 : 120,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          Text(
            'Edit Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
