import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/profile/components/bottom_nav.dart';

class ProfileStatsScreen extends StatefulWidget {
  const ProfileStatsScreen({super.key});

  @override
  State<ProfileStatsScreen> createState() => _ProfileStatsScreenState();
}

class _ProfileStatsScreenState extends State<ProfileStatsScreen> {
  DateTimeRange? selectedRange;
  bool _loading = true;
  int _tab = 1;

  List<SocialStats> _socials = [];
  Map<String, int> _totals = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Carga de datos del usuario

  Map<String, dynamic> _fieldMap = {};

  Future<void> _loadData() async {
    setState(() => _loading = true);

    // Cargar mapeo global
    _fieldMap = await _loadFieldMapping();

    // Cargar redes del usuario
    final socials = await _loadUserSocials();

    // Calcular totales
    final totals = _calculateTotals(socials);

    setState(() {
      _socials = socials;
      _totals = totals;
      _loading = false;
    });

    debugPrint('Socials detectadas: ${_socials.map((s) => s.name).toList()}');
    debugPrint('Totales: $_totals');
  }

  Future<Map<String, dynamic>> _loadFieldMapping() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('socialFieldMapping')
          .get();

      if (!doc.exists || doc.data() == null) return {};

      final raw = doc.data()!;
      final result = <String, dynamic>{};

      raw.forEach((key, value) {
        if (value is Map) {
          result[key.toLowerCase()] = Map<String, dynamic>.from(value);
        }
      });

