import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class InviteService {
  static final _db = FirebaseFirestore.instance;

  static String generateCode({int length = 8}) {
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // بدون 0/O/1/I عشان ما يتلخبطش
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  /// Create invite (Admin only by rules)
  static Future<String> createDoctorInvite({
    String? allowedEmail, // optional
    bool autoApprove = true, // انتِ اخترتي true
  }) async {
    // نضمن uniqueness: نكرر لحد ما نلاقي كود مش موجود
    String code;
    while (true) {
      code = generateCode();
      final exists = await _db
          .collection("doctor_invites")
          .where("code", isEqualTo: code)
          .limit(1)
          .get();
      if (exists.docs.isEmpty) break;
    }

    final docRef = await _db.collection("doctor_invites").add({
      "code": code,
      "role": "doctor",
      "autoApprove": autoApprove,
      "allowedEmail": allowedEmail?.trim(),
      "used": false,
      "usedByUid": null,
      "usedAt": null,
      "createdAt": DateTime.now().toIso8601String(),
    });

    return code; // نرجعه عشان الأدمن يبعته للدكتور
  }

  /// Verify invite code (must be unused)
  static Future<DocumentSnapshot<Map<String, dynamic>>?> verifyInviteCode(
      String code) async {
    final q = await _db
        .collection("doctor_invites")
        .where("code", isEqualTo: code.trim())
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;

    final doc = q.docs.first;
    final data = doc.data();
    final used = (data["used"] ?? false) as bool;
    if (used) return null;

    return doc;
  }

  /// Mark invite used
  static Future<void> markInviteUsed({
    required String inviteDocId,
    required String usedByUid,
  }) async {
    await _db.collection("doctor_invites").doc(inviteDocId).update({
      "used": true,
      "usedByUid": usedByUid,
      "usedAt": DateTime.now().toIso8601String(),
    });
  }
}