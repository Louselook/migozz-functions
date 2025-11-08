import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/auth/data/domain/models/location_dto.dart';
import 'package:migozz_app/features/auth/data/domain/models/user_dto.dart';
import 'package:migozz_app/features/search/web/components/search_result_card.dart';

/// ResultSearch realiza una búsqueda simple en la colección `users || profiles_public`
/// por `username` y `displayName`. Muestra los resultados en una lista.
class ResultSearch extends StatefulWidget {
  final String query;

  const ResultSearch({super.key, required this.query});

  @override
  State<ResultSearch> createState() => _ResultSearchState();
}

class _ResultSearchState extends State<ResultSearch> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<Map<String, dynamic>>> _futureResults;

  @override
  void initState() {
    super.initState();
    _futureResults = _search(widget.query.trim());
  }

  @override
  void didUpdateWidget(covariant ResultSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _futureResults = _search(widget.query.trim());
    }
  }

  /// Helper para parsear LocationDTO desde los datos dinámicos
  LocationDTO _parseLocation(dynamic locationData) {
    if (locationData is Map) {
      try {
        final locMap = Map<String, dynamic>.from(locationData);
        return LocationDTO(
          country: locMap['country']?.toString() ?? '',
          state: locMap['state']?.toString() ?? '',
          city: locMap['city']?.toString() ?? '',
          lat: (locMap['lat'] is num) ? (locMap['lat'] as num).toDouble() : 0.0,
          lng: (locMap['lng'] is num) ? (locMap['lng'] as num).toDouble() : 0.0,
        );
      } catch (e) {
        // Si falla el parsing, retornar LocationDTO vacío
        return LocationDTO(
          country: '',
          state: '',
          city: '',
          lat: 0.0,
          lng: 0.0,
        );
      }
    }
    // Si no es un Map, retornar LocationDTO vacío
    return LocationDTO(country: '', state: '', city: '', lat: 0.0, lng: 0.0);
  }

  Future<List<Map<String, dynamic>>> _search(String q) async {
    if (q.isEmpty) return [];

    final qTrim = q.trim();
    final qLower = qTrim.toLowerCase();
    final end = '\$qTrim\uf8ff';
    final endLower = '\$qLower\uf8ff';

    final List<Map<String, dynamic>> candidates = [];
    final seen = <String>{};

    try {
      final queries = <Query<Map<String, dynamic>>>[
        _firestore
            .collection('users')
            .where('userName', isGreaterThanOrEqualTo: qTrim)
            .where('userName', isLessThanOrEqualTo: end)
            .limit(50),
        _firestore
            .collection('users')
            .where('displayName', isGreaterThanOrEqualTo: qTrim)
            .where('displayName', isLessThanOrEqualTo: end)
            .limit(50),
        _firestore
            .collection('users')
            .where('userNameLower', isGreaterThanOrEqualTo: qLower)
            .where('userNameLower', isLessThanOrEqualTo: endLower)
            .limit(50),
        _firestore
            .collection('users')
            .where('displayNameLower', isGreaterThanOrEqualTo: qLower)
            .where('displayNameLower', isLessThanOrEqualTo: endLower)
            .limit(50),
      ];

      for (final qRef in queries) {
        try {
          final snap = await qRef.get();
          for (final doc in snap.docs) {
            if (seen.contains(doc.id)) continue;
            seen.add(doc.id);
            final data = doc.data();
            candidates.add({'id': doc.id, ...data});
          }
        } catch (e) {
          // ignore this particular query failure and continue
        }
      }
    } catch (e) {
      // ignore and continue
    }

    final List<Map<String, dynamic>> matched = [];
    for (final m in candidates) {
      final uname = ((m['userName'] ?? m['username'] ?? ''))
          .toString()
          .toLowerCase();
      final dname = ((m['displayName'] ?? '')).toString().toLowerCase();
      if (uname.contains(qLower) || dname.contains(qLower)) matched.add(m);
    }

    if (matched.isNotEmpty) return matched;

    // Fallback: scan limited batch
    try {
      final snap = await _firestore.collection('users').limit(200).get();
      for (final doc in snap.docs) {
        if (seen.contains(doc.id)) continue;
        final data = doc.data();
        final uname = ((data['userName'] ?? data['username'] ?? ''))
            .toString()
            .toLowerCase();
        final dname = ((data['displayName'] ?? '')).toString().toLowerCase();
        if (uname.contains(qLower) || dname.contains(qLower)) {
          matched.add({'id': doc.id, ...data});
        }
      }
    } catch (e) {
      // errores ignorados
    }
    return matched;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = size.width / 375.0;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureResults,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];

        if (widget.query.isNotEmpty && items.isEmpty) {
          return _buildEmptyState(scale);
        }

        return _buildResultsList(items, scale);
      },
    );
  }

  /// Widget para mostrar cuando no hay resultados
  Widget _buildEmptyState(double scale) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all((24.0 * scale).clamp(12.0, 40.0)),
        child: Text(
          'No se encontraron coincidencias',
          style: TextStyle(
            color: Colors.white70,
            fontSize: (16.0 * scale).clamp(12.0, 20.0),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Lista de resultados de búsqueda
  Widget _buildResultsList(List<Map<String, dynamic>> items, double scale) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 12 * scale, horizontal: 0),
      itemBuilder: (context, index) {
        final item = items[index];
        return SearchResultCard(
          userData: item,
          scale: scale,
          onTap: () {
            // Convertir los datos del usuario a UserDTO
            final user = UserDTO(
              displayName: item['displayName'] ?? '',
              username: item['userName'] ?? item['username'] ?? '',
              avatarUrl: item['avatarUrl'] ?? '',
              email: item['email'] ?? '',
              lang: item['lang'] ?? '',
              gender: item['gender'] ?? '',
              location: _parseLocation(item['location']),
              voiceNoteUrl: item['voiceNoteUrl'],
              socialEcosystem:
                  (item['socialEcosystem'] as List?)
                      ?.map((e) => Map<String, dynamic>.from(e))
                      .toList() ??
                  [],
            );

            // Navegar a la pantalla de perfil con el usuario buscado
            context.push('/profile-view', extra: user);
          },
        );
      },
      separatorBuilder: (context, index) => SizedBox(height: 8 * scale),
      itemCount: items.length,
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
    );
  }
}
