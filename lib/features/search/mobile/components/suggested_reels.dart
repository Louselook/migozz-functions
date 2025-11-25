import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/features/auth/data/domain/models/user/user_dto.dart';
import 'package:migozz_app/features/search/mobile/components/user_card.dart';

class SuggestedReels extends StatelessWidget {
  final double topPadding;

  const SuggestedReels({super.key, required this.topPadding});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('users').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "search.notFound.searchNoResult".tr(),
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          );
        }

        final List<UserDTO> users = snapshot.data!.docs
            .where((doc) => doc.id != currentUserId)
            .map((doc) => UserDTO.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        return GridView.builder(
          padding: EdgeInsets.only(top: topPadding),
          physics: const BouncingScrollPhysics(),
          itemCount: users.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            return UserCard(user: users[index]);
          },
        );
      },
    );
  }
}
