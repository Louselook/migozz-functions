import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/components/follow_button.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';
import 'package:migozz_app/features/profile/data/domain/models/follower_dto.dart';
import 'package:migozz_app/features/profile/presentation/bloc/follower_cubit/follower_cubit.dart';

/// Web-optimized followers/following list with SideMenu
class WebFollowersScreen extends StatefulWidget {
  final String userId;
  final String username;
  final int initialTab;

  const WebFollowersScreen({
    super.key,
    required this.userId,
    required this.username,
    this.initialTab = 0,
  });

  @override
  State<WebFollowersScreen> createState() => _WebFollowersScreenState();
}

class _WebFollowersScreenState extends State<WebFollowersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadData();
  }

  void _loadData() {
    final cubit = context.read<FollowerCubit>();
    cubit.loadFollowers(widget.userId);
    cubit.loadFollowing(widget.userId);
    cubit.loadCounts(widget.userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 900;
    final leftMenuWidth = isSmallScreen ? 80.0 : 100.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(left: leftMenuWidth),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 8),
                      _buildTabs(),
                      const SizedBox(height: 12),
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildFollowersList(),
                            _buildFollowingList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Side Menu
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: leftMenuWidth,
            child: const SideMenu(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/profile'),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.people, color: AppColors.primaryPink, size: 28),
          const SizedBox(width: 12),
          Text(
            '@${widget.username}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return BlocBuilder<FollowerCubit, FollowerState>(
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: AppColors.primaryPink, width: 2),
              insets: EdgeInsets.zero,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Text(
                  '${_formatNumber(state.followersCount)} ${'followers.followers'.tr()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Tab(
                child: Text(
                  '${_formatNumber(state.followingCount)} ${'followers.following'.tr()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'followers.search'.tr(),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) =>
              setState(() => _searchQuery = value.toLowerCase()),
        ),
      ),
    );
  }

  Widget _buildFollowersList() {
    return BlocBuilder<FollowerCubit, FollowerState>(
      builder: (context, state) {
        if (state.status == FollowerStatus.loading && state.followers.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final filtered = state.followers.where((f) {
          if (_searchQuery.isEmpty) return true;
          final name = (f.displayName ?? '').toLowerCase();
          final username = (f.username ?? '').toLowerCase();
          return name.contains(_searchQuery) || username.contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyState('followers.noFollowers'.tr());
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final follower = filtered[index];
            final isMutual = state.isMutualMap[follower.oderId] ?? false;
            return _WebFollowerListItem(
              follower: follower,
              isMutual: isMutual,
              isFollowersList: true,
              onRemove: () => _showRemoveConfirmation(follower, true),
              onUserTap: () => _navigateToProfile(follower.oderId),
              onMessageTap: () => _navigateToChat(follower),
            );
          },
        );
      },
    );
  }

  Widget _buildFollowingList() {
    return BlocBuilder<FollowerCubit, FollowerState>(
      builder: (context, state) {
        if (state.status == FollowerStatus.loading && state.following.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final filtered = state.following.where((f) {
          if (_searchQuery.isEmpty) return true;
          final name = (f.displayName ?? '').toLowerCase();
          final username = (f.username ?? '').toLowerCase();
          return name.contains(_searchQuery) || username.contains(_searchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return _buildEmptyState('followers.noFollowing'.tr());
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final following = filtered[index];
            return _WebFollowerListItem(
              follower: following,
              isMutual: true,
              isFollowersList: false,
              onRemove: () => _showRemoveConfirmation(following, false),
              onUserTap: () => _navigateToProfile(following.oderId),
              onMessageTap: () => _navigateToChat(following),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToProfile(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists && mounted) {
        final userData = doc.data()!;
        final user = UserDTO.fromMap(userData);
        if (user.username.isNotEmpty) {
          context.go('/u/${user.username}');
        } else {
          context.push('/profile-view', extra: user);
        }
      }
    } catch (e) {
      debugPrint('❌ Error cargando perfil: $e');
    }
  }

  Future<void> _navigateToChat(FollowerDTO user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.oderId)
          .get();
      if (doc.exists && mounted) {
        final userData = doc.data()!;
        final otherUserEmail = userData['email'] as String? ?? '';
        if (otherUserEmail.isNotEmpty) {
          context.push('/chat/$otherUserEmail');
        }
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo email del usuario para chat: $e');
    }
  }

  Future<void> _showRemoveConfirmation(
    FollowerDTO user,
    bool isFollower,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isFollower
              ? 'followers.removeFollowerTitle'.tr()
              : 'followers.unfollowConfirmTitle'.tr(),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          isFollower
              ? 'followers.removeFollowerMessage'.tr()
              : 'followers.unfollowConfirmMessage'.tr(),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'followers.cancel'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isFollower ? 'followers.remove'.tr() : 'followers.unfollow'.tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final cubit = context.read<FollowerCubit>();
      if (isFollower) {
        await cubit.removeFollower(user.oderId);
      } else {
        await cubit.unfollowUser(user.oderId);
      }
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number >= 10000 ? 0 : 1)}K';
    }
    return number.toString();
  }
}

/// Web-optimized follower list item with hover effects
class _WebFollowerListItem extends StatefulWidget {
  final FollowerDTO follower;
  final bool isMutual;
  final bool isFollowersList;
  final VoidCallback onRemove;
  final VoidCallback onUserTap;
  final VoidCallback onMessageTap;

  const _WebFollowerListItem({
    required this.follower,
    required this.isMutual,
    required this.isFollowersList,
    required this.onRemove,
    required this.onUserTap,
    required this.onMessageTap,
  });

  @override
  State<_WebFollowerListItem> createState() => _WebFollowerListItemState();
}

class _WebFollowerListItemState extends State<_WebFollowerListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        context.read<AuthCubit>().state.firebaseUser?.uid ?? '';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isHovered
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar + info
            Expanded(
              child: GestureDetector(
                onTap: widget.onUserTap,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: widget.follower.avatarUrl != null
                            ? NetworkImage(widget.follower.avatarUrl!)
                            : null,
                        child: widget.follower.avatarUrl == null
                            ? Icon(
                                Icons.person,
                                color: Colors.grey[400],
                                size: 24,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.follower.displayName ?? 'User',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.verified,
                                  color: Colors.blue[400],
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${widget.follower.username ?? 'unknown'}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Action button
            if (widget.isFollowersList)
              widget.isMutual
                  ? _WebMessageButton(onTap: widget.onMessageTap)
                  : FollowButtonSmall(
                      targetUserId: widget.follower.oderId,
                      currentUserId: currentUserId,
                    )
            else
              _WebMessageButton(onTap: widget.onMessageTap),
            const SizedBox(width: 8),
            // Remove button
            IconButton(
              onPressed: widget.onRemove,
              icon: Icon(
                Icons.close,
                color: Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
              hoverColor: Colors.red.withValues(alpha: 0.1),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebMessageButton extends StatelessWidget {
  final VoidCallback onTap;
  const _WebMessageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        backgroundColor: Colors.grey.withValues(alpha: 0.2),
      ),
      child: Text(
        'followers.message'.tr(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
