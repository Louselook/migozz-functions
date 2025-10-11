import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:migozz_app/features/profile/presentation/profile_screen.dart';

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

      // Debug: imprimir primeros documentos recibidos (hasta 3) para inspección
      try {
        for (
          var i = 0;
          i < (uSnap.docs.length < 3 ? uSnap.docs.length : 3);
          i++
        ) {
          final d = uSnap.docs[i];
          // ignore: avoid_print
          print('uSnap doc ${d.id}: ${d.data()}');
        }
        // ignore: empty_catches
      } catch (e) {}

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

      try {
        for (
          var i = 0;
          i < (dSnap.docs.length < 3 ? dSnap.docs.length : 3);
          i++
        ) {
          final d = dSnap.docs[i];
          // ignore: avoid_print
          print('dSnap doc ${d.id}: ${d.data()}');
        }
        // ignore: empty_catches
      } catch (e) {}
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
    final avatarRadius = (22.0 * scale).clamp(16.0, 32.0);
    final containerPadding = (12.0 * scale).clamp(8.0, 18.0);
    final displayNameFont = (16.0 * scale).clamp(13.0, 20.0);
    final usernameFont = (12.0 * scale).clamp(10.0, 14.0);
    final locationFont = (12.0 * scale).clamp(10.0, 14.0);
    final iconSize = (14.0 * scale).clamp(12.0, 18.0);
    final borderRadius = (12.0 * scale).clamp(8.0, 20.0);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureResults,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];

        // Prefetch avatar images to improve perceived loading speed.
        // Use a short circuit to avoid doing this repeatedly for identical snapshots.
        if (items.isNotEmpty) {
          for (final item in items) {
            final avatar = item['avatarUrl'] as String?;
            if (avatar != null && avatar.isNotEmpty) {
              // Use Flutter precache with CachedNetworkImageProvider so images
              // are downloaded into the image cache ahead of time.
              try {
                precacheImage(CachedNetworkImageProvider(avatar), context);
              } catch (e) {
                // ignore prefetch errors
              }
            }
          }
        }

        if (widget.query.isNotEmpty && items.isEmpty) {
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

        return ListView.separated(
          padding: EdgeInsets.symmetric(
            vertical: 12 * scale,
            horizontal: 12 * scale,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final avatar = item['avatarUrl'] as String?;

            // Helper local para leer distintos posibles nombres de campo
            String? pickString(Map m, List<String> keys) {
              for (final k in keys) {
                final v = m[k];
                if (v is String && v.trim().isNotEmpty) return v.trim();
              }
              return null;
            }

            final displayName =
                pickString(item, [
                  'displayName',
                  'displayname',
                  'display_name',
                  'name',
                  'fullName',
                  'full_name',
                ]) ??
                pickString(item, ['userName', 'username']) ??
                'Unknown';

            final username =
                pickString(item, [
                  'userName',
                  'username',
                  'user',
                  'user_name',
                ]) ??
                '';
            final location = item['location'] as Map<String, dynamic>?;
            final city = location?['city'] as String?;
            final state = location?['state'] as String?;
            final country = location?['country'] as String?;

            return InkWell(
              onTap: () {
                // Navigate to ProfileScreen showing the selected user
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: item['id'] as String),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(containerPadding),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: Row(
                  children: [
                    // Avatar: use CachedNetworkImage with placeholder and errorWidget
                    Container(
                      width: avatarRadius * 2,
                      height: avatarRadius * 2,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: ClipOval(
                        child: avatar != null && avatar.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: avatar,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: SizedBox(
                                    width: avatarRadius,
                                    height: avatarRadius,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person,
                                  size: avatarRadius,
                                  color: Colors.white70,
                                ),
                              )
                            : Icon(Icons.person, size: avatarRadius),
                      ),
                    ),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // displayName y username pegados (como en el prototipo)
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: displayName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: displayNameFont,
                                  ),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: '@$username',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: usernameFont,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6 * scale),
                          // location line: join available parts with a pin icon
                          Builder(
                            builder: (_) {
                              final parts = <String>[];
                              if (city != null && city.isNotEmpty) {
                                parts.add(city);
                              }
                              if (state != null && state.isNotEmpty) {
                                parts.add(state);
                              }
                              if (country != null && country.isNotEmpty) {
                                parts.add(country);
                              }
                              final locationLine = parts.join(', ');
                              return Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: iconSize,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(width: 6 * scale),
                                  Expanded(
                                    child: Text(
                                      locationLine,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: locationFont,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
              ),
            );
          },
          separatorBuilder: (context, index) => SizedBox(height: 12 * scale),
          itemCount: items.length,
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
        );
      },
    );
  }
}
