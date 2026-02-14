import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/search/web/components/suggestion_card.dart';

class SuggestedReels extends StatelessWidget {
  const SuggestedReels({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final size = MediaQuery.of(context).size;

    // Responsive grid: más columnas en pantallas más grandes
    final crossAxisCount = size.width > 1200
        ? 5
        : (size.width > 900 ? 4 : (size.width > 600 ? 3 : 2));

    return StreamBuilder<QuerySnapshot>(
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
          debugPrint('❌ [WebSuggestedReels] Error: ${snapshot.error}');
          return Center(
            child: Text(
              'search.notFound.searchError'.tr(),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'search.notFound.searchNoResult'.tr(),
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
                debugPrint(
                  '⚠️ [WebSuggestedReels] Error parseando usuario: $e',
                );
                return null;
              }
            })
            .whereType<UserDTO>()
            .toList();

        if (users.isEmpty) {
          return Center(
            child: Text(
              'search.notFound.searchNoResult'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        debugPrint(
          '✅ [WebSuggestedReels] ${users.length} usuarios encontrados',
        );

        return GridView.builder(
          padding: const EdgeInsets.only(top: 4, bottom: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: users.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            return SuggestionCard(user: users[index]);
          },
        );
      },
    );
  }
}
