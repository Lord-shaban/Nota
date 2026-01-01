import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/recent_tasks_widget.dart';
import 'summary_cards.dart';
import 'quick_actions_grid.dart';
import 'task_groups_section.dart';
import 'recent_notes_section.dart';

/// التابة الرئيسية المحسنة - تعرض نظرة عامة شاملة
class EnhancedHomeTab extends StatefulWidget {
  final TabController mainTabController;
  final VoidCallback onAddNew;
  final Map<String, dynamic>? userData;

  const EnhancedHomeTab({
    super.key,
    required this.mainTabController,
    required this.onAddNew,
    this.userData,
  });

  @override
  State<EnhancedHomeTab> createState() => _EnhancedHomeTabState();
}

class _EnhancedHomeTabState extends State<EnhancedHomeTab> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: const Color(0xFF58CC02),
        child: CustomScrollView(
          slivers: [
            // Welcome Card
            SliverToBoxAdapter(
              child: AnimationConfiguration.staggeredList(
                position: 0,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  horizontalOffset: 50,
                  child: FadeInAnimation(
                    child: _buildWelcomeCard(),
                  ),
                ),
              ),
            ),

            // Summary Cards
            SliverToBoxAdapter(
              child: AnimationConfiguration.staggeredList(
                position: 1,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  horizontalOffset: 50,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SummaryCards(
                        onTapTasks: () => widget.mainTabController.animateTo(1),
                        onTapAppointments: () => widget.mainTabController.animateTo(2),
                        onTapExpenses: () => widget.mainTabController.animateTo(3),
                        onTapQuotes: () => widget.mainTabController.animateTo(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Quick Actions
            SliverToBoxAdapter(
              child: AnimationConfiguration.staggeredList(
                position: 2,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  horizontalOffset: 50,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: QuickActionsGrid(
                        onAddTask: () => widget.mainTabController.animateTo(1),
                        onAddAppointment: () => widget.mainTabController.animateTo(2),
                        onAddExpense: () => widget.mainTabController.animateTo(3),
                        onAddQuote: () => widget.mainTabController.animateTo(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Task Groups Section
            SliverToBoxAdapter(
              child: AnimationConfiguration.staggeredList(
                position: 3,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  horizontalOffset: 50,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TaskGroupsSection(
                        onViewAll: () => widget.mainTabController.animateTo(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Recent Tasks
            SliverToBoxAdapter(
              child: AnimationConfiguration.staggeredList(
                position: 4,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  horizontalOffset: 50,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RecentTasksWidget(
                        onViewAll: () => widget.mainTabController.animateTo(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Recent Notes/Activities
            SliverToBoxAdapter(
              child: AnimationConfiguration.staggeredList(
                position: 5,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  horizontalOffset: 50,
                  child: FadeInAnimation(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RecentNotesSection(
                        onViewAll: () {},
                        onTapNote: (note) => _showNoteDetails(note),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'صباح الخير'
        : hour < 18
            ? 'مساء الخير'
            : 'مساء الخير';
    final iconData = hour < 12
        ? Icons.wb_sunny_rounded
        : hour < 18
            ? Icons.wb_twilight_rounded
            : Icons.nightlight_rounded;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF58CC02), Color(0xFF45A801)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF58CC02).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _userId != null
            ? _firestore
                .collection('users')
                .doc(_userId)
                .collection('notes')
                .where('type', isEqualTo: 'task')
                .where('completed', isEqualTo: false)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          int pendingTasks = snapshot.data?.docs.length ?? 0;
          String message = pendingTasks == 0
              ? 'لا توجد مهام معلقة، أحسنت!'
              : pendingTasks == 1
                  ? 'لديك مهمة واحدة غير مكتملة'
                  : 'لديك $pendingTasks مهمة غير مكتملة';

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting، ${widget.userData?['name'] ?? 'صديقي'}',
                      style: GoogleFonts.tajawal(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(iconData, color: Colors.white, size: 32),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNoteDetails(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          note['title'] ?? 'بدون عنوان',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note['content'] ?? 'لا يوجد محتوى',
              style: GoogleFonts.tajawal(fontSize: 16),
            ),
            if (note['imageUrl'] != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  note['imageUrl'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إغلاق', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }
}
