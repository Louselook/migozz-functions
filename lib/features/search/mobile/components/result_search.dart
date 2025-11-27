import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/location_dto.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';

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
    debugPrint('🔍 [ResultSearch] Búsqueda inicial: "${widget.query}"');
  }

  @override
  void didUpdateWidget(covariant ResultSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Buscar de nuevo cada vez que cambia la query
    if (oldWidget.query != widget.query) {
      debugPrint('🔄 [ResultSearch] Nueva búsqueda: "${widget.query}"');
      setState(() {
        _futureResults = _search(widget.query.trim());
      });
    }
  }

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
        return LocationDTO(
          country: '',
          state: '',
          city: '',
          lat: 0.0,
          lng: 0.0,
        );
      }
    }
    return LocationDTO(country: '', state: '', city: '', lat: 0.0, lng: 0.0);
  }

  Future<List<Map<String, dynamic>>> _search(String q) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    if (q.isEmpty) return [];

    final qTrim = q.trim();
    final qLower = qTrim.toLowerCase();
    final end = '$qTrim\uf8ff';
    final endLower = '$qLower\uf8ff';

    final List<Map<String, dynamic>> candidates = [];
    final seen = <String>{};

    try {
      // Queries optimizadas de Firestore
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
            if (doc.id == currentUserId) continue;
            if (seen.contains(doc.id)) continue;

            seen.add(doc.id);
            final data = doc.data();
            candidates.add({'id': doc.id, ...data});
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Filtrado client-side
    final List<Map<String, dynamic>> matched = [];

    for (final m in candidates) {
      final uname = ((m['userName'] ?? m['username'] ?? ''))
          .toString()
          .toLowerCase();
      final dname = ((m['displayName'] ?? '')).toString().toLowerCase();

      if (uname.contains(qLower) || dname.contains(qLower)) {
        matched.add(m);
      }
    }

    if (matched.isNotEmpty) {
      debugPrint('✅ [ResultSearch] ${matched.length} resultados encontrados');
      return matched;
    }

    // Fallback
    try {
      final snap = await _firestore.collection('users').limit(200).get();
      for (final doc in snap.docs) {
        if (doc.id == currentUserId) continue;
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
    } catch (_) {}

    debugPrint('✅ [ResultSearch] ${matched.length} resultados totales');
    return matched;
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
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final items = snapshot.data ?? [];

        // Prefetch avatar images
        if (items.isNotEmpty) {
          for (final item in items) {
            final avatar = item['avatarUrl'] as String?;
            if (avatar != null && avatar.isNotEmpty) {
              try {
                precacheImage(CachedNetworkImageProvider(avatar), context);
              } catch (e) {
                // ignore
              }
            }
          }
        }

        if (widget.query.isNotEmpty && items.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all((24.0 * scale).clamp(12.0, 40.0)),
              child: Text(
                "search.notFound.searchNoResult".tr(),
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
                final userMap = item;
                final user = UserDTO(
                  displayName: userMap['displayName'] ?? '',
                  username: userMap['userName'] ?? userMap['username'] ?? '',
                  avatarUrl: userMap['avatarUrl'] ?? '',
                  email: userMap['email'] ?? '',
                  lang: userMap['lang'] ?? '',
                  gender: userMap['gender'] ?? '',
                  location: _parseLocation(userMap['location']),
                  voiceNoteUrl: userMap['voiceNoteUrl'],
                  socialEcosystem:
                      (userMap['socialEcosystem'] as List?)
                          ?.map((e) => Map<String, dynamic>.from(e))
                          .toList() ??
                      [],
                );

                context.push('/profile-view', extra: user);
              },
              child: Container(
                padding: EdgeInsets.all(containerPadding),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: Row(
                  children: [
                    // Avatar
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
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.person,
                                  size: avatarRadius,
                                  color: Colors.white70,
                                ),
                              )
                            : Icon(
                                Icons.person,
                                size: avatarRadius,
                                color: Colors.white70,
                              ),
                      ),
                    ),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
