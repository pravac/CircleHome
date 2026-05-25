import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:circlehome/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('currentUser is null when not signed in', () {
      final auth = MockFirebaseAuth();
      final service = AuthService(auth: auth);
      expect(service.currentUser, isNull);
    });

    test('currentUser is set after sign in', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'abc123', email: 'user@example.com'),
      );
      final service = AuthService(auth: auth);

      await service.signIn(email: 'user@example.com', password: 'password');
      expect(service.currentUser, isNotNull);
      expect(service.currentUser!.email, 'user@example.com');
    });

    test('signUp creates a new user', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'newuser', email: 'new@example.com'),
      );
      final service = AuthService(auth: auth);

      final credential = await service.signUp(
        email: 'new@example.com',
        password: 'password123',
      );
      expect(credential.user, isNotNull);
      expect(credential.user!.email, 'new@example.com');
    });

    test('signOut clears the current user', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'abc123', email: 'user@example.com'),
      );
      final service = AuthService(auth: auth);

      expect(service.currentUser, isNotNull);
      await service.signOut();
      expect(service.currentUser, isNull);
    });

    test('authStateChanges emits null when signed out', () async {
      final auth = MockFirebaseAuth();
      final service = AuthService(auth: auth);

      expect(service.authStateChanges, emits(isNull));
    });

    test('authStateChanges emits user after sign in', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'abc123', email: 'user@example.com'),
      );
      final service = AuthService(auth: auth);

      final userFuture = service.authStateChanges.where((u) => u != null).first;
      await service.signIn(email: 'user@example.com', password: 'pass');
      final user = await userFuture;

      expect(user, isNotNull);
      expect(user!.email, 'user@example.com');
    });
  });
}
