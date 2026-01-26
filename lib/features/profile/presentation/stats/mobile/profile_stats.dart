import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/social_ecosystem_step_v3.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/profile/presentation/bloc/follower_cubit/follower_cubit.dart';
import 'package:migozz_app/features/profile/presentation/followers/followers_list_screen.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class ProfileStatsScreen extends StatefulWidget {
  const ProfileStatsScreen({super.key, required TutorialKeys tutorialKeys});

  @override
  State<ProfileStatsScreen> createState() => _ProfileStatsScreenState();
}

class _ProfileStatsScreenState extends State<ProfileStatsScreen> {
  bool _loading = true;
  // int _tab = 1;

  List<SocialStats> _socials = [];
  String _overviewSelection = 'community';
  Map<String, int> _totalsGlobal = {};

  // Stream subscription para escuchar cambios en tiempo real
  StreamSubscription<DocumentSnapshot>? _userDataSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    super.dispose();
  }

  /// Configurar listener en tiempo real para cambios en Firestore
  void _setupRealtimeListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    // Escuchar cambios en tiempo real del documento del usuario
    _userDataSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (docSnapshot) {
            if (docSnapshot.exists) {
              _processUserData(docSnapshot.data());
            } else {
              setState(() {
                _socials = [];
                _totalsGlobal = {};
                _loading = false;
              });
            }
          },
          onError: (error) {
            debugPrint('❌ Error en listener de Firestore: $error');
            setState(() => _loading = false);
          },
        );
  }

  /// Procesar datos del usuario y actualizar la UI
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
    final socials = <SocialStats>[];

    for (final e in _parseEcosystem(ecosystem)) {
      socials.add(SocialStats.fromMap(e.key, e.value));
    }

    // Calculate global social totals (still useful for overview etc if needed, but top icons use profile stats)
    final globalTotals = _calculateTotals(socials);
    _calculateNetworkTotals(socials);

    // Extract profile specific stats for top icons
    // Defaults to 0 if not present
    final int profileLikes = (data['likes'] ?? data['profileLikes'] ?? 0) is int
        ? (data['likes'] ?? data['profileLikes'] ?? 0)
        : int.tryParse(
                (data['likes'] ?? data['profileLikes'] ?? 0).toString(),
              ) ??
              0;

    final int unreadMessages =
        (data['unreadMessages'] ?? data['unreadMessageCount'] ?? 0) is int
        ? (data['unreadMessages'] ?? data['unreadMessageCount'] ?? 0)
        : int.tryParse(
                (data['unreadMessages'] ?? data['unreadMessageCount'] ?? 0)
                    .toString(),
              ) ??
              0;

    final int profileShares =
        (data['shares'] ?? data['profileShares'] ?? 0) is int
        ? (data['shares'] ?? data['profileShares'] ?? 0)
        : int.tryParse(
                (data['shares'] ?? data['profileShares'] ?? 0).toString(),
              ) ??
              0;

    // Merge profile stats into totals map or use specific keys
    globalTotals['profile_likes'] = profileLikes;
    globalTotals['unread_messages'] = unreadMessages;
    globalTotals['profile_shares'] = profileShares;

    setState(() {
      _socials = socials;
      _totalsGlobal = globalTotals;
      _loading = false;
    });

    debugPrint('✅ Datos actualizados: ${socials.length} redes sociales');
  }

  String normalizeStatKey(String key) {
    final lower = key.toLowerCase();
    return _fieldRules[lower] ?? lower;
  }

  /// Calcula los totales globales (suma de todas las redes)
  Map<String, int> _calculateTotals(List<SocialStats> socials) {
    final Map<String, int> totals = {};

    for (final s in socials) {
      final stats = {
        'followers': s.followers,
        'likes': s.likes,
        'views': s.viewCount,
        'shares': s.shares,
        'media': s.mediaCount,
        'following': s.followingCount,
        'subscribers': s.subscribers,
      };

      for (final entry in stats.entries) {
        final normalizedKey = normalizeStatKey(entry.key);
        totals[normalizedKey] =
            (totals[normalizedKey] ?? 0) + (entry.value ?? 0);
      }
    }

    return totals;
  }

  /// Calcula los totales por red social individualmente
  Map<String, Map<String, int>> _calculateNetworkTotals(
    List<SocialStats> socials,
  ) {
    final Map<String, Map<String, int>> totalsByNetwork = {};

    for (final s in socials) {
      final stats = {
        'followers': s.followers,
        'likes': s.likes,
        'views': s.viewCount,
        'shares': s.shares,
        'media': s.mediaCount,
        'following': s.followingCount,
        'subscribers': s.subscribers,
      };

      final normalized = <String, int>{};
      for (final entry in stats.entries) {
        final key = normalizeStatKey(entry.key);
        normalized[key] = (normalized[key] ?? 0) + (entry.value ?? 0);
      }

      totalsByNetwork[s.name] = normalized;
    }

    return totalsByNetwork;
  }

  /// Navegar a edición de redes sociales
  Future<void> _navigateToEditSocials() async {
    final authCubit = context.read<AuthCubit>();
    final userId = authCubit.state.firebaseUser?.uid;
    final userProfile = authCubit.state.userProfile;

    if (userId == null || userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('edit.validations.errorUserLogin'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final editCubit = context.read<EditCubit>();
    editCubit.setEditItem(EditItem.socialEcosystem);

    debugPrint('🔹 Navegando a SocialEcosystemStepV3 en modo EDIT');

    // Navegar y esperar el resultado
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: editCubit),
            BlocProvider.value(value: authCubit),
            BlocProvider.value(value: context.read<RegisterCubit>()),
          ],
          child: SocialEcosystemStepV3(
            controller:
                PageController(), // PageController temporal para navegación directa
            user: userProfile,
            mode: MoreUserDetailsMode.edit,
          ),
        ),
      ),
    );

    // La actualización será automática gracias al StreamSubscription
    debugPrint('✅ Regresó de edición - Stream manejará la actualización');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          TintesGradients(
            child: Container(height: MediaQuery.of(context).size.height * 0.35),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  "stats.title".tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Top Three Metrics
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    BlocBuilder<FollowerCubit, FollowerState>(
                                      builder: (context, followerState) {
                                        return _TopMetricItem(
                                          icon: Icons.person_add,
                                          value: _formatNum(
                                            followerState.followersCount > 0
                                                ? followerState.followersCount
                                                : (_totalsGlobal['profile_likes'] ??
                                                      0),
                                          ),
                                          label: "stats.fieldLabels.followers"
                                              .tr(),
                                          onTap: () {
                                            final authState = context
                                                .read<AuthCubit>()
                                                .state;
                                            final user = authState.userProfile;
                                            final userId =
                                                authState.firebaseUser?.uid;
                                            if (user != null &&
                                                userId != null) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      FollowersListScreen(
                                                        userId: userId,
                                                        username: user.username,
                                                        initialTab: 0,
                                                      ),
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      },
                                    ),
                                    // TODO: Descomentar cuando se necesiten estos datos para la version paga (usuarios premium)
                                    // _TopMetricItem(
                                    //   icon: Icons.chat_bubble,
                                    //   value: _formatNum(
                                    //     _totalsGlobal['unread_messages'] ?? 0,
                                    //   ),
                                    // ),
                                    // _TopMetricItem(
                                    //   icon: Icons.reply, // Curved arrow look
                                    //   value: _formatNum(
                                    //     _totalsGlobal['profile_shares'] ?? 0,
                                    //   ),
                                    //   isRotated: true,
                                    // ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // 2. Overview Card
                              _OverviewCard(
                                socials: _socials,
                                selectedMode: _overviewSelection,
                                onModeChanged: (val) {
                                  if (val != null) {
                                    setState(() => _overviewSelection = val);
                                  }
                                },
                              ),

                              const SizedBox(height: 20),

                              // 3. Individual Networks Logic
                              if (_socials.isEmpty)
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 40),
                                      Icon(
                                        Icons.analytics_outlined,
                                        size: 60,
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "stats.noStats.notSocials".tr(),
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      _EditButton(
                                        onTap: _navigateToEditSocials,
                                        label: "stats.noStats.addButton".tr(),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ..._socials.map(
                                  (s) => _NetworkStatsCard(social: s),
                                ),

                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Helper Widgets ---

class _TopMetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? label;
  final VoidCallback? onTap;

  const _TopMetricItem({
    required this.icon,
    required this.value,
    this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(
              label!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final List<SocialStats> socials;
  final String selectedMode;
  final ValueChanged<String?> onModeChanged;

  const _OverviewCard({
    required this.socials,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    SocialStats? findSocial(String name) {
      try {
        return socials.firstWhere(
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

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.featured_play_list_outlined,
                color: Colors.white70,
                size: 26,
              ),
              const SizedBox(width: 12),
              const Text(
                "Overview",
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
                // Community Dropdown
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedMode,
                      onChanged: onModeChanged,
                      isDense: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.white70,
                      ),
                      dropdownColor: const Color(0xFF2C2C2C),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'community',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.public,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text("stats.overview.community".tr()),
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
                                width: 14,
                                height: 14,
                              ),
                              const SizedBox(width: 6),
                              Text("stats.overview.migozz".tr()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Stats Grid
                if (selectedMode == 'community')
                  Builder(
                    builder: (context) {
                      final rows = <Widget>[];

                      if (instagram != null) {
                        rows.add(
                          _SmallSocialRow(
                            name: 'Instagram',
                            count: instagram.followers ?? 0,
                            iconPath:
                                'assets/icons/social_networks/Instagram.svg',
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
                            iconPath:
                                'assets/icons/social_networks/Facebook.svg',
                          ),
                        );
                      }

                      if (rows.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'stats.noData'.tr(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        );
                      }

                      List<Widget> withSpacing(List<Widget> items) {
                        return [
                          for (int i = 0; i < items.length; i++) ...[
                            items[i],
                            if (i != items.length - 1) const SizedBox(height: 18),
                          ],
                        ];
                      }

                      final left = <Widget>[];
                      final right = <Widget>[];
                      for (int i = 0; i < rows.length; i++) {
                        if (i.isEven) {
                          left.add(rows[i]);
                        } else {
                          right.add(rows[i]);
                        }
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Column(children: withSpacing(left))),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(children: withSpacing(right)),
                          ),
                        ],
                      );
                    },
                  )
                else
                  // Migozz followers stats
                  BlocBuilder<FollowerCubit, FollowerState>(
                    builder: (context, followerState) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SmallSocialRow(
                              name: 'stats.fieldLabels.followers'.tr(),
                              count: followerState.followersCount,
                              iconPath: 'assets/icons/social_networks/mini_icon_migozz.svg',
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _SmallSocialRow(
                              name: 'stats.fieldLabels.following'.tr(),
                              count: followerState.followingCount,
                              iconPath: 'assets/icons/social_networks/mini_icon_migozz.svg',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallSocialRow extends StatelessWidget {
  final String name;
  final int count;
  final String iconPath;

  const _SmallSocialRow({
    required this.name,
    required this.count,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          iconPath,
          width: 12,
          height: 12,
          placeholderBuilder: (_) =>
              const Icon(Icons.public, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                _formatNum(count),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NetworkStatsCard extends StatelessWidget {
  final SocialStats social;

  const _NetworkStatsCard({required this.social});

  @override
  Widget build(BuildContext context) {
    // Filter relevant stats (allow 0, filter nulls)
    final data = social.toJson();
    final filteredEntries = data.entries.where((e) {
      final key = e.key.toLowerCase();
      final value = e.value;
      return value != null &&
          value.toString().trim().isNotEmpty &&
          !['id', 'name', 'iconpath', 'label'].contains(key);
    }).toList();

    if (filteredEntries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildColorfulIcon(social.name),
                const SizedBox(width: 14),
                // Capitalize and show network name
                Text(
                  social.name.capitalize(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredEntries.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) {
                final e = filteredEntries[i];
                final displayKey = _applyFieldRules(e.key);
                final formatted = _formatKey(displayKey);
                final numValue = int.tryParse(e.value.toString()) ?? 0;

                return Row(
                  children: [
                    _getStatIcon(displayKey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formatted,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      _formatNum(numValue),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorfulIcon(String name) {
    String cleanName = name.capitalize();
    if (name.toLowerCase() == 'tiktok') cleanName = 'Tiktok';
    if (name.toLowerCase() == 'youtube') cleanName = 'Youtube';
    if (name.toLowerCase() == 'facebook') cleanName = 'Facebook';
    if (name.toLowerCase() == 'instagram') cleanName = 'Instagram';
    if (name.toLowerCase() == 'twitter') cleanName = 'Twitter';

    // Usar iconByLabel para obtener la ruta correcta, con fallback
    final path =
        iconByLabel[cleanName] ?? 'assets/icons/social_networks/Other.svg';

    return SvgPicture.asset(
      path,
      width: 16,
      height: 16,
      placeholderBuilder: (_) =>
          const Icon(Icons.public, color: Colors.white, size: 16),
    );
  }

  Widget _getStatIcon(String key) {
    IconData icon;
    switch (key.toLowerCase()) {
      case 'followers':
        icon = Icons.person_add_outlined;
        break;
      case 'following':
        icon = Icons.person_add_outlined;
        break;
      case 'likes':
      case 'media':
        // Map both Likes and Media to a Heart icon if that's what the design implies for engagement
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
    return Icon(icon, color: Colors.white70, size: 20);
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _EditButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFB86BFF), Color(0xFFFF5F9A)],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// Reglas personalizables
final Map<String, String> _fieldRules = {
  "friends": "followers",
  "fans": "followers",
  "subscribers": "followers",
  "subscriber": "followers",
  "subscriberCount": "followers",
  "followersCount": "followers",
  "hearts": "likes",
  "likes_count": "likes",
  "favorites": "likes",
  "videos": "media",
  "media_count": "media",
  "mediacount": "media",
  "videoCount": "media",
};

// Formateadores
String _formatKey(String key) {
  final translationKey = 'stats.fieldLabels.$key';
  final translated = translationKey.tr();

  // Si existe traducción, usarla; si no, formatear el texto original
  if (translated != translationKey) {
    return translated;
  }

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

String _formatNum(int n) {
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '')} mill.';
  }
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '')} mil';
  }
  return n.toString();
}

// Modelo SocialStats
class SocialStats {
  final String name;
  final int? followers;
  final int? likes;
  final int? subscribers;
  final int? shares;
  final int? viewCount;
  final int? mediaCount;
  final int? followingCount;

  SocialStats({
    required this.name,
    this.subscribers,
    this.followers,
    this.likes,
    this.shares,
    this.viewCount,
    this.mediaCount,
    this.followingCount,
  });

  factory SocialStats.fromMap(String name, Map<String, dynamic> data) {
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

    return SocialStats(
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
      'followers': followers,
      // TODO: Descomentar cuando se necesiten estos datos para la version paga (usuarios premium)
      // 'following': followingCount,
      // 'subscribersCount': subscribers,
      // 'likes': likes,
      // 'shares': shares,
      // 'viewCount': viewCount,
      // 'mediaCount': mediaCount,
    };
  }
}
