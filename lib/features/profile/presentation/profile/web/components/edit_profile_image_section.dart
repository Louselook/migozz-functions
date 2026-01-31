import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/core/components/compuestos/gradient_button.dart';

class EditProfileImageSection extends StatelessWidget {
  final bool isSmallScreen;
  final double imageSize;
  final VoidCallback onDeleteAccount;
  final VoidCallback onSave;
  final String? avatarUrl;

  const EditProfileImageSection({
    super.key,
    required this.isSmallScreen,
    required this.imageSize,
    required this.onDeleteAccount,
    required this.onSave,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Imagen de perfil
        Stack(
          children: [
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? Image.network(
                        avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: Icon(
                              Icons.person,
                              size: isSmallScreen ? 50 : 60,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          );
                        },
                      )
                    : Image.asset(
                        'assets/image/avatar.webp',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: Icon(
                              Icons.person,
                              size: isSmallScreen ? 50 : 60,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          );
                        },
                      ),
              ),
            ),
            Positioned(
              bottom: 25,
              right: 25,
              child: Container(
                width: isSmallScreen ? 50 : 58,
                height: isSmallScreen ? 50 : 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                  ),
                  border: Border.all(color: Colors.black, width: 3),
                ),
                child: Icon(
                  Icons.edit,
                  size: isSmallScreen ? 24 : 28,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: isSmallScreen ? 30 : 40),

        // Botón Delete Account
        GradientButton(
          onPressed: onDeleteAccount,
          width: double.infinity,
          height: isSmallScreen ? 48 : 54,
          radius: 10,
          gradient: AppColors.verticalOrangeRed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: isSmallScreen ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Text(
                'edit.presentation.deleteAccount.title'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Botón Save
        GradientButton(
          onPressed: onSave,
          width: double.infinity,
          height: isSmallScreen ? 48 : 54,
          radius: 10,
          child: Text(
            'buttons.save'.tr(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 13 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
