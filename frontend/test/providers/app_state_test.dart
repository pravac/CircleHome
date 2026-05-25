import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:circlehome/providers/app_state.dart';
import 'package:circlehome/services/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = FirestoreService(db: fakeFirestore);
  });

  group('AppState.initialize', () {
    test('clears data when initialized with null user', () async {
      final appState = AppState(firestoreService: service);
      await appState.initialize(null);

      expect(appState.firebaseUser, isNull);
      expect(appState.userData, isNull);
      expect(appState.householdData, isNull);
      expect(appState.isLoading, false);
    });

    test('loads user data when initialized with a valid user', () async {
      final mockUser = MockUser(uid: 'user1', email: 'alice@example.com');

      await fakeFirestore.collection('users').doc('user1').set({
        'name': 'Alice',
        'householdId': 'hh1',
      });

      final appState = AppState(firestoreService: service);
      await appState.initialize(mockUser);

      expect(appState.userData, isNotNull);
      expect(appState.userData!['name'], 'Alice');
      expect(appState.isLoading, false);
    });

    test('loads household data when user belongs to a household', () async {
      final mockUser = MockUser(uid: 'user1', email: 'alice@example.com');

      await fakeFirestore.collection('users').doc('user1').set({
        'name': 'Alice',
        'householdId': 'hh1',
      });
      await fakeFirestore.collection('households').doc('hh1').set({
        'name': 'The Smith House',
        'code': 'ABC123',
      });

      final appState = AppState(firestoreService: service);
      await appState.initialize(mockUser);

      expect(appState.householdData, isNotNull);
      expect(appState.householdData!['name'], 'The Smith House');
    });

    test('leaves householdData null when user has no householdId', () async {
      final mockUser = MockUser(uid: 'user2', email: 'bob@example.com');

      await fakeFirestore.collection('users').doc('user2').set({
        'name': 'Bob',
      });

      final appState = AppState(firestoreService: service);
      await appState.initialize(mockUser);

      expect(appState.userData!['name'], 'Bob');
      expect(appState.householdData, isNull);
    });

    test('uid and email getters return correct values', () async {
      final mockUser = MockUser(uid: 'user1', email: 'alice@example.com');

      await fakeFirestore.collection('users').doc('user1').set({
        'name': 'Alice',
        'householdId': '',
      });

      final appState = AppState(firestoreService: service);
      await appState.initialize(mockUser);

      expect(appState.uid, 'user1');
      expect(appState.email, 'alice@example.com');
    });
  });

  group('AppState.joinHouseholdByCode', () {
    test('returns false and sets error for invalid code', () async {
      final mockUser = MockUser(uid: 'user1', email: 'alice@example.com');

      await fakeFirestore.collection('users').doc('user1').set({
        'name': 'Alice',
        'householdId': '',
      });

      final appState = AppState(firestoreService: service);
      await appState.initialize(mockUser);

      final result = await appState.joinHouseholdByCode('BADCODE');

      expect(result, false);
      expect(appState.errorMessage, 'Invalid household code.');
      expect(appState.isLoading, false);
    });

    test('returns true and updates state for valid code', () async {
      final mockUser = MockUser(uid: 'user1', email: 'alice@example.com');

      await fakeFirestore.collection('users').doc('user1').set({
        'name': 'Alice',
        'householdId': '',
      });
      await fakeFirestore.collection('households').add({
        'name': 'Cool House',
        'code': 'VALID1',
      });

      final appState = AppState(firestoreService: service);
      await appState.initialize(mockUser);

      final result = await appState.joinHouseholdByCode('VALID1');

      expect(result, true);
      expect(appState.isLoading, false);
      expect(appState.errorMessage, isNull);
    });

    test('returns false when uid is null', () async {
      final appState = AppState(firestoreService: service);
      // No user initialized — uid is null

      final result = await appState.joinHouseholdByCode('ABC123');
      expect(result, false);
    });
  });

  group('AppState.taskStream', () {
    test('returns null when no household is set', () async {
      final appState = AppState(firestoreService: service);
      expect(appState.taskStream(), isNull);
    });

    test('returns a stream when household is loaded', () async {
      final mockUser = MockUser(uid: 'user1', email: 'alice@example.com');

      await fakeFirestore.collection('users').doc('user1').set({
        'name': 'Alice',
        'householdId': 'hh1',
      });
      await fakeFirestore.collection('households').doc('hh1').set({
        'name': 'Test House',
      });

      final appState = AppState(firestoreService: service);
      await appState.initialize(mockUser);

      expect(appState.taskStream(), isNotNull);
    });
  });
}
