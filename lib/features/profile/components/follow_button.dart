import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/profile/presentation/bloc/follower_cubit/follower_cubit.dart';

/// Botón de Follow/Following para perfiles de otros usuarios
class FollowButton extends StatefulWidget {
  final String targetUserId;
  final String currentUserId;
  final bool compact;

  const FollowButton({
    super.key,
    required this.targetUserId,
    required this.currentUserId,
    this.compact = false,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final cubit = context.read<FollowerCubit>();
    final isFollowing = await cubit.checkIsFollowing(widget.targetUserId);
    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    final cubit = context.read<FollowerCubit>();

    if (_isFollowing) {
      // Mostrar diálogo de confirmación para dejar de seguir
      final confirmed = await _showUnfollowConfirmation();
      if (confirmed != true) return;

      setState(() => _isLoading = true);
      final success = await cubit.unfollowUser(widget.targetUserId);
      if (mounted) {
        setState(() {
          if (success) _isFollowing = false;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = true);
      final success = await cubit.followUser(widget.targetUserId);
      if (mounted) {
        setState(() {
          if (success) _isFollowing = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<bool?> _showUnfollowConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'followers.unfollowConfirmTitle'.tr(),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          'followers.unfollowConfirmMessage'.tr(),
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'followers.cancel'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'followers.unfollow'.tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 12 : 16,
          vertical: widget.compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.withOpacity(0.3),
        ),
        child: SizedBox(
          width: widget.compact ? 14 : 16,
          height: widget.compact ? 14 : 16,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleFollow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 12 : 20,
          vertical: widget.compact ? 6 : 10,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: _isFollowing
              ? null
              : LinearGradient(
                  colors: AppColors.primaryGradient.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: _isFollowing
              ? Border.all(color: Colors.white.withOpacity(0.5), width: 1)
              : null,
          color: _isFollowing ? Colors.transparent : null,
        ),
        child: Text(
          _isFollowing ? 'followers.following'.tr() : 'followers.follow'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.compact ? 12 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Botón de seguir simplificado para listas
class FollowButtonSmall extends StatefulWidget {
  final String targetUserId;
  final String currentUserId;
  final VoidCallback? onFollowChanged;

  const FollowButtonSmall({
    super.key,
    required this.targetUserId,
    required this.currentUserId,
    this.onFollowChanged,
  });

  @override
  State<FollowButtonSmall> createState() => _FollowButtonSmallState();
}

class _FollowButtonSmallState extends State<FollowButtonSmall> {
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final cubit = context.read<FollowerCubit>();
    final isFollowing = await cubit.checkIsFollowing(widget.targetUserId);
    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    final cubit = context.read<FollowerCubit>();

    if (_isFollowing) {
      final confirmed = await _showUnfollowConfirmation();
      if (confirmed != true) return;

      setState(() => _isLoading = true);
      final success = await cubit.unfollowUser(widget.targetUserId);
      if (mounted) {
        setState(() {
          if (success) {
            _isFollowing = false;
            widget.onFollowChanged?.call();
          }
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = true);
      final success = await cubit.followUser(widget.targetUserId);
      if (mounted) {
        setState(() {
          if (success) {
            _isFollowing = true;
            widget.onFollowChanged?.call();
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<bool?> _showUnfollowConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'followers.unfollowConfirmTitle'.tr(),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          'followers.unfollowConfirmMessage'.tr(),
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'followers.cancel'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'followers.unfollow'.tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.withOpacity(0.3),
        ),
        child: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleFollow,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: _isFollowing
              ? null
              : LinearGradient(
                  colors: AppColors.primaryGradient.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: _isFollowing
              ? Border.all(color: Colors.white.withOpacity(0.5), width: 1)
              : null,
        ),
        child: Text(
          _isFollowing
              ? 'followers.following'.tr()
              : 'followers.followBack'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
