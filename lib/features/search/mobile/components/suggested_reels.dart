import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/search/mobile/components/user_card.dart';

class SuggestedReels extends StatefulWidget {
  final double topPadding;

  const SuggestedReels({super.key, required this.topPadding});

  @override
  State<SuggestedReels> createState() => _SuggestedReelsState();
}

class _SuggestedReelsState extends State<SuggestedReels> {
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  int _refreshKey = 0;

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() async {
    debugPrint('🔄 [SuggestedReels] Refrescando usuarios sugeridos...');

    // Pequeño delay para feedback visual
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _refreshKey++; // Forzar rebuild del StreamBuilder
    });

    _refreshController.refreshCompleted();
    debugPrint('✅ [SuggestedReels] Refresh completado');
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    debugPrint(
      '🔍 [SuggestedReels] Construyendo con StreamBuilder (key: $_refreshKey)',
    );

    return StreamBuilder<QuerySnapshot>(
      key: ValueKey('suggested-$_refreshKey'),
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          debugPrint('❌ [SuggestedReels] Error: ${snapshot.error}');
          return Center(
            child: Text(
              "search.notFound.searchError".tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "search.notFound.searchNoResult".tr(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        final List<UserDTO> users = snapshot.data!.docs
            .where((doc) => doc.id != currentUserId)
            .map((doc) {
              try {
                return UserDTO.fromMap(doc.data() as Map<String, dynamic>);
              } catch (e) {
                debugPrint('⚠️ [SuggestedReels] Error parseando usuario: $e');
                return null;
              }
            })
            .whereType<UserDTO>()
            .toList();

        if (users.isEmpty) {
          return Center(
            child: Text(
              "search.notFound.searchNoResult".tr(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        debugPrint('✅ [SuggestedReels] ${users.length} usuarios encontrados');

        // ✅ Usar SmartRefresher con CustomScrollView
        return SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          enablePullDown: true,
          enablePullUp: false,
          header: const WaterDropMaterialHeader(
            backgroundColor: Color(0xFF722583),
            color: Colors.white,
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Espacio superior
              SliverToBoxAdapter(child: SizedBox(height: widget.topPadding)),
              // Grid de usuarios
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return UserCard(user: users[index]);
                }, childCount: users.length),
              ),
            ],
          ),
        );
      },
    );
  }
}
