import 'package:flutter_test/flutter_test.dart';
import 'package:nota/core/models/note.dart';

void main() {
  group('Note Model Tests', () {
    late Note testNote;

    setUp(() {
      testNote = Note(
        id: 'note-123',
        title: 'Test Note',
        content: 'Test content here',
        category: NoteCategory.personal,
        dateCreated: DateTime(2025, 1, 1),
        dateModified: DateTime(2025, 1, 1),
        userId: 'user-456',
      );
    });

    test('Note should be created with correct data', () {
      expect(testNote.id, 'note-123');
      expect(testNote.title, 'Test Note');
      expect(testNote.content, 'Test content here');
      expect(testNote.userId, 'user-456');
    });

    test('Valid note should pass validation', () {
      expect(testNote.isValid, true);
    });

    test('Note with empty title should be invalid', () {
      final invalidNote = testNote.copyWith(title: '');
      expect(invalidNote.isValid, false);
    });

    test('Note with empty content should be invalid', () {
      final invalidNote = testNote.copyWith(content: '');
      expect(invalidNote.isValid, false);
    });

    test('Should find note by text search', () {
      expect(testNote.containsText('Test'), true);
      expect(testNote.containsText('content'), true);
      expect(testNote.containsText('nonexistent'), false);
    });

    test('copyWith should create new instance', () {
      final updated = testNote.copyWith(title: 'New Title');
      expect(updated.title, 'New Title');
      expect(updated.id, testNote.id);
      expect(updated.content, testNote.content);
    });

    test('Should convert to and from JSON', () {
      final json = testNote.toJson();
      final fromJson = Note.fromJson(json);
      expect(fromJson.id, testNote.id);
      expect(fromJson.title, testNote.title);
      expect(fromJson.content, testNote.content);
    });

    test('Should update modification date when content changes', () {
      final now = DateTime.now();
      final updated = testNote.copyWith(
        content: 'Updated content',
        dateModified: now,
      );
      expect(updated.dateModified, now);
      expect(updated.content, 'Updated content');
    });

    test('Note equality based on ID', () {
      final note2 = testNote.copyWith(title: 'Different Title');
      expect(testNote.id, note2.id);
    });

    test('Should support category categorization', () {
      final workNote = testNote.copyWith(category: NoteCategory.work);
      expect(workNote.category, NoteCategory.work);
    });
  });
}
