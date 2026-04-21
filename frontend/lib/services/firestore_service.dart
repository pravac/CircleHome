import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getHouseholdMembers(String householdId) {
    return _db
        .collection('users')
        .where('householdId', isEqualTo: householdId)
        .snapshots();
  }

  Stream<QuerySnapshot> getTasks(String householdId) {
    return _db
        .collection('tasks')
        .where('householdId', isEqualTo: householdId)
        .where('completed', isEqualTo: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getActivities(String householdId) {
    return _db
        .collection('activities')
        .where('householdId', isEqualTo: householdId)
        .limit(10)
        .snapshots();
  }

  Future<void> addTask({
    required String title,
    required String category,
    required String assignedTo,
    required String householdId,
    required String dueLabel,
    required DateTime dueDateTime,
  }) async {
    await _db.collection('tasks').add({
      'title': title,
      'category': category,
      'assignedTo': assignedTo,
      'householdId': householdId,
      'dueLabel': dueLabel,
      'dueDateTime': Timestamp.fromDate(dueDateTime),
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeTask({
    required String docId,
    required String title,
    required String userName,
    required String householdId,
  }) async {
    await _db.collection('tasks').doc(docId).update({
      'completed': true,
    });

    await _db.collection('activities').add({
      'text': '$userName completed "$title"',
      'timeLabel': 'Just now',
      'householdId': householdId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTask(String docId) async {
    await _db.collection('tasks').doc(docId).delete();
  }

  Future<void> createUserDocument({
    required String uid,
    required String email,
    required String householdId,
    String? name,
  }) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'name': name ?? email.split('@').first,
      'householdId': householdId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocument(
    String uid,
  ) async {
    return _db.collection('users').doc(uid).get();
  }

  Future<String?> getHouseholdIdForUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    return data?['householdId'] as String?;
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(rand.nextInt(chars.length)),
      ),
    );
  }

  Future<String> createHousehold({
    required String name,
    required String userId,
  }) async {
    final code = _generateCode();

    final doc = await _db.collection('households').add({
      'name': name,
      'code': code,
      'createdBy': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('users').doc(userId).update({
      'householdId': doc.id,
    });

    return code;
  }

  Future<bool> joinHouseholdByCode({
    required String code,
    required String userId,
  }) async {
    final query = await _db
        .collection('households')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;

    final householdId = query.docs.first.id;

    await _db.collection('users').doc(userId).update({
      'householdId': householdId,
    });

    return true;
  }

  Future<Map<String, dynamic>?> getHousehold(String householdId) async {
    final doc = await _db.collection('households').doc(householdId).get();
    return doc.data();
  }
}

