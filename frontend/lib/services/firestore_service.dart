import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    required String assignedTo,
    required String householdId,
    required String dueLabel,
  }) async {
    await _db.collection('tasks').add({
      'title': title,
      'assignedTo': assignedTo,
      'householdId': householdId,
      'dueLabel': dueLabel,
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
}