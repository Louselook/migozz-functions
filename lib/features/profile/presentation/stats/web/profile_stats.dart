// lib/features/profile/presentation/profile/web/web_profile_stats.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/profile/components/draggable_social_rail.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/profile_background_gradients.dart';
import 'package:migozz_app/features/profile/presentation/stats/web/components/web_date_range_picker_modal.dart';

class WebProfileStats extends StatefulWidget {
  final UserDTO user;
  const WebProfileStats({super.key, required this.user});

  @override
  State<WebProfileStats> createState() => _WebProfileStatsState();
}

class _WebProfileStatsState extends State<WebProfileStats> {
  bool _loading = true;
  DateTimeRange? selectedRange;
  List<SocialStats> _socials = [];
  Map<String, int> _totalsGlobal = {};
  late Offset initialSocialPosition;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final socials = await _loadUserSocials();
    final globalTotals = _calculateTotals(socials);
    setState(() {
      _socials = socials;
      _totalsGlobal = globalTotals;
      _loading = false;
    });
  }

  Future<List<SocialStats>> _loadUserSocials() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) return [];
      final data = doc.data();
      final dynamic ecosystem = data?['socialEcosystem'];
      final out = <SocialStats>[];
      for (final e in _parseEcosystem(ecosystem)) {
        out.add(SocialStats.fromMap(e.key, e.value));
      }
      return out;
    } catch (e) {
      debugPrint('Error cargando socials: $e');
      return [];
    }
  }

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
        final normalizedKey =
            _fieldRules[entry.key.toLowerCase()] ?? entry.key.toLowerCase();
        totals[normalizedKey] = (totals[normalizedKey] ?? 0) + entry.value;
      }
    }
    return totals;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showWebDateRangePicker(
      context,
      initialDateRange:
          selectedRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );

    if (picked != null) setState(() => selectedRange = picked);
  }

  String get rangeText {
    if (selectedRange == null) return "No seleccionado";
    final s = selectedRange!;
    // Format: "17 ene - 28 ene" to match image style mostly, but let's stick to what we had or improve
    // Use standard numeric for now: 17/1/2025
    return "${s.start.day}/${s.start.month}/${s.start.year} - ${s.end.day}/${s.end.month}/${s.end.year}";
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 900;

    // Social Rail params
    final socialItemSize = isSmall ? 35.0 : 45.0;
    final socialIconSize = isSmall ? 30.0 : 40.0;
    final socialRailWidth = socialItemSize + 16;
    final socialPadding = isSmall ? 20.0 : 30.0;
    final socialRailHeight = (socialItemSize * 4) + (8.0 * 3) + 16.0;

    initialSocialPosition = Offset(
      size.width - socialRailWidth - socialPadding,
      (size.height - socialRailHeight) / 2,
    );

    final leftMenuWidth = isSmall ? 80.0 : 100.0;

    // Totals calculations
    final totalLikes = _totalsGlobal['likes'] ?? 0;
    final totalComments = _totalsGlobal['comments'] ?? 0;
    final totalShares = _totalsGlobal['shares'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const ProfileBackgroundGradients(),

          // Main Content
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title
                          const Text(
                            'My Stats',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 50),

                          // Top Metrics Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MetricItem(
                                icon: Icons.favorite,
                                value: _formatNum(totalLikes),
                                // label: "Likes",
                              ),
                              const SizedBox(width: 80),
                              _MetricItem(
                                icon: Icons.chat_bubble,
                                value: _formatNum(totalComments),
                                // label: "Comments",
                              ),
                              const SizedBox(width: 80),
                              _MetricItem(
                                icon: Icons.reply,
                                value: _formatNum(totalShares),
                                // label: "Shares",
                              ),
                            ],
                          ),

                          const SizedBox(height: 60),

                          // Date Filter Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                child: InkWell(
                                  onTap: _pickDateRange,
                                  borderRadius: BorderRadius.circular(30),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        "Últimos 30 días",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Text(
                                rangeText,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 50),

                          // Stats Cards (Overview + Followers + Others)
                          Wrap(
                            spacing: 24,
                            runSpacing: 24,
                            alignment: WrapAlignment.center,
                            children: [
                              // Overview Card
                              _StatsCard(
                                title: "Overview",
                                icon: Icons.receipt_long,
                                width: 350,
                                child: Column(
                                  children: [
                                    _StatRow(
                                      icon: Icons.favorite,
                                      label: "Likes:",
                                      value: _formatNum(totalLikes).replaceAll(
                                        'k',
                                        ',000',
                                      ), // Rough adjustments for visual preference
                                    ),
                                    _StatRow(
                                      icon: Icons.chat_bubble,
                                      label: "Coments:",
                                      value: _formatNum(totalComments),
                                    ),
                                    _StatRow(
                                      icon: Icons.near_me,
                                      label: "Shared:",
                                      value: _formatNum(totalShares),
                                    ),
                                  ],
                                ),
                              ),

                              // Followers Card (Aggregated)
                              _StatsCard(
                                title: "Followers",
                                icon: Icons.person_add_alt_1,
                                width: 350,
                                child: Column(
                                  children:
                                      _socials
                                          .take(4)
                                          .map(
                                            (s) => _StatRow(
                                              imagePath:
                                                  "assets/icons/social_networks/mini_icon_${s.name.toLowerCase()}.svg",
                                              label: s.name,
                                              value: _formatNum(s.followers),
                                              showArrow: true,
                                            ),
                                          )
                                          .toList()
                                        ..add(
                                          _StatRow(
                                            icon: Icons.public,
                                            label: "All",
                                            value: _formatNum(
                                              _totalsGlobal['followers'] ?? 0,
                                            ),
                                            showArrow: true,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Side Menu
          const Positioned(left: 0, top: 0, bottom: 0, child: SideMenu()),

          // Draggable Rail
          DraggableSocialRail(
            key: ValueKey('social_rail_${size.width}'),
            initialPosition: initialSocialPosition,
            links: const [],
            itemSize: socialItemSize,
            iconSize: socialIconSize,
          ),
        ],
      ),
    );
  }
}

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
  "videoCount": "media",
};

