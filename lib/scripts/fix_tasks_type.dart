import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to fix old tasks by adding 'type' field
/// Run this once to update all existing tasks in Firestore
/// 
/// Co-authored-by: ALi Sameh
/// Co-authored-by: Mahmoud Abdelrauf

Future<void> fixTasksType() async {
  print('🔧 Starting to fix tasks...');
  
  try {
    // Get all documents from notes collection without type field
    final snapshot = await FirebaseFirestore.instance
        .collection('notes')
        .get();
    
    print('📦 Found ${snapshot.docs.length} documents');
    
    int updated = 0;
    int skipped = 0;
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      
      // Check if it has groupId (which means it's a task)
      if (data.containsKey('groupId') && !data.containsKey('type')) {
        // Update with type field
        await doc.reference.update({'type': 'task'});
        print('✅ Updated task: ${doc.id}');
        updated++;
      } else if (data.containsKey('type')) {
        print('⏭️  Skipped (already has type): ${doc.id}');
        skipped++;
      } else {
        // It's a note, not a task
        print('📝 Skipped (note): ${doc.id}');
        skipped++;
      }
    }
    
    print('');
    print('✨ Fix completed!');
    // print('   Updated: $updated tasks');
    // print('   Skipped: $skipped documents');
    
  } catch (e) {
    // print('❌ Error: $e');
  }
}
