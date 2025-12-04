import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../auth/splash/animated_splash_screen.dart';

/// Home Screen / Dashboard (alNota Style)
/// Main screen with tabs matching alNota design exactly
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nota - ملاحظاتك الذكية',
          style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.home, size: 20), text: 'الكل'),
            Tab(icon: Icon(Icons.check_circle_outline, size: 20), text: 'مهام'),
            Tab(icon: Icon(Icons.event, size: 20), text: 'مواعيد'),
            Tab(icon: Icon(Icons.attach_money, size: 20), text: 'مصروفات'),
            Tab(icon: Icon(Icons.more_horiz, size: 20), text: 'أخرى'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTab(),
          _buildCategoryTab('todo'),
          _buildCategoryTab('appointment'),
          _buildCategoryTab('expense'),
          _buildCategoryTab('note'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoteDialog,
        icon: const Icon(Icons.add),
        label: Text('إضافة', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
      ),
    );
  }

  /// Build All Items Tab
  Widget _buildAllTab() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Center(child: Text('غير مسجل'));

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState('لا توجد ملاحظات', 'ابدأ بإضافة ملاحظة جديدة', Icons.note_add);
        }

        final notes = snapshot.data!.docs;
        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index].data() as Map<String, dynamic>;
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50,
                  child: FadeInAnimation(
                    child: _buildNoteCard(note, notes[index].id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Build Category Tab
  Widget _buildCategoryTab(String category) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Center(child: Text('غير مسجل'));

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(
            'لا توجد عناصر',
            'ابدأ بإضافة $category',
            _getCategoryIcon(category),
          );
        }

        final notes = snapshot.data!.docs;
        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index].data() as Map<String, dynamic>;
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50,
                  child: FadeInAnimation(
                    child: _buildNoteCard(note, notes[index].id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Build Note Card
  Widget _buildNoteCard(Map<String, dynamic> note, String docId) {
    final category = note['category'] ?? 'note';
    final title = note['title'] ?? 'بدون عنوان';
    final content = note['content'] ?? '';
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          content,
          style: GoogleFonts.tajawal(fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 20),
                  const SizedBox(width: 8),
                  Text('تعديل', style: GoogleFonts.tajawal()),
                ],
              ),
              onTap: () => _editNote(docId, note),
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('حذف', style: GoogleFonts.tajawal(color: Colors.red)),
                ],
              ),
              onTap: () => _deleteNote(docId),
            ),
          ],
        ),
        onTap: () => _showNoteDetails(note),
      ),
    );
  }

  /// Build Empty State
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.tajawal(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Get Category Icon
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'todo':
      case 'مهمة':
        return Icons.check_box;
      case 'appointment':
      case 'موعد':
        return Icons.calendar_today;
      case 'expense':
      case 'مصروف':
        return Icons.attach_money;
      case 'note':
      case 'ملاحظة':
      default:
        return Icons.note;
    }
  }

  /// Get Category Color
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'todo':
      case 'مهمة':
        return Colors.blue;
      case 'appointment':
      case 'موعد':
        return Colors.green;
      case 'expense':
      case 'مصروف':
        return Colors.orange;
      case 'note':
      case 'ملاحظة':
      default:
        return const Color(0xFFFFB800);
    }
  }

  /// Show Add Note Dialog
  void _showAddNoteDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedCategory = 'note';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'إضافة ملاحظة جديدة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'المحتوى',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'الفئة',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'note', child: Text('ملاحظة')),
                  DropdownMenuItem(value: 'todo', child: Text('مهمة')),
                  DropdownMenuItem(value: 'appointment', child: Text('موعد')),
                  DropdownMenuItem(value: 'expense', child: Text('مصروف')),
                ],
                onChanged: (value) {
                  if (value != null) selectedCategory = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال العنوان')),
                );
                return;
              }

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              await FirebaseFirestore.instance.collection('notes').add({
                'userId': user.uid,
                'title': titleController.text.trim(),
                'content': contentController.text.trim(),
                'category': selectedCategory,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إضافة الملاحظة بنجاح')),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  /// Edit Note
  void _editNote(String docId, Map<String, dynamic> note) {
    final titleController = TextEditingController(text: note['title']);
    final contentController = TextEditingController(text: note['content']);
    String selectedCategory = note['category'] ?? 'note';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'تعديل الملاحظة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'المحتوى',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'الفئة',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'note', child: Text('ملاحظة')),
                  DropdownMenuItem(value: 'todo', child: Text('مهمة')),
                  DropdownMenuItem(value: 'appointment', child: Text('موعد')),
                  DropdownMenuItem(value: 'expense', child: Text('مصروف')),
                ],
                onChanged: (value) {
                  if (value != null) selectedCategory = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('notes')
                  .doc(docId)
                  .update({
                'title': titleController.text.trim(),
                'content': contentController.text.trim(),
                'category': selectedCategory,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث الملاحظة بنجاح')),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  /// Delete Note
  void _deleteNote(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'حذف الملاحظة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: const Text('هل أنت متأكد من حذف هذه الملاحظة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('notes')
                  .doc(docId)
                  .delete();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف الملاحظة')),
                );
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  /// Show Note Details
  void _showNoteDetails(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          note['title'] ?? 'بدون عنوان',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                note['content'] ?? 'لا يوجد محتوى',
                style: GoogleFonts.tajawal(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(note['category'] ?? 'note'),
                    color: _getCategoryColor(note['category'] ?? 'note'),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    note['category'] ?? 'ملاحظة',
                    style: GoogleFonts.tajawal(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// Show Search Dialog
  void _showSearchDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('قريباً: البحث في الملاحظات')),
    );
  }

  /// Handle Logout
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'تسجيل الخروج',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const AnimatedSplashScreen(),
          ),
          (route) => false,
        );
      }
    }
  }
}
