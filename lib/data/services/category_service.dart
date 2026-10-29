import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please login first.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');

  static const List<String> defaultCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
  ];

  // Read categories for the logged-in user
  Stream<QuerySnapshot<Map<String, dynamic>>> getCategories() {
    return _categories
        .where('userId', isEqualTo: _userId)
        .snapshots();
  }

  // Create missing default categories
  Future<void> initializeCategories() async {
    final userId = _userId;

    final existing = await _categories
        .where('userId', isEqualTo: userId)
        .get();

    final existingNames = existing.docs
        .map((doc) => doc.data()['name'])
        .whereType<String>()
        .toSet();

    final batch = _firestore.batch();
    int addedCount = 0;

    for (final name in defaultCategories) {
      if (!existingNames.contains(name)) {
        final doc = _categories.doc();

        batch.set(doc, {
          'name': name,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        addedCount++;
      }
    }

    if (addedCount > 0) {
      await batch.commit();
    }
  }

  // Add a category
  Future<void> addCategory(String name) async {
    final userId = _userId;
    final categoryName = name.trim();

    if (categoryName.isEmpty) {
      throw Exception('Category name cannot be empty.');
    }

    final existing = await _categories
        .where('userId', isEqualTo: userId)
        .where('name', isEqualTo: categoryName)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Category already exists.');
    }

    await _categories.add({
      'name': categoryName,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a category
  Future<void> deleteCategory(String categoryId) async {
    final userId = _userId;
    final doc = await _categories.doc(categoryId).get();

    if (!doc.exists || doc.data()?['userId'] != userId) {
      throw Exception('Category not found.');
    }

    await doc.reference.delete();
  }
}