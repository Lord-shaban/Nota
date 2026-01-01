import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// قسم آخر الملاحظات والأنشطة
class RecentNotesSection extends StatelessWidget {
  final VoidCallback onViewAll;
  final Function(Map<String, dynamic>) onTapNote;

  const RecentNotesSection({
    super.key,
    required this.onViewAll,
    required this.onTapNote,
  });

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_userId == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'آخر الأنشطة',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Recent Activities
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getCombinedActivitiesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF58CC02)),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final activities = snapshot.data!;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length > 5 ? 5 : activities.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) => _ActivityItem(
                  activity: activities[index],
                  onTap: () => onTapNote(activities[index]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Stream<List<Map<String, dynamic>>> _getCombinedActivitiesStream() async* {
    final firestore = FirebaseFirestore.instance;
    
    // Combine notes, appointments, and expenses
    final notesStream = firestore
        .collection('users')
        .doc(_userId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots();

    await for (final notes in notesStream) {
      final appointmentsSnapshot = await firestore
          .collection('appointments')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      final expensesSnapshot = await firestore
          .collection('expenses')
          .where('userId', isEqualTo: _userId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      final allActivities = <Map<String, dynamic>>[];

      // Add notes
      for (var doc in notes.docs) {
        final data = doc.data();
        allActivities.add({
          'id': doc.id,
          'source': 'notes',
          ...data,
        });
      }

      // Add appointments
      for (var doc in appointmentsSnapshot.docs) {
        final data = doc.data();
        allActivities.add({
          'id': doc.id,
          'source': 'appointments',
          'type': 'appointment',
          ...data,
        });
      }

      // Add expenses
      for (var doc in expensesSnapshot.docs) {
        final data = doc.data();
        allActivities.add({
          'id': doc.id,
          'source': 'expenses',
          'type': 'expense',
          ...data,
        });
      }

      // Sort by createdAt
      allActivities.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      yield allActivities;
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 32,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(width: 12),
          Text(
            'لا توجد أنشطة حديثة',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback onTap;

  const _ActivityItem({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = activity['type'] ?? 'note';
    IconData icon;
    Color color;
    String subtitle = '';

    switch (type) {
      case 'task':
        icon = Icons.task_alt_rounded;
        color = const Color(0xFF58CC02);
        subtitle = activity['completed'] == true ? 'مكتملة' : 'معلقة';
        break;
      case 'appointment':
        icon = Icons.event_rounded;
        color = const Color(0xFFFFB800);
        final dateTime = (activity['dateTime'] as Timestamp?)?.toDate();
        if (dateTime != null) {
          subtitle = DateFormat('dd/MM - HH:mm').format(dateTime);
        }
        break;
      case 'expense':
        icon = Icons.receipt_long_rounded;
        color = Colors.blue;
        subtitle = '${activity['amount'] ?? 0} ${activity['currency'] ?? 'ر.س'}';
        break;
      case 'quote':
        icon = Icons.format_quote_rounded;
        color = Colors.purple;
        subtitle = 'اقتباس';
        break;
      default:
        icon = Icons.note_rounded;
        color = Colors.grey;
        subtitle = 'ملاحظة';
    }

    final createdAt = (activity['createdAt'] as Timestamp?)?.toDate();
    final timeAgo = createdAt != null ? _getTimeAgo(createdAt) : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title'] ?? 'بدون عنوان',
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                timeAgo,
                style: GoogleFonts.tajawal(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }
}
