import 'dart:async';
import 'dart:ui';
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFB86BFF), // Main color
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedRange = picked);
  }

  String get rangeText {
    if (selectedRange == null) {
      return "stats.rangeText".tr();
    }
    final s = selectedRange!;
    final f = DateFormat('MMM dd');
    return "${f.format(s.start)} - ${f.format(s.end)}";
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
                const SizedBox(height: 24),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Top Metrics Row
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _InfoCard(
                                            icon: Icons.favorite,
                                            value: _formatNum(
                                              _totalsGlobal['likes'] ?? 0,
                                            ),
                                            label: "stats.metrics.likes".tr(),
                                            color: const Color(
                                              0xFFFF5F9A,
                                            ), // Pinkish
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _InfoCard(
                                            icon: Icons.share,
                                            value: _formatNum(
                                              _totalsGlobal['shares'] ?? 0,
                                            ),
                                            label: "stats.metrics.shares".tr(),
                                            color: const Color(
                                              0xFFB86BFF,
                                            ), // Purpleish
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _InfoCard(
                                            icon: Icons.people,
                                            value: _formatNum(
                                              _totalsGlobal['followers'] ?? 0,
                                            ),
                                            label: "stats.metrics.followers"
                                                .tr(),
                                            color: const Color(
                                              0xFF6BFFB8,
                                            ), // Greenish
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),

                                    // Date Range (Simple Text)
                                    GestureDetector(
                                      onTap: _pickDateRange,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          rangeText,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    // Global Totals Card
                                    _GlassCard(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _CardHeader(
                                            icon: Icons.public,
                                            title: "stats.dataCardLabel.title"
                                                .tr(),
                                            color: Colors.blueAccent,
                                          ),
                                          const SizedBox(height: 16),
                                          _RowData(
                                            label: "stats.dataCardLabel.likes"
                                                .tr(),
                                            value: _formatNum(
                                              _totalsGlobal['likes'] ?? 0,
                                            ),
                                          ),
                                          const Divider(
                                            height: 16,
                                            color: Colors.white10,
                                          ),
                                          _RowData(
                                            label: "stats.dataCardLabel.shares"
                                                .tr(),
                                            value: _formatNum(
                                              _totalsGlobal['shares'] ?? 0,
                                            ),
                                          ),
                                          const Divider(
                                            height: 16,
                                            color: Colors.white10,
                                          ),
                                          _RowData(
                                            label:
                                                "stats.dataCardLabel.followers"
                                                    .tr(),
                                            value: _formatNum(
                                              _totalsGlobal['followers'] ?? 0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 24),
                                    Text(
                                      "Networks",
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Individual Networks
                                    ..._socials.map((s) {
                                      final data = s.toJson();
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

                                      if (filteredEntries.isEmpty) {
                                        return const SizedBox.shrink();
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _GlassCard(
                                          child: Column(
                                            children: [
                                              _SocialHeader(name: s.name),
                                              const SizedBox(height: 16),
                                              ListView.separated(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                itemCount:
                                                    filteredEntries.length,
                                                separatorBuilder: (ctx, i) =>
                                                    const Divider(
                                                      height: 16,
                                                      color: Colors.white10,
                                                    ),
                                                itemBuilder: (ctx, i) {
                                                  final e = filteredEntries[i];
                                                  final displayKey =
                                                      _applyFieldRules(e.key);
                                                  final formatted = _formatKey(
                                                    displayKey,
                                                  );
                                                  final numValue =
                                                      int.tryParse(
                                                        e.value.toString(),
                                                      ) ??
                                                      0;
                                                  return _RowData(
                                                    label: formatted,
                                                    value: _formatNum(numValue),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),

                                    const SizedBox(
                                      height: 100,
                                    ), // Bottom padding for nav bar
                                  ],
                                ),
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _CardHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SocialHeader extends StatelessWidget {
  final String name;
  const _SocialHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    final String? iconPath = SocialIconResolver.resolve(name);

    return Row(
      children: [
        if (iconPath != null) ...[
          SvgPicture.asset(iconPath, width: 24, height: 24),
          const SizedBox(width: 10),
        ],
        Text(
          name.capitalize(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RowData extends StatelessWidget {
  final String label, value;
  const _RowData({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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
    return '${(n / 1000000).toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}M';
  }
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '')}K';
  }
  return n.toString();
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
