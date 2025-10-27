import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/components/atomics/network_list.dart';
import 'package:migozz_app/features/auth/data/domain/models/user_dto.dart';
import 'package:migozz_app/features/profile/components/draggable_social_rail.dart';
import 'package:migozz_app/features/profile/components/social_rail.dart';
import 'package:migozz_app/features/profile/components/utils/side_menu.dart';
import 'package:migozz_app/features/profile/presentation/profile/web/components/profile_background_gradients.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class WebProfileStats extends StatefulWidget {
  final UserDTO user;
  const WebProfileStats({
    super.key,
    required this.user,
  
  });

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
        final normalizedKey = _fieldRules[entry.key.toLowerCase()] ?? entry.key;
        totals[normalizedKey] = (totals[normalizedKey] ?? 0) + entry.value;
      }
    }
    return totals;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: now,
      initialDateRange:
          selectedRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked != null) setState(() => selectedRange = picked);
  }

  String get rangeText {
    if (selectedRange == null) return "No seleccionado";
    final s = selectedRange!;
    return "${s.start.day}/${s.start.month}/${s.start.year} → ${s.end.day}/${s.end.month}/${s.end.year}";
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 700;
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

    final totalFollowers = _totalsGlobal['followers'] ?? 0;
    final socialLinks =
        <SocialLink>[]; // podrías cargarlo igual que en el profile

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const ProfileBackgroundGradients(),
          Positioned(
            left: leftMenuWidth,
            right: 0,
            top: 0,
            bottom: 0,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _socials.isEmpty
                ? const Center(
                    child: Text(
                      "No tienes redes conectadas.",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : SafeArea(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 40,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'My Stats',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _Metric(
                                      icon: Icons.favorite,
                                      label:
                                          '${_formatNum(_totalsGlobal['likes'] ?? 0)} Likes',
                                    ),
                                    const SizedBox(width: 50),
                                    _Metric(
                                      icon: Icons.reply,
                                      label:
                                          '${_formatNum(_totalsGlobal['shares'] ?? 0)} Shares',
                                    ),
                                    const SizedBox(width: 50),
                                    _Metric(
                                      icon: Icons.people,
                                      label:
                                          '${_formatNum(totalFollowers)} Followers',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[800],
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: _pickDateRange,
                                      child: const Text("Select date"),
                                    ),
                                    const SizedBox(width: 20),
                                    Text(
                                      rangeText,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                _DataCard(
                                  title: "Overview",
                                  rows: [
                                    _RowData(
                                      label: "Likes:",
                                      value: _formatNum(
                                        _totalsGlobal['likes'] ?? 0,
                                      ),
                                    ),
                                    _RowData(
                                      label: "Shares:",
                                      value: _formatNum(
                                        _totalsGlobal['shares'] ?? 0,
                                      ),
                                    ),
                                    _RowData(
                                      label: "Followers:",
                                      value: _formatNum(totalFollowers),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                ..._socials.map((s) {
                                  final data = s.toJson();
                                  final name = s.name;
                                  final filteredEntries = data.entries.where((
                                    e,
                                  ) {
                                    final key = e.key.toLowerCase();
                                    final value = e.value;
                                    return value != null &&
                                        value.toString().trim().isNotEmpty &&
                                        value != 0 &&
                                        key != "id" &&
                                        key != "name" &&
                                        key != "iconpath" &&
                                        key != "label";
                                  }).toList();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _DataCard(
                                      title: name,
                                      image:
                                          "assets/icons/social_networks/mini_icon_${name.toLowerCase()}.png",
                                      rows: filteredEntries
                                          .map(
                                            (e) => _RowData(
                                              label: _formatKey(e.key),
                                              value: e.value.toString(),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: SideMenu(),
          ),
          DraggableSocialRail(
            key: ValueKey('social_rail_${size.width}'),
            initialPosition: initialSocialPosition,
            links: socialLinks,
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
  "followersCount": "followers",
  "hearts": "likes",
  "favorites": "likes",
  "videos": "media",
};

String _formatKey(String key) {
  final formatted = key
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .trim();
  return formatted.isNotEmpty
      ? formatted[0].toUpperCase() + formatted.substring(1)
      : key;
}

String _formatNum(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
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

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Metric({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: Colors.white, size: 28),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(color: Colors.white)),
    ],
  );
}

class _DataCard extends StatelessWidget {
  final String title;
  final String? image;
  final List<_RowData> rows;
  const _DataCard({required this.title, required this.rows, this.image});

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.grey[900],
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (image != null && image!.isNotEmpty)
                Image.asset(
                  image!,
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              if (image != null && image!.isNotEmpty) const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    ),
  );
}

class _RowData extends StatelessWidget {
  final String label, value;
  const _RowData({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

/// Modelo social igual que en mobile
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
    required this.followers,
    required this.likes,
    required this.subscribers,
    required this.shares,
    required this.viewCount,
    required this.mediaCount,
    required this.followingCount,
  });

  factory SocialStats.fromMap(String name, Map<String, dynamic> map) {
    return SocialStats(
      name: name,
      followers: (map['followers'] ?? 0) is int
          ? map['followers']
          : int.tryParse(map['followers'].toString()) ?? 0,
      likes: (map['likes'] ?? 0) is int
          ? map['likes']
          : int.tryParse(map['likes'].toString()) ?? 0,
      subscribers: (map['subscribers'] ?? 0) is int
          ? map['subscribers']
          : int.tryParse(map['subscribers'].toString()) ?? 0,
      shares: (map['shares'] ?? 0) is int
          ? map['shares']
          : int.tryParse(map['shares'].toString()) ?? 0,
      viewCount: (map['viewCount'] ?? 0) is int
          ? map['viewCount']
          : int.tryParse(map['viewCount'].toString()) ?? 0,
      mediaCount: (map['mediaCount'] ?? 0) is int
          ? map['mediaCount']
          : int.tryParse(map['mediaCount'].toString()) ?? 0,
      followingCount: (map['followingCount'] ?? 0) is int
          ? map['followingCount']
          : int.tryParse(map['followingCount'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'followers': followers,
    'likes': likes,
    'subscribers': subscribers,
    'shares': shares,
    'viewCount': viewCount,
    'mediaCount': mediaCount,
    'followingCount': followingCount,
  };
}
