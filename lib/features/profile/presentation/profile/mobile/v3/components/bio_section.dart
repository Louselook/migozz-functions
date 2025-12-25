import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'edit_bio_bottom_sheet.dart';
import 'package:migozz_app/features/profile/components/utils/alertGeneral.dart';

class BioSection extends StatefulWidget {
  final String bio;
  final bool isOwnProfile;
  final int profilePercentage;

  const BioSection({
    super.key,
    required this.bio,
    required this.isOwnProfile,
    this.profilePercentage = 100,
  });

  @override
  State<BioSection> createState() => _BioSectionState();
}

class _BioSectionState extends State<BioSection> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _pulseCount = 0;
  bool _showTooltip = false;
  static const String _tooltipShownKey = 'bio_edit_tooltip_shown';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _pulseCount++;
        if (_pulseCount < 3 && widget.profilePercentage < 80 && widget.isOwnProfile) {
          _pulseController.forward();
        }
      }
    });

    // Start pulse animation if profile is incomplete
    if (widget.profilePercentage < 80 && widget.isOwnProfile) {
      _pulseController.forward();
      _checkAndShowTooltip();
    }
  }

  Future<void> _checkAndShowTooltip() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool(_tooltipShownKey) ?? false;
    if (!hasShown && mounted) {
      setState(() => _showTooltip = true);
      await prefs.setBool(_tooltipShownKey, true);
      // Hide tooltip after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showTooltip = false);
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _editBio(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditBioBottomSheet(
        currentBio: widget.bio,
        onSave: (newBio) async {
          final authCubit = context.read<AuthCubit>();
          final editCubit = context.read<EditCubit>();
          final userId = authCubit.state.firebaseUser?.uid;

          if (userId == null) {
            AlertGeneral.show(
              context,
              4,
              message: 'edit.validations.errorUserLogin'.tr(),
            );
            return;
          }

          try {
            await editCubit.saveUserProfileField(
              userId: userId,
              updatedFields: {'bio': newBio},
            );

            if (context.mounted) {
              AlertGeneral.show(
                context,
                1,
                message: 'profile.customization.bio.success'.tr(),
              );
            }
          } catch (e) {
            if (context.mounted) {
              AlertGeneral.show(
                context,
                4,
                message:
                    '${'profile.customization.bio.errorUpdate'.tr()}$e',
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildPulsingEditIcon() {
    final shouldPulse = widget.profilePercentage < 80 && widget.isOwnProfile;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _editBio(context),
          child: ScaleTransition(
            scale: shouldPulse ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration:  BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.verticalPinkPurple,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 7),
            ),
          ),
        ),
        // Tooltip
        if (_showTooltip)
          Positioned(
            top: -35,
            left: -50,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'profile.customization.editButton.tooltip'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isOwnProfile ? () => _editBio(context) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                      'profile.customization.bio.label'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPulsingEditIcon(),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: Toggle visibility
                    debugPrint('Toggle bio visibility');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.remove_red_eye_outlined,
                      color: Colors.white70,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              widget.bio.isEmpty ? 'profile.customization.bio.add'.tr() : widget.bio,
              style: TextStyle(
                color: widget.bio.isEmpty ? Colors.white38 : Colors.white70,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            if (widget.isOwnProfile && widget.bio.isEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _editBio(context),
                child: Text(
                  'profile.customization.bio.editCta'.tr(),
                  style: TextStyle(
                    color: Colors.purple.shade300,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
