import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';

import '../../../../../../../core/color.dart';

class ContactInfoSection extends StatelessWidget {
  final bool isOwnProfile;
  final UserDTO user;

  const ContactInfoSection({
    super.key,
    required this.isOwnProfile,
    required this.user,
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
                 Text('+5 %',style: TextStyle(color: Colors.purple.shade400,fontSize: 11,fontWeight: FontWeight.w800),),

                ],
              ),

              GestureDetector(
                onTap: () {
                  // TODO: Editar bio
                  debugPrint('Editar bio');
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
            icon: Icons.language,
            label: 'Website',
            isOwnProfile: isOwnProfile,
          ),
          const SizedBox(height: 8),
          _buildContactItem(
            icon: Icons.phone,
            label: 'Number',
            isOwnProfile: isOwnProfile,
          ),
          const SizedBox(height: 8),
          _buildContactItem(
            icon: Icons.email_outlined,
            label: 'Email',
            isOwnProfile: isOwnProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required bool isOwnProfile,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.grey.shade400,
              size: 15,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        if (isOwnProfile)
          Icon(
            Icons.add,
            color: Colors.white,
            size: 15,
          ),
      ],
    );
  }
}

