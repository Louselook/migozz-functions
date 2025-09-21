import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:migozz_app/core/color.dart';

class ProfileService {
  final _db = FirebaseFirestore.instance;

  Future<void> createUserProfile(String uid) async {
    await _db.collection('users').doc(uid).set({
      'totalFollowers': 0,
      'linksCount': 0,
      'onboarding': {'status': 'started', 'completed': false},
      'privacy': {'discoverable': true},
      'share': {'handle': '', 'publicUrl': '', 'qrUrl': ''},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }
}
