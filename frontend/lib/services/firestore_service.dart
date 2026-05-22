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
        .limit(5)
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

  Future<void> updateTask({
    required String docId,
    required String title,
    required String category,
    required String assignedTo,
    required String dueLabel,
    required DateTime dueDateTime,
    int difficulty = 3,
    bool isRecurring = false,
    String recurrenceFrequency = 'none',
  }) async {
    await _db.collection('tasks').doc(docId).update({
      'title': title,
      'category': category,
      'assignedTo': assignedTo,
      'dueLabel': dueLabel,
      'dueDateTime': Timestamp.fromDate(dueDateTime),
      'difficulty': difficulty,
      'isRecurring': isRecurring,
      'recurrenceFrequency': recurrenceFrequency,
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
      'ownerId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final userDoc = await _db.collection('users').doc(userId).get();
    final existingId = userDoc.data()?['householdId'] as String?;
    final idsToAdd = [doc.id, if (existingId != null && existingId.isNotEmpty) existingId];

    await _db.collection('users').doc(userId).set({
      'householdId': doc.id,
      'role': 'owner',
      'householdIds': FieldValue.arrayUnion(idsToAdd),
    }, SetOptions(merge: true));

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

    final userDoc = await _db.collection('users').doc(userId).get();
    final existingId = userDoc.data()?['householdId'] as String?;
    final idsToAdd = [householdId, if (existingId != null && existingId.isNotEmpty) existingId];

    await _db.collection('users').doc(userId).set({
      'householdId': householdId,
      'role': 'member',
      'householdIds': FieldValue.arrayUnion(idsToAdd),
    }, SetOptions(merge: true));

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

Future<void> switchHousehold(String uid, String householdId) async {
  await _db.collection('users').doc(uid).update({
    'householdId': householdId,
  });
}

Future<void> leaveHousehold(String uid, String householdId) async {
  final doc = await _db.collection('users').doc(uid).get();
  final data = doc.data() ?? {};
  final rawIds = data['householdIds'];
  final ids = (rawIds is List ? rawIds.cast<String>() : <String>[])
      .where((id) => id != householdId)
      .toList();

  final updates = <String, dynamic>{
    'householdIds': FieldValue.arrayRemove([householdId]),
  };

  final activeId = data['householdId'] as String? ?? '';
  if (activeId == householdId) {
    if (ids.isNotEmpty) {
      updates['householdId'] = ids.first;
    } else {
      updates['householdId'] = FieldValue.delete();
    }
  }

  await _db.collection('users').doc(uid).update(updates);
}

Future<void> kickMember(String uid) async {
  await _db.collection('users').doc(uid).update({
    'householdId': FieldValue.delete(),
    'role': FieldValue.delete(),
  });
}

Stream<QuerySnapshot> getCareNotes(String householdId) {
  return _db
      .collection('careNotes')
      .where('householdId', isEqualTo: householdId)
      .snapshots();
}

Future<void> addCareNote({
  required String householdId,
  required String title,
  required String description,
  required String category,
  required String aboutName,
  required String authorName,
  String authorPhotoUrl = '',
}) async {
  await _db.collection('careNotes').add({
    'householdId': householdId,
    'title': title,
    'description': description,
    'category': category,
    'aboutName': aboutName,
    'authorName': authorName,
    'authorPhotoUrl': authorPhotoUrl,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

Future<void> deleteCareNote(String docId) async {
  await _db.collection('careNotes').doc(docId).delete();
}

Future<String?> autoAssignTask({
  required String householdId,
  required int taskDifficulty,
}) async {
  final membersSnap = await _db
      .collection('users')
      .where('householdId', isEqualTo: householdId)
      .get();

  if (membersSnap.docs.isEmpty) return null;

  final tasksSnap = await _db
      .collection('tasks')
      .where('householdId', isEqualTo: householdId)
      .where('completed', isEqualTo: false)
      .get();

  final taskWeights = <String, double>{};
  final now = DateTime.now();
  for (final doc in tasksSnap.docs) {
    final data = doc.data();
    final name = data['assignedTo'] as String? ?? '';
    if (name.isEmpty) continue;
    final difficulty = (data['difficulty'] as int? ?? 1).clamp(1, 5);
    final dueTs = data['dueDateTime'] as Timestamp?;
    double urgency = 1.0;
    if (dueTs != null) {
      final daysUntilDue = dueTs.toDate().difference(now).inDays;
      if (daysUntilDue <= 0) urgency = 2.0;
      else if (daysUntilDue <= 3) urgency = 1.5;
      else if (daysUntilDue <= 7) urgency = 1.25;
    }
    taskWeights[name] = (taskWeights[name] ?? 0) + difficulty * urgency;
  }

  final isHardTask = taskDifficulty >= 4;

  var candidates = membersSnap.docs.map((doc) {
    final data = doc.data();
    final name = (data['name'] as String?)?.trim();
    final email = data['email'] as String? ?? '';
    final displayName = (name != null && name.isNotEmpty) ? name : email.split('@').first;
    final workload = (data['workload'] as int?) ?? 3;
    return {'name': displayName, 'workload': workload};
  }).toList();

  if (isHardTask) {
    final filtered = candidates.where((m) => (m['workload'] as int) < 4).toList();
    if (filtered.isNotEmpty) candidates = filtered;
  }

  String? bestName;
  double bestScore = double.infinity;

  for (final candidate in candidates) {
    final name = candidate['name'] as String;
    final workload = candidate['workload'] as int;
    final weightedLoad = taskWeights[name] ?? 0.0;
    final score = (weightedLoad + 1) * workload.toDouble();
    if (score < bestScore) {
      bestScore = score;
      bestName = name;
    }
  }

  return bestName;
}

Future<void> saveNotificationToken(String uid, String token) async {
  await _db.collection('users').doc(uid).update({'fcmToken': token});
}

Future<void> renameUserInHouseholds({
  required String uid,
  required String oldName,
  required String newName,
}) async {
  final userDoc = await _db.collection('users').doc(uid).get();
  final data = userDoc.data() ?? {};
  final rawIds = data['householdIds'];
  final activeId = data['householdId'] as String? ?? '';
  final List<String> householdIds = rawIds is List
      ? List<String>.from(rawIds)
      : (activeId.isNotEmpty ? [activeId] : []);

  if (householdIds.isEmpty) return;

  final batch = _db.batch();

  for (final householdId in householdIds) {
    final taskQuery = await _db
        .collection('tasks')
        .where('householdId', isEqualTo: householdId)
        .where('assignedTo', isEqualTo: oldName)
        .get();
    for (final doc in taskQuery.docs) {
      batch.update(doc.reference, {'assignedTo': newName});
    }

    final activityQuery = await _db
        .collection('activities')
        .where('householdId', isEqualTo: householdId)
        .where('actorName', isEqualTo: oldName)
        .get();
    for (final doc in activityQuery.docs) {
      final actData = doc.data();
      final text = (actData['text'] as String? ?? '').replaceFirst(oldName, newName);
      batch.update(doc.reference, {
        'actorName': newName,
        'text': text,
      });
    }
  }

  await batch.commit();
}

}
