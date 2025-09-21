import 'package:cloud_firestore/cloud_firestore.dart';

class SocialService {
  final _db = FirebaseFirestore.instance;

  Future<void> addSocialLink(
    String uid,
    String linkUid,
    Map<String, dynamic> linkData,
  ) async {
    await _db
        .collection('userSocials')
        .doc(uid)
        .collection('links')
        .doc(linkUid)
        .set({...linkData, 'status': 'pending', 'lastFetched': null});
  }

  Future<List<Map<String, dynamic>>> getUserSocialLinks(String uid) async {
    final snapshot = await _db.collection('userSocials').doc(uid).collection('links').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}
