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

  Stream<QuerySnapshot> getAllTasks(String householdId) {
    return _db
        .collection('tasks')
        .where('householdId', isEqualTo: householdId)
        .snapshots();
  }

  Stream<QuerySnapshot> getActivities(String householdId) {
    return _db
        .collection('activities')
        .where('householdId', isEqualTo: householdId)
        .limit(10)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Future<void> addTask({
    required String title,
    required String category,
    required String assignedTo,
    required String householdId,
    required String dueLabel,
    required DateTime dueDateTime,
    int difficulty = 3,
    bool isRecurring = false,
    String recurrenceFrequency = 'none',
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
      'difficulty': difficulty,
      'isRecurring': isRecurring,
      'recurrenceFrequency': recurrenceFrequency,
    });
  }

  Future<void> completeTask({
    required String docId,
    required String title,
    required String userName,
    required String householdId,
    String photoUrl = '',
  }) async {
    await _db.collection('tasks').doc(docId).update({
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('activities').add({
      'text': '$userName completed "$title"',
      'householdId': householdId,
      'createdAt': FieldValue.serverTimestamp(),
      'actorName': userName,
      'actorPhotoUrl': photoUrl,
    });
  }

  Future<void> uncompleteTask(String docId) async {
    await _db.collection('tasks').doc(docId).update({
      'completed': false,
      'completedAt': FieldValue.delete(),
    });
  }

  Future<void> deleteTask(String docId) async {
    await _db.collection('tasks').doc(docId).delete();
  }

  Future<void> updateUserProfile(
    String uid, {
    String? name,
    int? workload,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (workload != null) data['workload'] = workload;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (data.isNotEmpty) {
      await _db.collection('users').doc(uid).update(data);
    }
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

  Stream<DocumentSnapshot<Map<String, dynamic>>> getHouseholdStream(
    String householdId,
  ) {
    return _db.collection('households').doc(householdId).snapshots();
  }

  Future<void> updateHousehold(
    String householdId, {
    String? name,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (data.isNotEmpty) {
      await _db.collection('households').doc(householdId).update(data);
    }
  }

  // Swap / reassign requests

  Future<void> createSwapRequest({
    required String type, // 'swap' or 'reassign'
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    required String offerTaskId,
    required String offerTaskTitle,
    required String householdId,
    String? requestTaskId,
    String? requestTaskTitle,
  }) async {
    await _db.collection('swapRequests').add({
      'type': type,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'offerTaskId': offerTaskId,
      'offerTaskTitle': offerTaskTitle,
      'requestTaskId': requestTaskId,
      'requestTaskTitle': requestTaskTitle,
      'householdId': householdId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getIncomingRequests(String toUserId) {
    return _db
        .collection('swapRequests')
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> acceptSwapRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    final type = data['type'] as String;
    final offerTaskId = data['offerTaskId'] as String;
    final toUserName = data['toUserName'] as String;
    final fromUserName = data['fromUserName'] as String;

    final batch = _db.batch();

    batch.update(_db.collection('tasks').doc(offerTaskId), {
      'assignedTo': toUserName,
    });

    if (type == 'swap') {
      final requestTaskId = data['requestTaskId'] as String;
      batch.update(_db.collection('tasks').doc(requestTaskId), {
        'assignedTo': fromUserName,
      });
    }

    batch.update(_db.collection('swapRequests').doc(requestId), {
      'status': 'accepted',
    });

    await batch.commit();
  }

  Future<void> rejectSwapRequest(String requestId) async {
    await _db
        .collection('swapRequests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  // Returns all tasks for a given member name (filter completed client-side)
  Stream<QuerySnapshot> getMemberTasks(String householdId, String memberName) {
    return _db
        .collection('tasks')
        .where('householdId', isEqualTo: householdId)
        .where('assignedTo', isEqualTo: memberName)
        .snapshots();
  }
}
