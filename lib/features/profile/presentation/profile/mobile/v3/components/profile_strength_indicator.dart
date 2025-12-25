import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class ProfileStrengthIndicator extends StatefulWidget {
  final int percentage;

  const ProfileStrengthIndicator({
    super.key,
    required this.percentage,
  });

  @override
  State<ProfileStrengthIndicator> createState() => _ProfileStrengthIndicatorState();
}

class _ProfileStrengthIndicatorState extends State<ProfileStrengthIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  int _previousPercentage = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.percentage / 100,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _previousPercentage = widget.percentage;
    _animationController.forward();
  }

  @override
  void didUpdateWidget(ProfileStrengthIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _progressAnimation = Tween<double>(
        begin: _previousPercentage / 100,
        end: widget.percentage / 100,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      _previousPercentage = widget.percentage;
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'profile.customization.profileStrength.title'.tr(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.percentage}%',
                style: TextStyle(
                  color: Colors.purple.shade400,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'profile.customization.profileStrength.ready'.tr(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'profile.customization.profileStrength.subtitle'.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  // Background
                  Container(
                    width: double.infinity,
                    color: Colors.grey.shade800,
                  ),
                  // Animated progress bar with gradient
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.verticalPinkPurple,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

