import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Text(
          'Profile Screen',
          style: TextStyle(color: AppColors.backgroundLight),
        ),
      ),
    );
  }
}