String _formatNum(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)} mill.';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)} mil';
  return n.toString();
}

List<MapEntry<String, Map<String, dynamic>>> _parseEcosystem(
  dynamic ecosystem,
) {
  final out = <MapEntry<String, Map<String, dynamic>>>[];
  if (ecosystem == null) return out;
  if (ecosystem is List) {
    for (final item in ecosystem) {
      if (item is Map<String, dynamic>) {
        item.forEach((k, v) {
          if (v is Map<String, dynamic>) out.add(MapEntry(k, v));
        });
      }
    }
  } else if (ecosystem is Map<String, dynamic>) {
    ecosystem.forEach((k, v) {
      if (v is Map<String, dynamic>) {
        out.add(MapEntry(k, v));
      }
    });
  }
  return out;
}

class SocialStats {
  final String name;
  final int followers;
  final int likes;
  final int subscribers;
  final int shares;
  final int viewCount;
  final int mediaCount;
  final int followingCount;

  SocialStats({
    required this.name,
    required this.subscribers,
    required this.followers,
    required this.likes,
    required this.shares,
    required this.viewCount,
    required this.mediaCount,
    required this.followingCount,
  });

  factory SocialStats.fromMap(String name, Map<String, dynamic> data) {
    int parse(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.round();
      return int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }

    int extract(List<String> keys) {
      for (final k in keys) {
        if (data.containsKey(k)) return parse(data[k]);
      }
      for (final entry in data.entries) {
        if (keys.any(
          (k) => entry.key.toLowerCase().contains(k.toLowerCase()),
        )) {
          return parse(entry.value);
        }
      }
      return 0;
    }

    return SocialStats(
      name: name,
      followers: extract(['followers']),
      likes: extract(['likes']),
      shares: extract(['shares']),
      viewCount: extract(['viewCount']),
      mediaCount: extract(['mediaCount']),
      subscribers: extract(['subscriberCount', 'subscribers']),
      followingCount: extract(['following']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'followers': followers};
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String value;

  const _MetricItem({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 48),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final double width;

  const _StatsCard({
    required this.title,
    this.icon,
    required this.child,
    this.width = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white70, size: 22),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String label;
  final String value;
  final bool showArrow;

  const _StatRow({
    this.icon,
    this.imagePath,
    required this.label,
    required this.value,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Icon or Image
          if (imagePath != null)
            Image.asset(
              imagePath!,
              width: 16,
              height: 16,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.link, color: Colors.white, size: 16),
            )
          else if (icon != null)
            Icon(icon, color: Colors.white, size: 16)
          else
            const SizedBox(width: 16),

          const SizedBox(width: 12),

          // Label
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),

          // Value
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),

          if (showArrow) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white, size: 16),
          ],
        ],
      ),
    );
  }
}
