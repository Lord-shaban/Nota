// lib/core/database/notes_repository.dart
import '../models/note.dart';
import 'firebase_service.dart';

class NotesRepository {
  final FirebaseService _firebaseService;

  NotesRepository({required FirebaseService firebaseService})
      : _firebaseService = firebaseService;

  // Create a new note
  Future<Note> createNote(Note note) async {
    try {
      if (!note.isValid) {
        throw Exception('Cannot create invalid note');
      }

      final noteToCreate = note.copyWith(
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
      );

      final noteId = await _firebaseService.createDocument(
        collection: FirebaseCollections.notes,
        data: noteToCreate.toJson(),
      );

      return noteToCreate.copyWith(id: noteId);
    } catch (e) {
      throw Exception('Failed to create note: $e');
    }
  }

  // Get all notes for a user
  Future<List<Note>> getNotes({required String userId}) async {
    try {
      final data = await _firebaseService.getCollection(
        collection: FirebaseCollections.notes,
        orderBy: 'dateModified',
        descending: true,
      );

      final notes = data.map((json) => Note.fromJson(json)).toList();
      return notes;
    } catch (e) {
      throw Exception('Failed to fetch notes: $e');
    }
  }

  // Get a specific note by ID
  Future<Note?> getNoteById(String noteId, String userId) async {
    try {
      final data = await _firebaseService.getDocument(
        collection: FirebaseCollections.notes,
        documentId: noteId,
      );

      if (data == null) return null;

      final note = Note.fromJson(data);

      // Security check
      if (note.userId != userId) {
        throw Exception('Access denied: Note does not belong to user');
      }

      return note;
    } catch (e) {
      throw Exception('Failed to fetch note: $e');
    }
  }

  // Update an existing note
  Future<Note> updateNote(Note note) async {
    try {
      if (!note.isValid) {
        throw Exception('Cannot update invalid note');
      }

      final updatedNote = note.copyWith(dateModified: DateTime.now());

      await _firebaseService.updateDocument(
        collection: FirebaseCollections.notes,
        documentId: updatedNote.id,
        data: updatedNote.toJson(),
      );

      return updatedNote;
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  // Delete a note
  Future<void> deleteNote(String noteId, String userId) async {
    try {
      // Verify note exists and belongs to user
      final note = await getNoteById(noteId, userId);
      if (note == null) {
        throw Exception('Note not found or access denied');
      }

      await _firebaseService.deleteDocument(
        collection: FirebaseCollections.notes,
        documentId: noteId,
      );
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  // Search notes by text
  Future<List<Note>> searchNotes({
    required String userId,
    required String query,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return await getNotes(userId: userId);
      }

      final data = await _firebaseService.searchDocuments(
        collection: FirebaseCollections.notes,
        searchTerm: query,
        searchFields: ['title', 'content', 'tags'],
      );

      return data.map((json) => Note.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search notes: $e');
    }
  }

  // Get notes by category
  Future<List<Note>> getNotesByCategory({
    required String userId,
    required NoteCategory category,
  }) async {
    try {
      final data = await _firebaseService.getCollection(
        collection: FirebaseCollections.notes,
        where: {'category': category.name},
        orderBy: 'dateModified',
        descending: true,
      );

      return data.map((json) => Note.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notes by category: $e');
    }
  }

  // Get archived notes
  Future<List<Note>> getArchivedNotes({required String userId}) async {
    try {
      final data = await _firebaseService.getCollection(
        collection: FirebaseCollections.notes,
        where: {'isArchived': true},
        orderBy: 'dateModified',
        descending: true,
      );

      return data.map((json) => Note.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch archived notes: $e');
    }
  }

  // Get recent notes (last 7 days)
  Future<List<Note>> getRecentNotes({required String userId}) async {
    try {
      final data = await _firebaseService.getTodayDocuments(
        collection: FirebaseCollections.notes,
      );

      return data.map((json) => Note.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recent notes: $e');
    }
  }

  // Real-time stream of notes
  Stream<List<Note>> getNotesStream({required String userId}) {
    return _firebaseService.collectionStream(
      collection: FirebaseCollections.notes,
      orderBy: 'dateModified',
      descending: true,
    ).map((dataList) {
      return dataList.map((json) => Note.fromJson(json)).toList();
    });
  }

  // Real-time stream of a single note
  Stream<Note?> getNoteStream({required String noteId, required String userId}) {
    return _firebaseService.documentStream(
      collection: FirebaseCollections.notes,
      documentId: noteId,
    ).map((data) {
      if (data == null) return null;
      final note = Note.fromJson(data);
      // Security check
      if (note.userId != userId) return null;
      return note;
    });
  }

  // Bulk operations
  Future<void> archiveNotes(List<String> noteIds, String userId) async {
    try {
      final operations = noteIds.map((noteId) {
        return BatchOperation(
          collection: FirebaseCollections.notes,
          documentId: noteId,
          type: OperationType.update,
          data: {'isArchived': true},
        );
      }).toList();

      await _firebaseService.batchWrite(operations: operations);
    } catch (e) {
      throw Exception('Failed to archive notes: $e');
    }
  }

  Future<void> unarchiveNotes(List<String> noteIds, String userId) async {
    try {
      final operations = noteIds.map((noteId) {
        return BatchOperation(
          collection: FirebaseCollections.notes,
          documentId: noteId,
          type: OperationType.update,
          data: {'isArchived': false},
        );
      }).toList();

      await _firebaseService.batchWrite(operations: operations);
    } catch (e) {
      throw Exception('Failed to unarchive notes: $e');
    }
  }

  // Statistics
  Future<Map<String, int>> getStatistics(String userId) async {
    try {
      return await _firebaseService.getStatistics();
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }
}
