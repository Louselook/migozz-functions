import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  Future<List<Map<String, dynamic>>> _search(String q) async {
    if (q.isEmpty) return [];

    // Búsqueda simple por prefijo. Firestore no tiene startsWith directo,
    // usamos range query: >= q and <= q + '\uf8ff'
    final end = '$q\uf8ff';

    final List<Map<String, dynamic>> results = [];

    try {
      // Buscar por userName en la colección 'users'
      final uSnap = await _firestore
          .collection('users')
          .where('userName', isGreaterThanOrEqualTo: q)
          .where('userName', isLessThanOrEqualTo: end)
          .limit(50)
          .get();

      for (final doc in uSnap.docs) {
        final data = doc.data();
        results.add({'id': doc.id, ...data});
      }

      // Buscar por displayName (evitamos duplicados por id)
      final dSnap = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: q)
          .where('displayName', isLessThanOrEqualTo: end)
          .limit(50)
          .get();

      for (final doc in dSnap.docs) {
        if (!results.any((r) => r['id'] == doc.id)) {
          final data = doc.data();
          results.add({'id': doc.id, ...data});
        }
      }
    } catch (e) {
      // En caso de error, devolver lista vacía
      return [];
    }

    return results;
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
            // Navigate to ProfileScreen showing the selected user
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (_) => ProfileScreen(userId: item['id'] as String),
            //   ),
            // );
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
