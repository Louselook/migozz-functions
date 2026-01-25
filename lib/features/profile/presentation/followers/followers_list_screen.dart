import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/color.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/chat/presentation/user/user_chat_screen.dart';
import 'package:migozz_app/features/profile/components/follow_button.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/profile/data/domain/models/follower_dto.dart';
import 'package:migozz_app/features/profile/presentation/bloc/follower_cubit/follower_cubit.dart';

/// Pantalla de lista de seguidores y siguiendo
class FollowersListScreen extends StatefulWidget {
  final String userId;
  final String username;
  final int initialTab; // 0 = followers, 1 = following

  const FollowersListScreen({
    super.key,
    required this.userId,
    required this.username,
    this.initialTab = 0,
  });

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen>
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo con gradiente
          TintesGradients(
            child: Container(height: MediaQuery.of(context).size.height * 0.25),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header con botón de regreso y username
                _buildHeader(),
                const SizedBox(height: 8),

                // Tabs de Seguidores y Seguidos
                _buildTabs(),
                const SizedBox(height: 12),

                // Barra de búsqueda
                _buildSearchBar(),
                const SizedBox(height: 16),

                // Lista de usuarios
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildFollowersList(), _buildFollowingList()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '@${widget.username}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
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
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: TabBar(
            controller: _tabController,
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: AppColors.primaryPink, width: 3),
              insets: EdgeInsets.symmetric(horizontal: 40),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'followers.search'.tr(),
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withOpacity(0.5),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value.toLowerCase());
          },
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

        final filteredFollowers = state.followers.where((f) {
          if (_searchQuery.isEmpty) return true;
          final name = (f.displayName ?? '').toLowerCase();
          final username = (f.username ?? '').toLowerCase();
          return name.contains(_searchQuery) || username.contains(_searchQuery);
        }).toList();

        if (filteredFollowers.isEmpty) {
          return _buildEmptyState('followers.noFollowers'.tr());
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredFollowers.length,
          itemBuilder: (context, index) {
            final follower = filteredFollowers[index];
            final isMutual = state.isMutualMap[follower.oderId] ?? false;
            return _FollowerListItem(
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

        final filteredFollowing = state.following.where((f) {
          if (_searchQuery.isEmpty) return true;
          final name = (f.displayName ?? '').toLowerCase();
          final username = (f.username ?? '').toLowerCase();
          return name.contains(_searchQuery) || username.contains(_searchQuery);
        }).toList();

        if (filteredFollowing.isEmpty) {
          return _buildEmptyState('followers.noFollowing'.tr());
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredFollowing.length,
          itemBuilder: (context, index) {
            final following = filteredFollowing[index];
            return _FollowerListItem(
              follower: following,
              isMutual: true, // En siguiendo, siempre podemos enviar mensaje
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
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToProfile(String userId) async {
    // Cargar datos del usuario desde Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && mounted) {
        final userData = doc.data()!;
        final user = UserDTO.fromMap(userData);
        context.push('/profile-view', extra: user);
      }
    } catch (e) {
      debugPrint('❌ Error cargando perfil: $e');
    }
  }

  void _navigateToChat(FollowerDTO user) {
    final currentUserId =
        context.read<AuthCubit>().state.firebaseUser?.uid ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserChatScreen(
          otherUserId: user.oderId,
          otherUserName: user.displayName ?? user.username ?? 'User',
          otherUserAvatar: user.avatarUrl,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  Future<void> _showRemoveConfirmation(
    FollowerDTO user,
    bool isFollower,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
              isFollower ? 'followers.remove'.tr() : 'followers.unfollow'.tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final cubit = context.read<FollowerCubit>();
      if (isFollower) {
        await cubit.removeFollower(user.oderId);
      } else {
        await cubit.unfollowUser(user.oderId);
      }
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number >= 10000 ? 0 : 1)}K';
    }
    return number.toString();
  }
}

/// Item individual de la lista de seguidores/siguiendo
class _FollowerListItem extends StatelessWidget {
  final FollowerDTO follower;
  final bool isMutual;
  final bool isFollowersList;
  final VoidCallback onRemove;
  final VoidCallback onUserTap;
  final VoidCallback onMessageTap;

  const _FollowerListItem({
    required this.follower,
    required this.isMutual,
    required this.isFollowersList,
    required this.onRemove,
    required this.onUserTap,
    required this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        context.read<AuthCubit>().state.firebaseUser?.uid ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Avatar y información del usuario
          Expanded(
            child: GestureDetector(
              onTap: onUserTap,
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: follower.avatarUrl != null
                        ? NetworkImage(follower.avatarUrl!)
                        : null,
                    child: follower.avatarUrl == null
                        ? Icon(Icons.person, color: Colors.grey[400], size: 28)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Nombre y username
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                follower.displayName ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Icono de verificado (opcional)
                            Icon(
                              Icons.verified,
                              color: Colors.blue[400],
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${follower.username ?? 'unknown'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
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

          // Botón de acción (Follow/Message)
          const SizedBox(width: 8),
          if (isFollowersList)
            // En lista de seguidores: mostrar Follow o Message según si es mutuo
            isMutual
                ? _MessageButton(onTap: onMessageTap)
                : FollowButtonSmall(
                    targetUserId: follower.oderId,
                    currentUserId: currentUserId,
                  )
          else
            // En lista de siguiendo: siempre mostrar Message
            _MessageButton(onTap: onMessageTap),

          // Botón de eliminar (X)
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón de mensaje
class _MessageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MessageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey.withOpacity(0.3),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Text(
          'followers.message'.tr(),
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
