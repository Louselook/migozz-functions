import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';
import 'package:migozz_app/features/profile/presentation/bloc/follower_cubit/follower_cubit.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/profile_background_gradients.dart';

class WebProfileStats extends StatefulWidget {
  final UserDTO user;
  const WebProfileStats({super.key, required this.user});

  @override
  State<WebProfileStats> createState() => _WebProfileStatsState();
}

class _WebProfileStatsState extends State<WebProfileStats> {
  bool _loading = true;
  String _overviewSelection = 'community';

  List<_SocialStats> _socials = [];
  Map<String, int> _totalsGlobal = {};

  StreamSubscription<DocumentSnapshot>? _userDocSub;

  @override
  void initState() {
    super.initState();
    _listenToUserData();
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    super.dispose();
  }

  // ─── FIRESTORE LISTENER ───

  void _listenToUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (!snapshot.exists || !mounted) return;
            final data = snapshot.data();
            _processUserData(data);
          },
          onError: (e) {
            debugPrint('Error listening to user data: $e');
            if (mounted) setState(() => _loading = false);
          },
        );
  }

  void _processUserData(Map<String, dynamic>? data) {
    if (data == null) {
      setState(() {
        _socials = [];
        _totalsGlobal = {};
        _loading = false;
      });
      return;
    }

    final dynamic ecosystem = data['socialEcosystem'];
    final socials = <_SocialStats>[];
    for (final e in _parseEcosystem(ecosystem)) {
      socials.add(_SocialStats.fromMap(e.key, e.value));
    }

    final globalTotals = _calculateTotals(socials);

    // Profile-specific stats
    final int profileLikes = _parseInt(data['likes'] ?? data['profileLikes']);
    final int profileShares = _parseInt(
      data['shares'] ?? data['profileShares'],
    );
    globalTotals['profile_likes'] = profileLikes;
    globalTotals['profile_shares'] = profileShares;

    setState(() {
      _socials = socials;
      _totalsGlobal = globalTotals;
      _loading = false;
    });
  }

  int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  Map<String, int> _calculateTotals(List<_SocialStats> socials) {
    final Map<String, int> totals = {};
    for (final s in socials) {
      final stats = {
        'followers': s.followers ?? 0,
        'likes': s.likes ?? 0,
        'views': s.viewCount ?? 0,
        'shares': s.shares ?? 0,
        'media': s.mediaCount ?? 0,
        'following': s.followingCount ?? 0,
        'subscribers': s.subscribers ?? 0,
      };
      for (final entry in stats.entries) {
        final normalizedKey =
            _fieldRules[entry.key.toLowerCase()] ?? entry.key.toLowerCase();
        totals[normalizedKey] = (totals[normalizedKey] ?? 0) + entry.value;
      }
    }
    return totals;
  }

  // ─── BUILD ───

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 900;

    final isMenuSmall = size.width < 600;
    final isMenuMedium = size.width >= 600 && size.width < 1200;
    final leftMenuWidth = isMenuSmall
        ? 95.0
        : isMenuMedium
        ? 110.0
        : 140.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const ProfileBackgroundGradients(),

          // Main content
          Positioned(
            left: leftMenuWidth,
            right: 0,
            top: 0,
            bottom: 0,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 20 : 40,
                            vertical: 30,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title
                              Center(
                                child: Text(
                                  'stats.title'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36),

                              // 1. Top Three Metrics (matches mobile)
                              _buildTopMetrics(isSmall),
                              const SizedBox(height: 40),

                              // 2. Overview + Followers side by side (desktop)
                              //    or stacked (small)
                              if (isSmall) ...[
                                _buildOverviewCard(),
                                const SizedBox(height: 20),
                                _buildFollowersCard(),
                              ] else
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: _buildOverviewCard(),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      flex: 4,
                                      child: _buildFollowersCard(),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 28),

                              // 3. Individual Network Cards
                              if (_socials.isEmpty)
                                _buildNoSocialsPlaceholder()
                              else
                                _buildNetworkCards(isSmall),

                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),

          // Side Menu
          const Positioned(left: 0, top: 0, bottom: 0, child: SideMenu()),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ─── WIDGET BUILDERS ───
  // ═══════════════════════════════════════════════

  /// Top 3 metrics: Migozz followers, Social followers, Total
  Widget _buildTopMetrics(bool isSmall) {
    final socialFollowers = _totalsGlobal['followers'] ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Migozz followers (tappable → followers list)
          BlocBuilder<FollowerCubit, FollowerState>(
            builder: (context, followerState) {
              return _TopMetricItem(
                iconWidget: Image.asset(
                  'assets/icons/Migozz_Icon.png',
                  width: isSmall ? 28 : 36,
                  height: isSmall ? 28 : 36,
                ),
                value: _formatNum(followerState.followersCount),
                onTap: () {
                  final authState = context.read<AuthCubit>().state;
                  final uid = authState.firebaseUser?.uid ?? '';
                  final username = authState.userProfile?.username ?? '';
                  context.go('/followers/$uid?username=$username');
                },
                isSmall: isSmall,
              );
            },
          ),

          // Social followers
          _TopMetricItem(
            icon: Icons.public,
            value: _formatNum(socialFollowers),
            isSmall: isSmall,
          ),

          // Total (Migozz + social)
          BlocBuilder<FollowerCubit, FollowerState>(
            builder: (context, followerState) {
              return _TopMetricItem(
                icon: Icons.person_add,
                value: _formatNum(
                  followerState.followersCount + socialFollowers,
                ),
                isSmall: isSmall,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Overview card with Community/Migozz dropdown
  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.featured_play_list_outlined,
                color: Colors.white70,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Inner content box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown selector
                _buildOverviewDropdown(),
                const SizedBox(height: 24),

                // Content based on selection
                if (_overviewSelection == 'community')
                  _buildCommunityOverview()
                else
                  _buildMigozzOverview(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewDropdown() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _overviewSelection,
          onChanged: (val) {
            if (val != null) setState(() => _overviewSelection = val);
          },
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Colors.white70,
          ),
          dropdownColor: const Color(0xFF2C2C2C),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          items: [
            DropdownMenuItem(
              value: 'community',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public, size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text('stats.overview.community'.tr()),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'migozz',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/Migozz_Icon.png',
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 8),
                  Text('stats.overview.migozz'.tr()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityOverview() {
    _SocialStats? findSocial(String name) {
      try {
        return _socials.firstWhere(
          (s) => s.name.toLowerCase().contains(name.toLowerCase()),
        );
      } catch (_) {
        return null;
      }
    }

    final instagram = findSocial('instagram');
    final youtube = findSocial('youtube');
    final tiktok = findSocial('tiktok');
    final facebook = findSocial('facebook');

    final rows = <Widget>[];
    if (instagram != null) {
      rows.add(
        _SmallSocialRow(
          name: 'Instagram',
          count: instagram.followers ?? 0,
          iconPath: 'assets/icons/social_networks/Instagram.svg',
        ),
      );
    }
    if (tiktok != null) {
      rows.add(
        _SmallSocialRow(
          name: 'Tiktok',
          count: tiktok.followers ?? 0,
          iconPath: 'assets/icons/social_networks/Tiktok.svg',
        ),
      );
    }
    if (youtube != null) {
      rows.add(
        _SmallSocialRow(
          name: 'Youtube',
          count: (youtube.followers ?? youtube.subscribers) ?? 0,
          iconPath: 'assets/icons/social_networks/Youtube.svg',
        ),
      );
    }
    if (facebook != null) {
      rows.add(
        _SmallSocialRow(
          name: 'Facebook',
          count: facebook.followers ?? 0,
          iconPath: 'assets/icons/social_networks/Facebook.svg',
        ),
      );
    }

    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'stats.noData'.tr(),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    // 2-column layout
    final left = <Widget>[];
    final right = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      if (i.isEven) {
        left.add(rows[i]);
      } else {
        right.add(rows[i]);
      }
    }

    List<Widget> withSpacing(List<Widget> items) {
      return [
        for (int i = 0; i < items.length; i++) ...[
          items[i],
          if (i != items.length - 1) const SizedBox(height: 18),
        ],
      ];
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: withSpacing(left))),
        const SizedBox(width: 24),
        Expanded(child: Column(children: withSpacing(right))),
      ],
    );
  }

  Widget _buildMigozzOverview() {
    return BlocBuilder<FollowerCubit, FollowerState>(
      builder: (context, followerState) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SmallSocialRow(
                name: 'stats.fieldLabels.followers'.tr(),
                count: followerState.followersCount,
                iconPath: 'assets/icons/Migozz_Icon.svg',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _SmallSocialRow(
                name: 'stats.fieldLabels.following'.tr(),
                count: followerState.followingCount,
                iconPath: 'assets/icons/Migozz_Icon.svg',
                isFollowing: true,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Followers card – shows Migozz followers with tap to navigate
  Widget _buildFollowersCard() {
    return BlocBuilder<FollowerCubit, FollowerState>(
      builder: (context, followerState) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(
                    Icons.people_alt_outlined,
                    color: Colors.white70,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'stats.fieldLabels.followers'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Migozz followers row
              _FollowerRow(
                iconWidget: Image.asset(
                  'assets/icons/Migozz_Icon.png',
                  width: 20,
                  height: 20,
                ),
                label: 'Migozz',
                value: _formatNum(followerState.followersCount),
                onTap: () {
                  final authState = context.read<AuthCubit>().state;
                  final uid = authState.firebaseUser?.uid ?? '';
                  final username = authState.userProfile?.username ?? '';
                  context.go('/followers/$uid?username=$username');
                },
              ),

              // Social followers rows
              ..._socials.map((s) {
                String cleanName = s.name;
                if (cleanName.toLowerCase() == 'tiktok') cleanName = 'Tiktok';
                if (cleanName.toLowerCase() == 'youtube') {
                  cleanName = 'Youtube';
                }
                if (cleanName.toLowerCase() == 'facebook') {
                  cleanName = 'Facebook';
                }
                if (cleanName.toLowerCase() == 'instagram') {
                  cleanName = 'Instagram';
                }

                final path =
                    iconByLabel[cleanName] ??
                    'assets/icons/social_networks/Other.svg';

                return _FollowerRow(
                  iconWidget: SvgPicture.asset(
                    path,
                    width: 20,
                    height: 20,
                    placeholderBuilder: (_) =>
                        const Icon(Icons.public, size: 20, color: Colors.white),
                  ),
                  label: cleanName,
                  value: _formatNum(s.followers ?? 0),
                );
              }),

              const Divider(color: Colors.white12, height: 24),

              // Total row
              _FollowerRow(
                iconWidget: const Icon(
                  Icons.public,
                  size: 20,
                  color: Colors.white70,
                ),
                label: 'stats.fieldLabels.all'.tr(),
                value: _formatNum(
                  followerState.followersCount +
                      (_totalsGlobal['followers'] ?? 0),
                ),
                isBold: true,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Individual network stat cards (responsive grid)
  Widget _buildNetworkCards(bool isSmall) {
    if (isSmall) {
      return Column(
        children: _socials
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _NetworkStatsCard(social: s),
              ),
            )
            .toList(),
      );
    }

    // Desktop: 2-column grid
    final items = _socials.toList();
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final hasSecond = i + 1 < items.length;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _NetworkStatsCard(social: items[i])),
              if (hasSecond) ...[
                const SizedBox(width: 16),
                Expanded(child: _NetworkStatsCard(social: items[i + 1])),
              ] else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  /// Placeholder when no social networks connected
  Widget _buildNoSocialsPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'stats.noStats.notSocials'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => context.go('/edit-profile'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB86BFF), Color(0xFFFF5F9A)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'stats.noStats.addButton'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// ─── HELPER WIDGETS ───
// ═══════════════════════════════════════════════

class _TopMetricItem extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String value;
  final VoidCallback? onTap;
  final bool isSmall;

  const _TopMetricItem({
    this.icon,
    this.iconWidget,
    required this.value,
    this.onTap,
    this.isSmall = false,
  }) : assert(icon != null || iconWidget != null);

  @override
  Widget build(BuildContext context) {
    final Widget resolvedIcon =
        iconWidget ?? Icon(icon!, color: Colors.white, size: isSmall ? 28 : 36);
    return MouseRegion(
      cursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            resolvedIcon,
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallSocialRow extends StatelessWidget {
  final String name;
  final int count;
  final String iconPath;
  final bool isFollowing;

  const _SmallSocialRow({
    required this.name,
    required this.count,
    required this.iconPath,
    this.isFollowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: SvgPicture.asset(
            iconPath,
            width: 20,
            height: 20,
            placeholderBuilder: (_) =>
                const Icon(Icons.public, size: 20, color: Colors.white),
          ),
        ),
        SizedBox(
          width: 24,
          child: Icon(
            isFollowing ? Icons.person_add_alt_1 : Icons.people_alt_outlined,
            size: 18,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        Expanded(
          child: Text(
            _formatNum(count),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _FollowerRow extends StatelessWidget {
  final Widget iconWidget;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isBold;

  const _FollowerRow({
    required this.iconWidget,
    required this.label,
    required this.value,
    this.onTap,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: MouseRegion(
        cursor: onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              iconWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: isBold ? 1.0 : 0.85),
                    fontSize: 14,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkStatsCard extends StatelessWidget {
  final _SocialStats social;

  const _NetworkStatsCard({required this.social});

  @override
  Widget build(BuildContext context) {
    final data = social.toJson();
    final filteredEntries = data.entries.where((e) {
      final key = e.key.toLowerCase();
      final value = e.value;
      return value != null &&
          value.toString().trim().isNotEmpty &&
          !['id', 'name', 'iconpath', 'label'].contains(key);
    }).toList();

    if (filteredEntries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Network header
          Row(
            children: [
              _buildColorfulIcon(social.name),
              const SizedBox(width: 14),
              Text(
                _capitalize(social.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats rows
          ...filteredEntries.map((e) {
            final displayKey = _applyFieldRules(e.key);
            final formatted = _formatKey(displayKey);
            final numValue = int.tryParse(e.value.toString()) ?? 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  _getStatIcon(displayKey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      formatted,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Text(
                    _formatNum(numValue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildColorfulIcon(String name) {
    String cleanName = _capitalize(name);
    if (name.toLowerCase() == 'tiktok') cleanName = 'Tiktok';
    if (name.toLowerCase() == 'youtube') cleanName = 'Youtube';
    if (name.toLowerCase() == 'facebook') cleanName = 'Facebook';
    if (name.toLowerCase() == 'instagram') cleanName = 'Instagram';
    if (name.toLowerCase() == 'twitter') cleanName = 'Twitter';

    final path =
        iconByLabel[cleanName] ?? 'assets/icons/social_networks/Other.svg';

    return SvgPicture.asset(
      path,
      width: 18,
      height: 18,
      placeholderBuilder: (_) =>
          const Icon(Icons.public, color: Colors.white, size: 18),
    );
  }

  Widget _getStatIcon(String key) {
    IconData icon;
    switch (key.toLowerCase()) {
      case 'followers':
      case 'following':
        icon = Icons.person_add_outlined;
        break;
      case 'likes':
      case 'media':
        icon = Icons.favorite;
        break;
      case 'shares':
        icon = Icons.reply;
        break;
      case 'subscribers':
        icon = Icons.subscriptions_outlined;
        break;
      default:
        icon = Icons.analytics_outlined;
    }
    return Icon(icon, color: Colors.white70, size: 18);
  }
}

// ═══════════════════════════════════════════════
// ─── MODELS & UTILS ───
// ═══════════════════════════════════════════════

final Map<String, String> _fieldRules = {
  'friends': 'followers',
  'fans': 'followers',
  'subscribers': 'followers',
  'subscriber': 'followers',
  'subscriberCount': 'followers',
  'followersCount': 'followers',
  'hearts': 'likes',
  'likes_count': 'likes',
  'favorites': 'likes',
  'videos': 'media',
  'media_count': 'media',
  'mediacount': 'media',
  'videoCount': 'media',
};

String _formatNum(int n) {
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '')} mill.';
  }
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '')} mil';
  }
  return n.toString();
}

String _capitalize(String s) {
  if (s.isEmpty) return '';
  return '${s[0].toUpperCase()}${s.substring(1)}';
}

String _formatKey(String key) {
  final translationKey = 'stats.fieldLabels.$key';
  final translated = translationKey.tr();
  if (translated != translationKey) return translated;

  final formatted = key
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .trim();
  return formatted.isNotEmpty
      ? formatted[0].toUpperCase() + formatted.substring(1)
      : key;
}

String _applyFieldRules(String key) {
  final lower = key.toLowerCase();
  return _fieldRules[lower] ?? key;
}

List<MapEntry<String, Map<String, dynamic>>> _parseEcosystem(
  dynamic ecosystem,
) {
  final out = <MapEntry<String, Map<String, dynamic>>>[];
  if (ecosystem == null) return out;

  if (ecosystem is List) {
    for (final item in ecosystem) {
      if (item is Map<String, dynamic>) {
        if (item.containsKey('domain')) {
          final domain = item['domain'] as String;
          out.add(MapEntry(domain, item));
        } else {
          item.forEach((k, v) {
            if (v is Map<String, dynamic>) out.add(MapEntry(k, v));
          });
        }
      }
    }
  } else if (ecosystem is Map<String, dynamic>) {
    ecosystem.forEach((k, v) {
      if (v is Map<String, dynamic>) {
        if (v.length == 1 && v.values.first is Map<String, dynamic>) {
          final innerKey = v.keys.first;
          final innerVal = v[innerKey] as Map<String, dynamic>;
          out.add(MapEntry(innerKey, innerVal));
        } else {
          bool added = false;
          v.forEach((subk, subv) {
            if (subv is Map<String, dynamic>) {
              out.add(MapEntry(subk, subv));
              added = true;
            }
          });
          if (!added) out.add(MapEntry(k, Map<String, dynamic>.from(v)));
        }
      }
    });
  }
  return out;
}

class _SocialStats {
  final String name;
  final int? followers;
  final int? likes;
  final int? subscribers;
  final int? shares;
  final int? viewCount;
  final int? mediaCount;
  final int? followingCount;

  _SocialStats({
    required this.name,
    this.subscribers,
    this.followers,
    this.likes,
    this.shares,
    this.viewCount,
    this.mediaCount,
    this.followingCount,
  });

  factory _SocialStats.fromMap(String name, Map<String, dynamic> data) {
    int? parse(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.round();
      final str = v.toString().replaceAll(RegExp(r'[^0-9]'), '');
      if (str.isEmpty) return null;
      return int.tryParse(str);
    }

    int? extract(List<String> keys) {
      for (final k in keys) {
        if (data.containsKey(k)) return parse(data[k]);
      }
      for (final entry in data.entries) {
        if (keys.any((k) => entry.key.toLowerCase() == k.toLowerCase()) ||
            keys.any(
              (k) => entry.key.toLowerCase().contains(k.toLowerCase()),
            )) {
          return parse(entry.value);
        }
      }
      return null;
    }

    return _SocialStats(
      name: name,
      followers: extract(['followers', 'friends', 'fans']),
      likes: extract(['likes', 'hearts', 'favorites']),
      shares: extract(['shares']),
      viewCount: extract(['viewCount', 'views']),
      mediaCount: extract([
        'mediaCount',
        'media',
        'videos',
        'media_count',
        'posts',
        'post_count',
      ]),
      subscribers: extract(['subscriberCount', 'subscribers']),
      followingCount: extract([
        'following',
        'followingCount',
        'following_count',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (followers != null) 'followers': followers,
      if (likes != null) 'likes': likes,
      if (subscribers != null) 'subscribers': subscribers,
      if (shares != null) 'shares': shares,
      if (viewCount != null) 'views': viewCount,
      if (mediaCount != null) 'media': mediaCount,
      if (followingCount != null) 'following': followingCount,
    };
  }
}