      debugPrint('Field mapping cargado: $result');
      return result;
    } catch (e) {
      debugPrint('Error cargando mapping: $e');
      return {};
    }
  }

  // Carga y parsing robusto

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
      debugPrint('Data Firestore: $data');

      final dynamic ecosystem = data?['socialEcosystem'];
      final List<SocialStats> out = [];

      final entries = _parseEcosystem(ecosystem);
      for (final e in entries) {
        out.add(SocialStats.fromMap(e.key, e.value, _fieldMap));
      }

      return out;
    } catch (e, st) {
      debugPrint('Error cargando socials: $e\n$st');
      return [];
    }
  }

  // Calculadora de totales

  Map<String, int> _calculateTotals(List<SocialStats> list) {
    int followers = 0;
    int likes = 0;
    int shares = 0;

    for (final s in list) {
      followers += s.followers;
      likes += s.likes;
      shares += s.shares;
    }

    return {'followers': followers, 'likes': likes, 'shares': shares};
  }

  // Selector de rango (sin cambios)

  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1990, 1, 1),
      lastDate: now,
      initialDateRange:
          selectedRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      helpText: 'Selecciona el rango de fechas',
      saveText: 'Seleccionar',
    );

    if (picked != null) {
      setState(() {
        selectedRange = picked;
      });
    }
  }

  String get rangeText {
    if (selectedRange == null) return "No seleccionado";
    final start = selectedRange!.start;
    final end = selectedRange!.end;
    return "${start.day}/${start.month}/${start.year} → ${end.day}/${end.month}/${end.year}";
  }

  // BUILD: UI usando _Metric y _DataCard

  @override
  Widget build(BuildContext context) {
  final double bottomGradientHeight = MediaQuery.of(context).size.height * 0.15;

  return Scaffold(
    backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo con gradientes decorativos
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.9, -0.9), // arriba-izquierda
                  radius: 1.0,
                  colors: [
                    const Color(0xFFB86BFF).withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottomGradientHeight * 1.6,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.9, 1.4),
                    radius: 1.2,
                    colors: [
                      const Color(0xFFF3C623).withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                    stops: const [0.4, 0.75],
                  ),
                ),
              ),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Título superior
                  const Text(
                    'My Stats',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contenido principal (usa Expanded para scroll)
                  Expanded(
                    child: Center(
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : _socials.isEmpty
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Aún no tienes socials conectadas, ¡Conéctalas!',
                                      style: TextStyle(color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: _loadData,
                                      child: const Text('Actualizar'),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    // Métricas totales
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _Metric(
                                          icon: Icons.favorite,
                                          label:
                                              '${_formatNum(_totals['likes'] ?? 0)} likes',
                                        ),
                                        _Metric(
                                          icon: Icons.reply,
                                          label:
                                              '${_formatNum(_totals['shares'] ?? 0)} shares',
                                        ),
                                        _Metric(
                                          icon: Icons.people,
                                          label:
                                              '${_formatNum(_totals['followers'] ?? 0)} followers',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Rango de fechas
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
                                          child:
                                              const Text("Seleccionar fecha"),
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

                                    // Card resumen general
                                    _DataCard(
                                      image:
                                          'assets/icons/social_networks/mini_icon_migozz.png',
                                      title: "Overview",
                                      rows: [
                                        _RowData(
                                          label: "Likes:",
                                          value:
                                              _formatNum(_totals['likes'] ?? 0),
                                        ),
                                        _RowData(
                                          label: "Shares:",
                                          value:
                                              _formatNum(_totals['shares'] ?? 0),
                                        ),
                                        _RowData(
                                          label: "Followers:",
                                          value: _formatNum(
                                              _totals['followers'] ?? 0),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Lista de redes sociales
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: _socials.length,
                                        itemBuilder: (context, i) {
                                          final s = _socials[i];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 12),
                                            child: _DataCard(
                                              image:
                                                  "assets/icons/social_networks/mini_icon_${(s.name).toLowerCase()}.png",
                                              title: s.name,
                                              rows: [
                                                _RowData(
                                                  label: "Followers:",
                                                  value: _formatNum(s.followers),
                                                ),
                                                _RowData(
                                                  label: "Likes:",
                                                  value: _formatNum(s.likes),
                                                ),
                                                _RowData(
                                                  label: "Shares:",
                                                  value: _formatNum(s.shares),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
                  alignment: Alignment.bottomCenter,
                  child: GradientBottomNav(
                    currentIndex: _tab,
                    onItemSelected: (i) => setState(() => _tab = i),
                    onCenterTap: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

// Helpers globales

// Parsea el campo socialEcosystem con varias formas comunes y devuelve pares (SocialName, dataMap)
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
    // ej: { "0": { "tiktok": { ... } }, "1": { "spotify": { ... } } } depende mucho si el usuario conecta o no redes
    ecosystem.forEach((k, v) {
      if (v is Map<String, dynamic>) {
        if (v.length == 1 && v.values.first is Map<String, dynamic>) {
          final innerKey = v.keys.first;
          final innerVal = v[innerKey] as Map<String, dynamic>;
          out.add(MapEntry(innerKey, innerVal));
        } else {
          // Caso: v podría ser { "tiktok": {...}, "spotify": {...} } o directamente los datos
          bool added = false;
          v.forEach((subk, subv) {
            if (subv is Map<String, dynamic>) {
              out.add(MapEntry(subk, subv));
              added = true;
            }
          });
          if (!added) {
            // Fallback: use k como nombre si no se detectó subcolección
            out.add(MapEntry(k, Map<String, dynamic>.from(v)));
          }
        }
      }
    });
  }

  return out;
}

// Abrevia números (1200 -> 1.2K, 1230000 -> 1.23M)
String _formatNum(int n) {
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}M';
  }
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '')}K';
  }
  return n.toString();
}

// Widgets auxiliares (sin cambiar)
class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Metric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}

class _DataCard extends StatelessWidget {
  final String title;
  final String? image;
  final List<_RowData> rows;
  const _DataCard({required this.title, required this.rows, this.image});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      elevation: 0,
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
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                if (image != null && image!.isNotEmpty)
                  const SizedBox(width: 8), // separación entre icono y texto
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
  final String label;
  final String value;
  const _RowData({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
}

// Modelo SocialStats
class SocialStats {
  final String name;
  final int followers;
  final int likes;
  final int shares;

  SocialStats({
    required this.name,
    required this.followers,
    required this.likes,
    required this.shares,
  });

  factory SocialStats.fromMap(
    String name,
    Map<String, dynamic> data,
    Map<String, dynamic> fieldMap,
  ) {
    final lowerPlatform = name.toLowerCase();
    final mapping =
        fieldMap[lowerPlatform] ?? {}; // Ej: {followers: "subscriberCount"}

    final followerField = (mapping['followers'] ?? 'followers').toString();
    final likesField = (mapping['likes'] ?? 'likes').toString();
    final sharesField = (mapping['shares'] ?? 'shares').toString();

    // Fallbacks conocidos por plataformas
    const followerFallbacks = [
      'followercount',
      'followers',
      'fans',
      'subscribers',
      'subscribercount',
      'subscriber_count',
    ];
    const likesFallbacks = [
      'likes',
      'likecount',
      'hearts',
      'favoritecount',
      'favorites',
      'favorite_count',
    ];
    const sharesFallbacks = [
      'shares',
      'sharecount',
      'reposts',
      'retweets',
      'retweetcount',
      'repostcount',
    ];

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.round();
      return int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }

    int extract(String primary, List<String> fallbacks, String metricName) {
      final primaryLower = primary.toLowerCase();
      if (data.containsKey(primary)) {
        return parseInt(data[primary]);
      }
      if (data.containsKey(primaryLower)) {
        return parseInt(data[primaryLower]);
      }
      for (final f in fallbacks) {
        if (data.containsKey(f)) {
          debugPrint('🔁 Fallback "$f" usado para $metricName en $name');
          return parseInt(data[f]);
        }
      }
      // Búsqueda heurística parcial
      for (final entry in data.entries) {
        final k = entry.key.toString().toLowerCase();
        if (fallbacks.any((f) => k.contains(f)) || k.contains(primaryLower)) {
          debugPrint('🔎 Heurística detectó "$k" para $metricName en $name');
          return parseInt(entry.value);
        }
      }
      return 0;
    }

    final followers = extract(followerField, followerFallbacks, 'followers');
    final likes = extract(likesField, likesFallbacks, 'likes');
    final shares = extract(sharesField, sharesFallbacks, 'shares');

    if (followers == 0 && likes == 0 && shares == 0) {
      debugPrint(
        '⚠️ Ninguna métrica encontrada para $name. Claves disponibles: ${data.keys.toList()}',
      );
    }

    return SocialStats(
      name: name,
      followers: followers,
      likes: likes,
      shares: shares,
    );
  }
}
