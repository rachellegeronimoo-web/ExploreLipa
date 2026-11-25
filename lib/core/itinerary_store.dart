
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ItineraryStore {
  ItineraryStore._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static String? get _userId =>
      FirebaseAuth.instance.currentUser?.uid;

  // =========================================================
  // LOCAL DATA
  // =========================================================

  static final ValueNotifier<List<Map<String, dynamic>>> itinerary =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static final ValueNotifier<DateTime> tripStartDate =
      ValueNotifier<DateTime>(DateTime.now());

  static final ValueNotifier<int> tripDays =
      ValueNotifier<int>(1);

  static final ValueNotifier<List<Map<String, dynamic>>> expenses =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static final ValueNotifier<List<Map<String, dynamic>>> checklist =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  // Compatibility with older Planner code.
  static ValueNotifier<int> get dayCount => tripDays;

  // =========================================================
  // HELPERS
  // =========================================================

  static DocumentReference<Map<String, dynamic>> _userDocument(
      String uid) {
    return _firestore.collection('users').doc(uid);
  }

  static String _placeDocumentId(String name) {
    return Uri.encodeComponent(name);
  }

  static bool contains(String name) {
    return itinerary.value.any(
      (place) => place['name'] == name,
    );
  }

  // =========================================================
  // LOAD ALL TRIP DATA
  // =========================================================

  static Future<void> loadTripPlan() async {
    final uid = _userId;

    if (uid == null) {
      itinerary.value = [];
      expenses.value = [];
      checklist.value = [];
      tripStartDate.value = DateTime.now();
      tripDays.value = 1;
      return;
    }

    try {
      final userRef = _userDocument(uid);

      // Load destinations.
      final placesSnapshot =
          await userRef.collection('itinerary').get();

      itinerary.value = placesSnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data.remove('addedAt');
        return data;
      }).toList();

      // Load trip settings.
      final planSnapshot = await userRef
          .collection('tripPlan')
          .doc('current')
          .get();

      if (planSnapshot.exists) {
        final data = planSnapshot.data() ?? {};

        final savedDate = data['tripStartDate'];

        if (savedDate is Timestamp) {
          tripStartDate.value = savedDate.toDate();
        }

        final savedDays = data['tripDays'];

        if (savedDays is num &&
            savedDays.toInt() >= 1 &&
            savedDays.toInt() <= 14) {
          tripDays.value = savedDays.toInt();
        }
      }

      // Load expenses.
      final expenseSnapshot =
          await userRef.collection('tripBudget').get();

      expenses.value = expenseSnapshot.docs.map((doc) {
        return {
          ...doc.data(),
          'id': doc.id,
        };
      }).toList();

      // Load checklist.
      final checklistSnapshot =
          await userRef.collection('tripChecklist').get();

      checklist.value = checklistSnapshot.docs.map((doc) {
        return {
          ...doc.data(),
          'id': doc.id,
        };
      }).toList();

      debugPrint(
        'TRIP PLAN: Loaded ${itinerary.value.length} destinations, '
        '${expenses.value.length} expenses, '
        'and ${checklist.value.length} checklist items.',
      );
    } catch (e) {
      debugPrint('TRIP PLAN LOAD ERROR: $e');
    }
  }

  static Future<void> load() async {
    await loadTripPlan();
  }

  // =========================================================
  // SAVE TRIP SETTINGS
  // =========================================================

  static Future<bool> saveTripPlan({
    required DateTime startDate,
    required int days,
  }) async {
    final uid = _userId;

    if (uid == null || days < 1 || days > 14) {
      return false;
    }

    try {
      await _userDocument(uid)
          .collection('tripPlan')
          .doc('current')
          .set({
        'tripStartDate': Timestamp.fromDate(startDate),
        'tripDays': days,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tripStartDate.value = startDate;
      tripDays.value = days;

      debugPrint('TRIP PLAN: Settings saved.');
      return true;
    } catch (e) {
      debugPrint('TRIP PLAN SAVE ERROR: $e');
      return false;
    }
  }

  // Compatibility with previous Planner code.
  static Future<bool> saveTripDetails({
    required DateTime startDate,
    required int days,
  }) {
    return saveTripPlan(
      startDate: startDate,
      days: days,
    );
  }

  // =========================================================
  // ADD DESTINATION
  // =========================================================

  static Future<bool> add(
    Map<String, dynamic> place,
  ) async {
    final uid = _userId;

    if (uid == null) return false;

    final name = place['name']?.toString() ?? '';

    if (name.isEmpty || contains(name)) {
      return false;
    }

    final savedPlace = Map<String, dynamic>.from(place);

    savedPlace.remove('icon');
    savedPlace['day'] ??= 1;
    savedPlace['visitTime'] ??= '09:00 AM';

    itinerary.value = [
      ...itinerary.value,
      savedPlace,
    ];

    try {
      await _userDocument(uid)
          .collection('itinerary')
          .doc(_placeDocumentId(name))
          .set({
        ...savedPlace,
        'addedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('ITINERARY: Added $name');
      return true;
    } catch (e) {
      itinerary.value = itinerary.value
          .where((item) => item['name'] != name)
          .toList();

      debugPrint('ITINERARY ADD ERROR: $e');
      return false;
    }
  }

  // =========================================================
  // UPDATE DESTINATION SCHEDULE
  // =========================================================

  static Future<bool> updateSchedule({
    required String name,
    required int day,
    required String visitTime,
  }) async {
    final uid = _userId;

    if (uid == null || day < 1 || day > 14) {
      return false;
    }

    final index = itinerary.value.indexWhere(
      (place) => place['name'] == name,
    );

    if (index == -1) return false;

    final updatedPlace =
        Map<String, dynamic>.from(itinerary.value[index]);

    updatedPlace['day'] = day;
    updatedPlace['visitTime'] = visitTime;

    final updatedList =
        List<Map<String, dynamic>>.from(itinerary.value);

    updatedList[index] = updatedPlace;
    itinerary.value = updatedList;

    try {
      await _userDocument(uid)
          .collection('itinerary')
          .doc(_placeDocumentId(name))
          .set({
        'day': day,
        'visitTime': visitTime,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('SCHEDULE UPDATE ERROR: $e');
      await loadTripPlan();
      return false;
    }
  }

  // =========================================================
  // REMOVE DESTINATION
  // =========================================================

  static Future<void> remove(String name) async {
    final uid = _userId;

    if (uid == null) return;

    final oldList =
        List<Map<String, dynamic>>.from(itinerary.value);

    itinerary.value = itinerary.value
        .where((place) => place['name'] != name)
        .toList();

    try {
      await _userDocument(uid)
          .collection('itinerary')
          .doc(_placeDocumentId(name))
          .delete();

      debugPrint('ITINERARY: Removed $name');
    } catch (e) {
      itinerary.value = oldList;
      debugPrint('ITINERARY DELETE ERROR: $e');
    }
  }

  // =========================================================
  // BUDGET - ADD EXPENSE
  // =========================================================

  static Future<bool> addExpense({
    required String title,
    required String category,
    required double amount,
    String notes = '',
  }) async {
    final uid = _userId;

    if (uid == null ||
        title.trim().isEmpty ||
        amount <= 0) {
      return false;
    }

    try {
      final doc = _userDocument(uid)
          .collection('tripBudget')
          .doc();

      final expense = {
        'title': title.trim(),
        'category': category,
        'amount': amount,
        'notes': notes.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await doc.set(expense);

      expenses.value = [
        ...expenses.value,
        {
          'title': title.trim(),
          'category': category,
          'amount': amount,
          'notes': notes.trim(),
          'id': doc.id,
        },
      ];

      return true;
    } catch (e) {
      debugPrint('EXPENSE ADD ERROR: $e');
      return false;
    }
  }

  // =========================================================
  // BUDGET - UPDATE EXPENSE
  // =========================================================

  static Future<bool> updateExpense({
    required String id,
    required String title,
    required String category,
    required double amount,
    String notes = '',
  }) async {
    final uid = _userId;

    if (uid == null ||
        title.trim().isEmpty ||
        amount <= 0) {
      return false;
    }

    try {
      await _userDocument(uid)
          .collection('tripBudget')
          .doc(id)
          .update({
        'title': title.trim(),
        'category': category,
        'amount': amount,
        'notes': notes.trim(),
      });

      expenses.value = expenses.value.map((item) {
        if (item['id'] != id) return item;

        return {
          ...item,
          'title': title.trim(),
          'category': category,
          'amount': amount,
          'notes': notes.trim(),
        };
      }).toList();

      return true;
    } catch (e) {
      debugPrint('EXPENSE UPDATE ERROR: $e');
      return false;
    }
  }

  // =========================================================
  // BUDGET - DELETE EXPENSE
  // =========================================================

  static Future<bool> removeExpense(String id) async {
    final uid = _userId;

    if (uid == null) return false;

    try {
      await _userDocument(uid)
          .collection('tripBudget')
          .doc(id)
          .delete();

      expenses.value = expenses.value
          .where((item) => item['id'] != id)
          .toList();

      return true;
    } catch (e) {
      debugPrint('EXPENSE DELETE ERROR: $e');
      return false;
    }
  }

  // Total expenses.
  static double get totalBudget {
    return expenses.value.fold<double>(
      0,
      (total, item) {
        final amount = item['amount'];

        if (amount is num) {
          return total + amount.toDouble();
        }

        return total;
      },
    );
  }

  // =========================================================
  // CHECKLIST - ADD ITEM
  // =========================================================

  static Future<bool> addChecklistItem(String title) async {
    final uid = _userId;

    if (uid == null || title.trim().isEmpty) {
      return false;
    }

    try {
      final doc = _userDocument(uid)
          .collection('tripChecklist')
          .doc();

      await doc.set({
        'title': title.trim(),
        'isDone': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      checklist.value = [
        ...checklist.value,
        {
          'title': title.trim(),
          'isDone': false,
          'id': doc.id,
        },
      ];

      return true;
    } catch (e) {
      debugPrint('CHECKLIST ADD ERROR: $e');
      return false;
    }
  }

  // =========================================================
  // CHECKLIST - TOGGLE ITEM
  // =========================================================

  static Future<bool> toggleChecklistItem({
    required String id,
    required bool isDone,
  }) async {
    final uid = _userId;

    if (uid == null) return false;

    try {
      await _userDocument(uid)
          .collection('tripChecklist')
          .doc(id)
          .update({
        'isDone': isDone,
      });

      checklist.value = checklist.value.map((item) {
        if (item['id'] != id) return item;

        return {
          ...item,
          'isDone': isDone,
        };
      }).toList();

      return true;
    } catch (e) {
      debugPrint('CHECKLIST UPDATE ERROR: $e');
      return false;
    }
  }

  // =========================================================
  // CHECKLIST - DELETE ITEM
  // =========================================================

  static Future<bool> removeChecklistItem(String id) async {
    final uid = _userId;

    if (uid == null) return false;

    try {
      await _userDocument(uid)
          .collection('tripChecklist')
          .doc(id)
          .delete();

      checklist.value = checklist.value
          .where((item) => item['id'] != id)
          .toList();

      return true;
    } catch (e) {
      debugPrint('CHECKLIST DELETE ERROR: $e');
      return false;
    }
  }

  // =========================================================
  // CHECKLIST PROGRESS
  // =========================================================

  static int get completedChecklistCount {
    return checklist.value.where(
      (item) => item['isDone'] == true,
    ).length;
  }

  static int get totalChecklistCount {
    return checklist.value.length;
  }

  // =========================================================
  // CLEAR LOCAL DATA
  // =========================================================

  static void clear() {
    itinerary.value = [];
    expenses.value = [];
    checklist.value = [];
    tripStartDate.value = DateTime.now();
    tripDays.value = 1;
  }
}
