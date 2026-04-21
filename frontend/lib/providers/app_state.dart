import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class AppState extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  User? firebaseUser;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? householdData;

  bool isLoading = false;
  String? errorMessage;

  String? get uid => firebaseUser?.uid;
  String? get email => firebaseUser?.email;
  String? get householdId => userData?['householdId'] as String?;

  Future<void> initialize(User? user) async {
    firebaseUser = user;

    if (user == null) {
      userData = null;
      householdData = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userDoc = await _firestoreService.getUserDocument(user.uid);
      userData = userDoc.data();

      final hid = userData?['householdId'] as String?;
      if (hid != null && hid.isNotEmpty) {
        householdData = await _firestoreService.getHousehold(hid);
      } else {
        householdData = null;
      }
    } catch (e) {
      errorMessage = 'Failed to load app state.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshHousehold() async {
    final hid = householdId;
    if (hid == null || hid.isEmpty) return;

    householdData = await _firestoreService.getHousehold(hid);
    notifyListeners();
  }

  Future<void> createHousehold({
    required String name,
  }) async {
    if (uid == null) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _firestoreService.createHousehold(
        name: name,
        userId: uid!,
      );

      await initialize(firebaseUser);
    } catch (e) {
      errorMessage = 'Failed to create household.';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinHouseholdByCode(String code) async {
    if (uid == null) return false;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final success = await _firestoreService.joinHouseholdByCode(
        code: code,
        userId: uid!,
      );

      if (success) {
        await initialize(firebaseUser);
      } else {
        isLoading = false;
        errorMessage = 'Invalid household code.';
        notifyListeners();
      }

      return success;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Failed to join household.';
      notifyListeners();
      return false;
    }
  }

  Stream<QuerySnapshot>? taskStream() {
    final hid = householdId;
    if (hid == null || hid.isEmpty) return null;
    return _firestoreService.getTasks(hid);
  }

  Stream<QuerySnapshot>? activityStream() {
    final hid = householdId;
    if (hid == null || hid.isEmpty) return null;
    return _firestoreService.getActivities(hid);
  }
}