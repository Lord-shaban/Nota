import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/task_group.dart';

/// قسم مجموعات المهام في الصفحة الرئيسية
class TaskGroupsSection extends StatelessWidget {
  final VoidCallback onViewAll;

  const TaskGroupsSection({
    super.key,
    required this.onViewAll,
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
                color: const Color(0xFF58CC02).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.folder_rounded,
                color: Color(0xFF58CC02),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'مجموعات المهام',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onViewAll,
              child: Text(
                'عرض الكل',
                style: GoogleFonts.tajawal(
                  color: const Color(0xFF58CC02),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Groups List
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('task_groups')
              .where('userId', isEqualTo: _userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF58CC02)),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(context);
            }

            final groups = snapshot.data!.docs
                .map((doc) => TaskGroup.fromFirestore(doc))
                .toList();

            // Sort by recent activity
            groups.sort((a, b) {
              final bDate = b.updatedAt ?? DateTime.now();
              final aDate = a.updatedAt ?? DateTime.now();
              return bDate.compareTo(aDate);
            });

            return SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: groups.length > 5 ? 5 : groups.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _GroupCard(group: groups[index]),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 40,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لا توجد مجموعات مهام',
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'اذهب للمهام لإنشاء مجموعة جديدة',
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewAll,
            child: Text(
              'إنشاء',
              style: GoogleFonts.tajawal(
                color: const Color(0xFF58CC02),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final TaskGroup group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(group.color.replaceFirst('#', '0xFF')));
    final progress = group.totalTasks > 0
        ? group.completedTasks / group.totalTasks
        : 0.0;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                group.icon,
                style: const TextStyle(fontSize: 28),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${group.completedTasks}/${group.totalTasks}',
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.title,
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
