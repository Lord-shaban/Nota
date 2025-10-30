import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

/// Firebase Service - Central hub for all Firebase operations
/// Handles initialization, CRUD operations, and real-time listeners
class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  static FirebaseFirestore? _firestore;
  static FirebaseAuth? _auth;
  static FirebaseStorage? _storage;

  // Current user getter
  User? get currentUser => _auth?.currentUser;
  String? get userId => currentUser?.uid;

  // ==================== INITIALIZATION ====================

  /// Initialize Firebase services
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      _storage = FirebaseStorage.instance;

      // Enable offline persistence
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Firebase initialization error: $e');
      throw Exception('Failed to initialize Firebase: $e');
    }
  }

  /// Check if Firebase is initialized
  bool get isInitialized =>
      _firestore != null && _auth != null && _storage != null;

  /// Ensure Firebase is initialized before operations
  void _ensureInitialized() {
    if (!isInitialized) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
  }

  // ==================== CRUD OPERATIONS ====================

  /// CREATE - Add document to collection
  Future<String> createDocument({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    _ensureInitialized();

    try {
      // Add metadata
      data['userId'] = userId;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      DocumentReference docRef;
      if (documentId != null) {
        docRef = _firestore!.collection(collection).doc(documentId);
        await docRef.set(data);
      } else {
        docRef = await _firestore!.collection(collection).add(data);
      }

      print('✅ Document created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Create document error: $e');
      throw Exception('Failed to create document: $e');
    }
  }

  /// READ - Get single document
  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String documentId,
  }) async {
    _ensureInitialized();

    try {
      DocumentSnapshot doc = await _firestore!
          .collection(collection)
          .doc(documentId)
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Get document error: $e');
      throw Exception('Failed to get document: $e');
    }
  }

  /// READ - Get all documents from collection
  Future<List<Map<String, dynamic>>> getCollection({
    required String collection,
    String? orderBy,
    bool descending = false,
    int? limit,
    Map<String, dynamic>? where,
  }) async {
    _ensureInitialized();

    try {
      Query query = _firestore!.collection(collection);

      // Add user filter for personal data
      query = query.where('userId', isEqualTo: userId);

      // Apply additional filters
      if (where != null) {
        where.forEach((field, value) {
          if (value is List) {
            query = query.where(field, whereIn: value);
          } else {
            query = query.where(field, isEqualTo: value);
          }
        });
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Get collection error: $e');
      throw Exception('Failed to get collection: $e');
    }
  }

  /// UPDATE - Update document
  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    _ensureInitialized();

    try {
      // Add update timestamp
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore!.collection(collection).doc(documentId).update(data);

      print('✅ Document updated: $documentId');
    } catch (e) {
      print('❌ Update document error: $e');
      throw Exception('Failed to update document: $e');
    }
  }

  /// DELETE - Delete document
  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    _ensureInitialized();

    try {
      await _firestore!.collection(collection).doc(documentId).delete();

      print('✅ Document deleted: $documentId');
    } catch (e) {
      print('❌ Delete document error: $e');
      throw Exception('Failed to delete document: $e');
    }
  }

  // ==================== REAL-TIME LISTENERS ====================

  /// Listen to single document changes
  Stream<Map<String, dynamic>?> documentStream({
    required String collection,
    required String documentId,
  }) {
    _ensureInitialized();

    return _firestore!.collection(collection).doc(documentId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        data['id'] = snapshot.id;
        return data;
      }
      return null;
    });
  }

  /// Listen to collection changes
  Stream<List<Map<String, dynamic>>> collectionStream({
    required String collection,
    String? orderBy,
    bool descending = false,
    Map<String, dynamic>? where,
  }) {
    _ensureInitialized();

    Query query = _firestore!.collection(collection);

    // Add user filter
    query = query.where('userId', isEqualTo: userId);

    // Apply filters
    if (where != null) {
      where.forEach((field, value) {
        query = query.where(field, isEqualTo: value);
      });
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // ==================== BATCH OPERATIONS ====================

  /// Batch write for multiple operations
  Future<void> batchWrite({required List<BatchOperation> operations}) async {
    _ensureInitialized();

    try {
      WriteBatch batch = _firestore!.batch();

      for (var operation in operations) {
        DocumentReference docRef = _firestore!
            .collection(operation.collection)
            .doc(operation.documentId);

        switch (operation.type) {
          case OperationType.create:
            batch.set(docRef, operation.data!);
            break;
          case OperationType.update:
            batch.update(docRef, operation.data!);
            break;
          case OperationType.delete:
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
      print('✅ Batch write completed: ${operations.length} operations');
    } catch (e) {
      print('❌ Batch write error: $e');
      throw Exception('Failed to execute batch write: $e');
    }
  }

  // ==================== SEARCH OPERATIONS ====================

  /// Search across multiple fields
  Future<List<Map<String, dynamic>>> searchDocuments({
    required String collection,
    required String searchTerm,
    required List<String> searchFields,
  }) async {
    _ensureInitialized();

    try {
      // For simple search, we'll get all documents and filter locally
      // For production, consider using Algolia or ElasticSearch
      List<Map<String, dynamic>> allDocs = await getCollection(
        collection: collection,
      );

      String searchLower = searchTerm.toLowerCase();

      return allDocs.where((doc) {
        for (String field in searchFields) {
          if (doc[field] != null &&
              doc[field].toString().toLowerCase().contains(searchLower)) {
            return true;
          }
        }
        return false;
      }).toList();
    } catch (e) {
      print('❌ Search error: $e');
      throw Exception('Failed to search documents: $e');
    }
  }

  // ==================== STORAGE OPERATIONS ====================

  /// Upload file to Firebase Storage
  Future<String> uploadFile({
    required File file,
    required String path,
    Function(double)? onProgress,
  }) async {
    _ensureInitialized();

    try {
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      Reference ref = _storage!.ref().child('$path/$fileName');

      UploadTask uploadTask = ref.putFile(file);

      // Listen to upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ File uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Upload file error: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Delete file from Firebase Storage
  Future<void> deleteFile({required String fileUrl}) async {
    _ensureInitialized();

    try {
      Reference ref = _storage!.refFromURL(fileUrl);
      await ref.delete();
      print('✅ File deleted from storage');
    } catch (e) {
      print('❌ Delete file error: $e');
      throw Exception('Failed to delete file: $e');
    }
  }

  // ==================== SPECIAL QUERIES ====================

  /// Get documents created today
  Future<List<Map<String, dynamic>>> getTodayDocuments({
    required String collection,
  }) async {
    _ensureInitialized();

    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      QuerySnapshot snapshot = await _firestore!
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
          .where('createdAt', isLessThan: endOfDay)
          .get();

      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Get today documents error: $e');
      throw Exception('Failed to get today documents: $e');
    }
  }

  /// Get statistics for dashboard
  Future<Map<String, int>> getStatistics() async {
    _ensureInitialized();

    try {
      // Get counts for each collection
      final futures = await Future.wait([
        _firestore!
            .collection('notes')
            .where('userId', isEqualTo: userId)
            .count()
            .get(),
        _firestore!
            .collection('tasks')
            .where('userId', isEqualTo: userId)
            .where('isCompleted', isEqualTo: false)
            .count()
            .get(),
        _firestore!
            .collection('appointments')
            .where('userId', isEqualTo: userId)
            .where('date', isGreaterThan: DateTime.now())
            .count()
            .get(),
        _firestore!
            .collection('expenses')
            .where('userId', isEqualTo: userId)
            .count()
            .get(),
      ]);

      return {
        'notes': futures[0].count ?? 0,
        'pendingTasks': futures[1].count ?? 0,
        'upcomingAppointments': futures[2].count ?? 0,
        'expenses': futures[3].count ?? 0,
      };
    } catch (e) {
      print('❌ Get statistics error: $e');
      return {
        'notes': 0,
        'pendingTasks': 0,
        'upcomingAppointments': 0,
        'expenses': 0,
      };
    }
  }

  // ==================== TEST FUNCTION ====================

  /// Test function for simple data retrieval
  Future<void> testConnection() async {
    try {
      print('🧪 Testing Firebase connection...');

      // Test 1: Check initialization
      if (!isInitialized) {
        await initialize();
      }
      print('✅ Firebase initialized');

      // Test 2: Create test document
      String testId = await createDocument(
        collection: 'test_collection',
        data: {
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
          'message': 'Test document from Nota App',
        },
      );
      print('✅ Test document created: $testId');

      // Test 3: Read test document
      var testDoc = await getDocument(
        collection: 'test_collection',
        documentId: testId,
      );
      print('✅ Test document retrieved: $testDoc');

      // Test 4: Update test document
      await updateDocument(
        collection: 'test_collection',
        documentId: testId,
        data: {'verified': true},
      );
      print('✅ Test document updated');

      // Test 5: Delete test document
      await deleteDocument(collection: 'test_collection', documentId: testId);
      print('✅ Test document deleted');

      print('🎉 All Firebase tests passed successfully!');
    } catch (e) {
      print('❌ Firebase test failed: $e');
      rethrow;
    }
  }
}

// ==================== HELPER CLASSES ====================

/// Batch operation model
class BatchOperation {
  final String collection;
  final String documentId;
  final OperationType type;
  final Map<String, dynamic>? data;

  BatchOperation({
    required this.collection,
    required this.documentId,
    required this.type,
    this.data,
  });
}

/// Operation types for batch operations
enum OperationType { create, update, delete }

// ==================== COLLECTION NAMES ====================
class FirebaseCollections {
  static const String users = 'users';
  static const String notes = 'notes';
  static const String tasks = 'tasks';
  static const String appointments = 'appointments';
  static const String expenses = 'expenses';
  static const String categories = 'categories';
  static const String aiProcessing = 'ai_processing';
}
