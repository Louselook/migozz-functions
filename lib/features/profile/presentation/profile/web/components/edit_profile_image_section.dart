import 'package:flutter/material.dart';

class EditProfileImageSection extends StatelessWidget {
  final bool isSmallScreen;
  final double imageSize;
  final String? avatarUrl;
  final VoidCallback? onEditImage;

  const EditProfileImageSection({
    super.key,
    required this.isSmallScreen,
    required this.imageSize,
    this.avatarUrl,
    this.onEditImage,
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
              child: _BouncingButton(
                onTap: onEditImage,
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
            ),
          ],
        ),
      ],
    );
  }
}

class _BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _BouncingButton({required this.child, this.onTap});

  @override
  State<_BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<_BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
