
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritesStore {
  FavoritesStore._();

  static final ValueNotifier<List<Map<String, dynamic>>> favorites =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // Get the currently signed-in user's UID.
  static String? get _userId {
    final user = FirebaseAuth.instance.currentUser;

    debugPrint('FAVORITES USER EMAIL: ${user?.email}');
    debugPrint('FAVORITES USER UID: ${user?.uid}');

    return user?.uid;
  }

  // Create a safe Firestore document ID.
  static String _documentId(String name) {
    return base64Url.encode(utf8.encode(name)).replaceAll('=', '');
  }

  // Remove IconData before saving to Firestore.
  static Map<String, dynamic> _toFirestore(
    Map<String, dynamic> place,
  ) {
    final data = Map<String, dynamic>.from(place);
    data.remove('icon');
    return data;
  }

  // Restore a default icon after loading.
  static Map<String, dynamic> _fromFirestore(
    Map<String, dynamic> data,
  ) {
    final result = Map<String, dynamic>.from(data);
    result['icon'] = Icons.place;
    return result;
  }

  // Check whether a place is already saved.
  static bool isFavorite(String name) {
    return favorites.value.any(
      (place) => place['name'] == name,
    );
  }

  // Load favorites belonging to the signed-in user.
  static Future<void> load() async {
    final uid = _userId;

    if (uid == null) {
      debugPrint('FAVORITES LOAD: No signed-in user.');
      favorites.value = [];
      return;
    }

    try {
      debugPrint('FAVORITES LOAD: Starting...');
      debugPrint('FAVORITES LOAD: User UID = $uid');

      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .get();

      favorites.value = snapshot.docs.map((doc) {
        debugPrint('FAVORITES LOAD: Found ${doc.id}');
        return _fromFirestore(doc.data());
      }).toList();

      debugPrint(
        'FAVORITES: Loaded ${favorites.value.length} saved places.',
      );
    } catch (e, stackTrace) {
      debugPrint('FAVORITES LOAD ERROR: $e');
      debugPrint('$stackTrace');
    }
  }

  // Add or remove a favorite.
  static Future<void> toggle(
    Map<String, dynamic> place,
  ) async {
    final uid = _userId;

    if (uid == null) {
      debugPrint('FAVORITES ERROR: Please sign in first.');
      return;
    }

    final name = place['name']?.toString() ?? '';

    if (name.isEmpty) {
      debugPrint('FAVORITES ERROR: Place name is missing.');
      return;
    }

    final updated =
        List<Map<String, dynamic>>.from(favorites.value);

    final index = updated.indexWhere(
      (item) => item['name'] == name,
    );

    if (index >= 0) {
      updated.removeAt(index);
      favorites.value = updated;

      await _deleteFromFirestore(uid, name);
    } else {
      final savedPlace = Map<String, dynamic>.from(place);

      updated.add(savedPlace);
      favorites.value = updated;

      await _saveToFirestore(uid, savedPlace);
    }
  }

  // Save a favorite to Firestore.
  static Future<void> _saveToFirestore(
    String uid,
    Map<String, dynamic> place,
  ) async {
    try {
      final name = place['name'].toString();
      final documentId = _documentId(name);

      debugPrint('FAVORITES SAVE: Starting...');
      debugPrint('FAVORITES SAVE: User UID = $uid');
      debugPrint('FAVORITES SAVE: Place = $name');
      debugPrint('FAVORITES SAVE: Document ID = $documentId');

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(documentId)
          .set({
        ..._toFirestore(place),
        'savedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('FAVORITES: Successfully saved $name');
    } catch (e, stackTrace) {
      debugPrint('FAVORITES SAVE ERROR: $e');
      debugPrint('$stackTrace');
    }
  }

  // Delete a favorite from Firestore.
  static Future<void> _deleteFromFirestore(
    String uid,
    String name,
  ) async {
    try {
      final documentId = _documentId(name);

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(documentId)
          .delete();

      debugPrint('FAVORITES: Successfully removed $name');
    } catch (e, stackTrace) {
      debugPrint('FAVORITES DELETE ERROR: $e');
      debugPrint('$stackTrace');
    }
  }

  // Remove a favorite from the favorites screen.
  static Future<void> remove(String name) async {
    final uid = _userId;

    if (uid == null) {
      debugPrint('FAVORITES REMOVE: No signed-in user.');
      return;
    }

    favorites.value = favorites.value
        .where((place) => place['name'] != name)
        .toList();

    await _deleteFromFirestore(uid, name);
  }

  // Clear favorites when the user signs out.
  static void clear() {
    favorites.value = [];
    debugPrint('FAVORITES: Local list cleared.');
  }
}
