import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:circlehome/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirestoreService(db: fakeFirestore);
  });

  // ─── addTask ─────────────────────────────────────────────────────────────────

  group('addTask', () {
    test('creates a task document with correct fields', () async {
      await service.addTask(
        title: 'Clean kitchen',
        category: 'Cleaning',
        assignedTo: 'Alice',
        householdId: 'hh1',
        dueLabel: '06/01/2027',
        dueDateTime: DateTime(2027, 6, 1),
        difficulty: 3,
        isRecurring: false,
        recurrenceFrequency: 'none',
      );

      final snap = await fakeFirestore.collection('tasks').get();
      expect(snap.docs.length, 1);

      final data = snap.docs.first.data();
      expect(data['title'], 'Clean kitchen');
      expect(data['category'], 'Cleaning');
      expect(data['assignedTo'], 'Alice');
      expect(data['householdId'], 'hh1');
      expect(data['completed'], false);
      expect(data['difficulty'], 3);
      expect(data['isRecurring'], false);
    });

    test('stores correct difficulty value', () async {
      await service.addTask(
        title: 'Hard task',
        category: 'Other',
        assignedTo: 'Bob',
        householdId: 'hh1',
        dueLabel: '06/01/2027',
        dueDateTime: DateTime(2027, 6, 1),
        difficulty: 5,
      );

      final snap = await fakeFirestore.collection('tasks').get();
      expect(snap.docs.first.data()['difficulty'], 5);
    });

    test('stores recurring task with frequency', () async {
      await service.addTask(
        title: 'Weekly chore',
        category: 'Cleaning',
        assignedTo: 'Alice',
        householdId: 'hh1',
        dueLabel: '06/01/2027',
        dueDateTime: DateTime(2027, 6, 1),
        isRecurring: true,
        recurrenceFrequency: 'Weekly',
      );

      final data = (await fakeFirestore.collection('tasks').get()).docs.first.data();
      expect(data['isRecurring'], true);
      expect(data['recurrenceFrequency'], 'Weekly');
    });
  });

  // ─── completeTask ─────────────────────────────────────────────────────────────

  group('completeTask', () {
    test('marks task as completed', () async {
      final ref = await fakeFirestore.collection('tasks').add({
        'title': 'Do laundry',
        'householdId': 'hh1',
        'completed': false,
      });

      await service.completeTask(
        docId: ref.id,
        title: 'Do laundry',
        userName: 'Alice',
        householdId: 'hh1',
      );

      final task = await ref.get();
      expect(task.data()!['completed'], true);
    });

    test('creates an activity entry', () async {
      final ref = await fakeFirestore.collection('tasks').add({
        'title': 'Vacuum floors',
        'householdId': 'hh1',
        'completed': false,
      });

      await service.completeTask(
        docId: ref.id,
        title: 'Vacuum floors',
        userName: 'Bob',
        householdId: 'hh1',
      );

      final activities = await fakeFirestore.collection('activities').get();
      expect(activities.docs.length, 1);
      final actData = activities.docs.first.data();
      expect(actData['actorName'], 'Bob');
      expect(actData['householdId'], 'hh1');
      expect((actData['text'] as String).contains('Bob'), true);
      expect((actData['text'] as String).contains('Vacuum floors'), true);
    });
  });

  // ─── uncompleteTask ───────────────────────────────────────────────────────────

  group('uncompleteTask', () {
    test('sets completed back to false', () async {
      final ref = await fakeFirestore.collection('tasks').add({
        'title': 'Take out trash',
        'completed': true,
      });

      await service.uncompleteTask(ref.id);

      final doc = await ref.get();
      expect(doc.data()!['completed'], false);
    });
  });

  // ─── deleteTask ───────────────────────────────────────────────────────────────

  group('deleteTask', () {
    test('removes the task document', () async {
      final ref = await fakeFirestore.collection('tasks').add({'title': 'Temp task'});
      await service.deleteTask(ref.id);

      final doc = await ref.get();
      expect(doc.exists, false);
    });

    test('does not affect other tasks', () async {
      final ref1 = await fakeFirestore.collection('tasks').add({'title': 'Task 1'});
      await fakeFirestore.collection('tasks').add({'title': 'Task 2'});

      await service.deleteTask(ref1.id);

      final remaining = await fakeFirestore.collection('tasks').get();
      expect(remaining.docs.length, 1);
      expect(remaining.docs.first.data()['title'], 'Task 2');
    });
  });

  // ─── addCareNote ──────────────────────────────────────────────────────────────

  group('addCareNote', () {
    test('creates a care note with correct fields', () async {
      await service.addCareNote(
        householdId: 'hh1',
        title: 'Gave medication',
        description: '10mg ibuprofen',
        category: 'Medication',
        aboutName: 'Grandma',
        authorName: 'Alice',
      );

      final snap = await fakeFirestore.collection('careNotes').get();
      expect(snap.docs.length, 1);

      final data = snap.docs.first.data();
      expect(data['title'], 'Gave medication');
      expect(data['category'], 'Medication');
      expect(data['aboutName'], 'Grandma');
      expect(data['authorName'], 'Alice');
      expect(data['householdId'], 'hh1');
    });
  });

  // ─── deleteCareNote ───────────────────────────────────────────────────────────

  group('deleteCareNote', () {
    test('removes the care note document', () async {
      final ref = await fakeFirestore.collection('careNotes').add({'title': 'Test note'});
      await service.deleteCareNote(ref.id);

      final doc = await ref.get();
      expect(doc.exists, false);
    });
  });

  // ─── joinHouseholdByCode ──────────────────────────────────────────────────────

  group('joinHouseholdByCode', () {
    test('returns false for an invalid code', () async {
      final result = await service.joinHouseholdByCode(
        code: 'BADCODE',
        userId: 'user1',
      );
      expect(result, false);
    });

    test('returns true and sets role to member for a valid code', () async {
      await fakeFirestore.collection('households').add({
        'name': 'Test House',
        'code': 'ABC123',
      });
      await fakeFirestore.collection('users').doc('user1').set({
        'email': 'user@example.com',
      });

      final result = await service.joinHouseholdByCode(
        code: 'ABC123',
        userId: 'user1',
      );

      expect(result, true);
      final userDoc = await fakeFirestore.collection('users').doc('user1').get();
      expect(userDoc.data()!['role'], 'member');
    });

    test('adds householdId to user householdIds list', () async {
      final householdRef = await fakeFirestore.collection('households').add({
        'name': 'My House',
        'code': 'XYZ999',
      });
      await fakeFirestore.collection('users').doc('user2').set({
        'email': 'user2@example.com',
        'householdId': 'old-hh',
      });

      await service.joinHouseholdByCode(code: 'XYZ999', userId: 'user2');

      final userDoc = await fakeFirestore.collection('users').doc('user2').get();
      expect(userDoc.data()!['householdId'], householdRef.id);
    });
  });

  // ─── getCareNotes ─────────────────────────────────────────────────────────────

  group('getCareNotes', () {
    test('returns only notes for the given household', () async {
      await fakeFirestore.collection('careNotes').add({
        'householdId': 'hh1',
        'title': 'Note for hh1',
      });
      await fakeFirestore.collection('careNotes').add({
        'householdId': 'hh2',
        'title': 'Note for hh2',
      });

      final snap = await service.getCareNotes('hh1').first;
      expect(snap.docs.length, 1);
      expect((snap.docs.first.data() as Map)['title'], 'Note for hh1');
    });

    test('returns empty when household has no notes', () async {
      final snap = await service.getCareNotes('empty-hh').first;
      expect(snap.docs.length, 0);
    });
  });

  // ─── getTasks ─────────────────────────────────────────────────────────────────

  group('getTasks', () {
    test('returns only incomplete tasks for the household', () async {
      await fakeFirestore.collection('tasks').add({
        'householdId': 'hh1',
        'title': 'Pending task',
        'completed': false,
      });
      await fakeFirestore.collection('tasks').add({
        'householdId': 'hh1',
        'title': 'Done task',
        'completed': true,
      });

      final snap = await service.getTasks('hh1').first;
      expect(snap.docs.length, 1);
      expect((snap.docs.first.data() as Map)['title'], 'Pending task');
    });
  });

  // ─── autoAssignTask ───────────────────────────────────────────────────────────

  group('autoAssignTask', () {
    test('returns null when household has no members', () async {
      final result = await service.autoAssignTask(
        householdId: 'empty-hh',
        taskDifficulty: 3,
      );
      expect(result, null);
    });

    test('assigns to the member with the lower task load', () async {
      await fakeFirestore.collection('users').add({
        'name': 'Alice',
        'householdId': 'hh1',
        'workload': 3,
      });
      await fakeFirestore.collection('users').add({
        'name': 'Bob',
        'householdId': 'hh1',
        'workload': 3,
      });

      // Give Alice a heavy existing task
      await fakeFirestore.collection('tasks').add({
        'householdId': 'hh1',
        'assignedTo': 'Alice',
        'difficulty': 5,
        'completed': false,
        'dueDateTime': Timestamp.fromDate(DateTime.now().add(const Duration(days: 10))),
      });

      final result = await service.autoAssignTask(
        householdId: 'hh1',
        taskDifficulty: 2,
      );
      expect(result, 'Bob');
    });

    test('assigns to single available member', () async {
      await fakeFirestore.collection('users').add({
        'name': 'Alice',
        'householdId': 'hh1',
        'workload': 3,
      });

      final result = await service.autoAssignTask(
        householdId: 'hh1',
        taskDifficulty: 2,
      );
      expect(result, 'Alice');
    });

    test('skips high-workload members for hard tasks', () async {
      await fakeFirestore.collection('users').add({
        'name': 'Overloaded',
        'householdId': 'hh1',
        'workload': 5,
      });
      await fakeFirestore.collection('users').add({
        'name': 'Available',
        'householdId': 'hh1',
        'workload': 2,
      });

      final result = await service.autoAssignTask(
        householdId: 'hh1',
        taskDifficulty: 5,
      );
      expect(result, 'Available');
    });

    test('falls back to all members if everyone is high-workload on hard task', () async {
      await fakeFirestore.collection('users').add({
        'name': 'Alice',
        'householdId': 'hh1',
        'workload': 5,
      });
      await fakeFirestore.collection('users').add({
        'name': 'Bob',
        'householdId': 'hh1',
        'workload': 5,
      });

      final result = await service.autoAssignTask(
        householdId: 'hh1',
        taskDifficulty: 5,
      );
      expect(result, isNotNull);
    });

    test('weights overdue tasks more heavily', () async {
      await fakeFirestore.collection('users').add({
        'name': 'Alice',
        'householdId': 'hh1',
        'workload': 3,
      });
      await fakeFirestore.collection('users').add({
        'name': 'Bob',
        'householdId': 'hh1',
        'workload': 3,
      });

      // Give Alice an overdue task (urgency multiplier 2.0)
      await fakeFirestore.collection('tasks').add({
        'householdId': 'hh1',
        'assignedTo': 'Alice',
        'difficulty': 3,
        'completed': false,
        'dueDateTime': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
      });

      final result = await service.autoAssignTask(
        householdId: 'hh1',
        taskDifficulty: 2,
      );
      expect(result, 'Bob');
    });
  });
}
