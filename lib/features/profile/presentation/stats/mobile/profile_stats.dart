import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:migozz_app/core/assets_constants.dart';
import 'package:migozz_app/features/auth/presentation/blocs/auth_cubit/auth_cubit.dart';
import 'package:migozz_app/features/auth/presentation/blocs/register_cubit/register_cubit.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/modules/social_ecosystem/social_ecosystem_step_v3.dart';
import 'package:migozz_app/features/auth/presentation/register/user_details/more_user_details.dart';
// import 'package:migozz_app/features/profile/components/bottom_nav.dart';
import 'package:migozz_app/features/profile/components/tintes_gradients.dart';
import 'package:migozz_app/features/profile/presentation/bloc/edit_cubit/edit_cubit_cubit.dart';
import 'package:migozz_app/features/tutorial/tutorial_keys.dart';

class ProfileStatsScreen extends StatefulWidget {
  const ProfileStatsScreen({super.key, required TutorialKeys tutorialKeys});

  @override
  State<ProfileStatsScreen> createState() => _ProfileStatsScreenState();
}

class _ProfileStatsScreenState extends State<ProfileStatsScreen> {
  DateTimeRange? selectedRange;
  bool _loading = true;
  // int _tab = 1;

  List<SocialStats> _socials = [];
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

    final globalTotals = _calculateTotals(socials);
    _calculateNetworkTotals(socials);

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
        totals[normalizedKey] = (totals[normalizedKey] ?? 0) + entry.value;
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
        normalized[key] = (normalized[key] ?? 0) + entry.value;
      }

      totalsByNetwork[s.name] = normalized;
    }

    return totalsByNetwork;
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
    if (selectedRange == null) {
      return "stats.rangeText".tr();
    }
    final s = selectedRange!;
    return "${s.start.day}/${s.start.month}/${s.start.year} → ${s.end.day}/${s.end.month}/${s.end.year}";
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
            child: Container(height: MediaQuery.of(context).size.height * 0.15),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      "stats.title".tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : _socials.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "stats.noStats.notSocials".tr(),
                                  style: const TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _navigateToEditSocials,
                                  child: Text("stats.noStats.addButton".tr()),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _Metric(
                                      icon: Icons.favorite,
                                      label:
                                          '${_formatNum(_totalsGlobal['likes'] ?? 0)} ${'stats.metrics.likes'.tr()}',
                                    ),
                                    _Metric(
                                      icon: Icons.reply,
                                      label:
                                          '${_formatNum(_totalsGlobal['shares'] ?? 0)} ${'stats.metrics.shares'.tr()}',
                                    ),
                                    _Metric(
                                      icon: Icons.people,
                                      label:
                                          '${_formatNum(_totalsGlobal['followers'] ?? 0)} ${'stats.metrics.followers'.tr()}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[800],
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: _pickDateRange,
                                      child: Text("stats.date".tr()),
                                    ),
                                    Text(
                                      rangeText,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _DataCard(
                                  iconKey: 'global',
                                  title: "stats.dataCardLabel.title".tr(),
                                  rows: [
                                    _RowData(
                                      label: "stats.dataCardLabel.likes".tr(),
                                      value: _formatNum(
                                        _totalsGlobal['likes'] ?? 0,
                                      ),
                                    ),
                                    _RowData(
                                      label: "stats.dataCardLabel.shares".tr(),
                                      value: _formatNum(
                                        _totalsGlobal['shares'] ?? 0,
                                      ),
                                    ),
                                    _RowData(
                                      label: "stats.dataCardLabel.followers"
                                          .tr(),
                                      value: _formatNum(
                                        _totalsGlobal['followers'] ?? 0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _socials.length,
                                    itemBuilder: (context, i) {
                                      final s = _socials[i];
                                      final data = s.toJson();
                                      final name = s.name;

                                      final filteredEntries = data.entries
                                          .where((e) {
                                            final key = e.key.toLowerCase();
                                            final value = e.value;
                                            return value != null &&
                                                value
                                                    .toString()
                                                    .trim()
                                                    .isNotEmpty &&
                                                value != 0 &&
                                                key != "id" &&
                                                key != "name" &&
                                                key != "iconpath" &&
                                                key != "label";
                                          })
                                          .toList();

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _DataCard(
                                          iconKey: name, 
                                          title: name,
                                          rows: filteredEntries.map((e) {
                                            final displayKey = _applyFieldRules(
                                              e.key,
                                            );
                                            final formatted = _formatKey(
                                              displayKey,
                                            );
                                            return _RowData(
                                              label: "$formatted:",
                                              value: e.value.toString(),
                                            );
                                          }).toList(),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: GradientBottomNav(
          //     currentIndex: _tab,
          //     onItemSelected: (i) => setState(() => _tab = i),
          //     onCenterTap: () async => await FirebaseAuth.instance.signOut(),
          //   ),
          // ),
        ],
      ),
    );
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
  "videoCount": "media",
};

// Formateadores
String _formatKey(String key) {
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
        // Nueva estructura: objeto directo con campo 'domain'
        if (item.containsKey('domain')) {
          final domain = item['domain'] as String;
          out.add(MapEntry(domain, item));
        } else {
          // Estructura antigua: objeto anidado {domain: {data}}
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
    return '${(n / 1000000).toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}M';
  }
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '')}K';
  }
  return n.toString();
}

// Widgets auxiliares
class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Metric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: Colors.white, size: 28),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white)),
    ],
  );
}

class _DataCard extends StatelessWidget {
  final String title;
  final String? iconKey; // clave lógica (instagram, twitter, etc)
  final List<_RowData> rows;

  const _DataCard({
    required this.title,
    required this.rows,
    this.iconKey,
  });

  @override
  Widget build(BuildContext context) {
    final String? iconPath =
        iconKey != null ? SocialIconResolver.resolve(iconKey!) : null;

    return Card(
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
                if (iconPath != null)
                  SvgPicture.asset(
                    iconPath,
                    width: 22,
                    height: 22,
                  ),
                if (iconPath != null) const SizedBox(width: 8),
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

// Modelo SocialStats
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
      subscribers: extract(['subscriberCount']),
      followingCount: extract(['following']),
    );
  }

  Map<String, dynamic> toJson() {
    final base = <String, dynamic>{
      'name': name,
      'followers': followers,
      'likes': likes,
      'shares': shares,
      'viewCount': viewCount,
      'mediaCount': mediaCount,
      'following': followingCount,
      'subscribersCount': subscribers,
    };
    return base;
  }
}
