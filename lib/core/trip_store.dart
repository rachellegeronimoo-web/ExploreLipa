
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class TripStore {
  TripStore._();

  static final ValueNotifier<List<Map<String, dynamic>>> trips =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static String? get _userId =>
      FirebaseAuth.instance.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>>? get _tripCollection {
    final uid = _userId;
    if (uid == null) return null;

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('trips');
  }

  static Future<void> load() async {
    final collection = _tripCollection;

    if (collection == null) {
      trips.value = [];
      return;
    }

    try {
      final snapshot = await collection
          .orderBy('createdAt', descending: true)
          .get();

      trips.value = snapshot.docs.map((doc) {
        return {
          ...doc.data(),
          'id': doc.id,
        };
      }).toList();

      debugPrint('TRIPS: Loaded ${trips.value.length} trips.');
    } catch (e) {
      debugPrint('TRIPS LOAD ERROR: $e');
    }
  }

  static Future<String?> createTrip({
    required String name,
    required DateTime startDate,
    required int numberOfDays,
    required int travelers,
  }) async {
    final collection = _tripCollection;

    if (collection == null) return null;

    try {
      final days = List.generate(numberOfDays, (index) {
        return {
          'dayNumber': index + 1,
          'items': <Map<String, dynamic>>[],
        };
      });

      final doc = collection.doc();

      final trip = {
        'name': name.trim(),
        'startDate': DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        ).toIso8601String(),
        'numberOfDays': numberOfDays,
        'travelers': travelers,
        'days': days,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await doc.set(trip);

      trips.value = [
        {
          ...trip,
          'id': doc.id,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        ...trips.value,
      ];

      debugPrint('TRIPS: Created ${doc.id}');
      return doc.id;
    } catch (e) {
      debugPrint('TRIP CREATE ERROR: $e');
      return null;
    }
  }

  static List<Map<String, dynamic>> _getDays(
    Map<String, dynamic> trip,
  ) {
    final rawDays = trip['days'] as List? ?? [];

    return rawDays.map((day) {
      return Map<String, dynamic>.from(day as Map);
    }).toList();
  }

  static Future<void> _saveDays(
    String tripId,
    List<Map<String, dynamic>> days,
  ) async {
    final collection = _tripCollection;
    if (collection == null) return;

    await collection.doc(tripId).update({
      'days': days,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    trips.value = trips.value.map((trip) {
      if (trip['id'] != tripId) return trip;

      return {
        ...trip,
        'days': days,
      };
    }).toList();
  }

  static Future<bool> addDestination({
    required String tripId,
    required int dayNumber,
    required Map<String, dynamic> place,
  }) async {
    final trip = trips.value.firstWhere(
      (item) => item['id'] == tripId,
      orElse: () => {},
    );

    if (trip.isEmpty) return false;

    final name = place['name']?.toString() ?? '';

    if (name.isEmpty) return false;

    final days = _getDays(trip);

    for (final day in days) {
      final items = (day['items'] as List? ?? []);
      if (items.any((item) => item['name'] == name)) {
        return false;
      }
    }

    final dayIndex = days.indexWhere(
      (day) => day['dayNumber'] == dayNumber,
    );

    if (dayIndex == -1) return false;

    final savedPlace = <String, dynamic>{
      'name': name,
      'category': place['category']?.toString() ?? '',
      'description': place['description']?.toString() ?? '',
      'location': place['location']?.toString() ?? 'Lipa City, Batangas',
      'image': place['image']?.toString() ?? '',
      'visitTime': '09:00 AM',
    };

    final items = List<Map<String, dynamic>>.from(
      days[dayIndex]['items'] as List? ?? [],
    );

    items.add(savedPlace);
    days[dayIndex]['items'] = items;

    try {
      await _saveDays(tripId, days);
      return true;
    } catch (e) {
      debugPrint('ADD DESTINATION ERROR: $e');
      return false;
    }
  }

  static Future<void> removeDestination({
    required String tripId,
    required int dayNumber,
    required String placeName,
  }) async {
    final trip = trips.value.firstWhere(
      (item) => item['id'] == tripId,
      orElse: () => {},
    );

    if (trip.isEmpty) return;

    final days = _getDays(trip);
    final dayIndex = days.indexWhere(
      (day) => day['dayNumber'] == dayNumber,
    );

    if (dayIndex == -1) return;

    final items = List<Map<String, dynamic>>.from(
      days[dayIndex]['items'] as List? ?? [],
    );

    items.removeWhere((item) => item['name'] == placeName);
    days[dayIndex]['items'] = items;

    try {
      await _saveDays(tripId, days);
    } catch (e) {
      debugPrint('REMOVE DESTINATION ERROR: $e');
    }
  }

  static Future<void> updateVisitTime({
    required String tripId,
    required int dayNumber,
    required String placeName,
    required String visitTime,
  }) async {
    final trip = trips.value.firstWhere(
      (item) => item['id'] == tripId,
      orElse: () => {},
    );

    if (trip.isEmpty) return;

    final days = _getDays(trip);
    final dayIndex = days.indexWhere(
      (day) => day['dayNumber'] == dayNumber,
    );

    if (dayIndex == -1) return;

    final items = List<Map<String, dynamic>>.from(
      days[dayIndex]['items'] as List? ?? [],
    );

    final placeIndex = items.indexWhere(
      (item) => item['name'] == placeName,
    );

    if (placeIndex == -1) return;

    items[placeIndex]['visitTime'] = visitTime;
    days[dayIndex]['items'] = items;

    try {
      await _saveDays(tripId, days);
    } catch (e) {
      debugPrint('UPDATE VISIT TIME ERROR: $e');
    }
  }

  static Future<void> reorderDestinations({
    required String tripId,
    required int dayNumber,
    required int oldIndex,
    required int newIndex,
  }) async {
    final trip = trips.value.firstWhere(
      (item) => item['id'] == tripId,
      orElse: () => {},
    );

    if (trip.isEmpty) return;

    final days = _getDays(trip);
    final dayIndex = days.indexWhere(
      (day) => day['dayNumber'] == dayNumber,
    );

    if (dayIndex == -1) return;

    final items = List<Map<String, dynamic>>.from(
      days[dayIndex]['items'] as List? ?? [],
    );

    if (newIndex > oldIndex) newIndex--;

    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    days[dayIndex]['items'] = items;

    try {
      await _saveDays(tripId, days);
    } catch (e) {
      debugPrint('REORDER DESTINATIONS ERROR: $e');
    }
  }

  static Future<void> deleteTrip(String tripId) async {
    final collection = _tripCollection;
    if (collection == null) return;

    try {
      await collection.doc(tripId).delete();

      trips.value = trips.value
          .where((trip) => trip['id'] != tripId)
          .toList();
    } catch (e) {
      debugPrint('DELETE TRIP ERROR: $e');
    }
  }

  static void clear() {
    trips.value = [];
  }
}
