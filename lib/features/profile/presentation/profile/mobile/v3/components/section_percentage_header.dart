import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

/// A reusable header widget that displays section title with percentage and completion status
/// with smooth animations
class SectionPercentageHeader extends StatefulWidget {
  final String title;
  final int percentage;
  final bool isCompleted;
  final Widget? trailing;
  final VoidCallback? onEditTap;
  final bool showEditIcon;

  const SectionPercentageHeader({
    super.key,
    required this.title,
    required this.percentage,
    required this.isCompleted,
    this.trailing,
    this.onEditTap,
    this.showEditIcon = false,
  });

  @override
  State<SectionPercentageHeader> createState() =>
      _SectionPercentageHeaderState();
}

class _SectionPercentageHeaderState extends State<SectionPercentageHeader>
    with TickerProviderStateMixin {
  late AnimationController _checkmarkController;
  late AnimationController _percentageController;
  late Animation<double> _checkmarkScaleAnimation;
  late Animation<double> _checkmarkOpacityAnimation;
  late Animation<double> _percentageFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Checkmark animation controller
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _checkmarkScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkmarkController, curve: Curves.elasticOut),
    );

    _checkmarkOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkmarkController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Percentage fade animation
    _percentageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _percentageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _percentageController, curve: Curves.easeOut),
    );

    // Start animations
    _percentageController.forward();
    if (widget.isCompleted) {
      _checkmarkController.forward();
    }
  }

  @override
  void didUpdateWidget(SectionPercentageHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted != oldWidget.isCompleted) {
      if (widget.isCompleted) {
        _checkmarkController.forward();
      } else {
        _checkmarkController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _percentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              // Percentage badge with animation
              AnimatedBuilder(
                animation: _percentageController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _percentageFadeAnimation.value,
                    child: Transform.scale(
                      scale: 0.8 + (_percentageFadeAnimation.value * 0.2),
                      child: _buildPercentageBadge(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              // Checkmark with animation
              if (widget.isCompleted) ...[
                AnimatedBuilder(
                  animation: _checkmarkController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _checkmarkOpacityAnimation.value,
                      child: Transform.scale(
                        scale: _checkmarkScaleAnimation.value,
                        child: _buildCheckmark(),
                      ),
                    );
                  },
                ),
              ],
              // Edit icon if needed
              if (widget.showEditIcon && widget.onEditTap != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: widget.onEditTap,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.verticalPinkPurple,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 7),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.trailing != null) widget.trailing!,
      ],
    );
  }

  Widget _buildPercentageBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: widget.isCompleted
            ? LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade400],
              )
            : LinearGradient(
                colors: [
                  Colors.purple.shade600.withValues(alpha: 0.8),
                  Colors.pink.shade400.withValues(alpha: 0.8),
                ],
              ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${widget.percentage}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCheckmark() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green.shade500,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 10),
    );
  }
}

/// Animated section container with fade-in and slide animation
class AnimatedSectionContainer extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const AnimatedSectionContainer({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedSectionContainer> createState() =>
      _AnimatedSectionContainerState();
}

class _AnimatedSectionContainerState extends State<AnimatedSectionContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Delay based on index for staggered animation
    Future.delayed(
      widget.delay + Duration(milliseconds: widget.index * 100),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
