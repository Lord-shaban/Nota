import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/task_model.dart';
import '../../../core/theme/app_theme.dart';

/// Widget to display recent tasks in home tab
/// Uses the same design as TaskGroupCard for consistency
/// 
/// Co-authored-by: ALi Sameh
/// Co-authored-by: Mahmoud Abdelrauf
class RecentTasksWidget extends StatelessWidget {
  const RecentTasksWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Color(0xFF58CC02),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'المهام الأخيرة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Tajawal',
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Navigate to tasks tab (will be handled by parent)
              },
              child: const Text(
                'عرض الكل',
                style: TextStyle(
                  color: Color(0xFF58CC02),
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notes')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Color(0xFF58CC02),
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return _buildEmptyState();
            }

            // Filter tasks for current user
            final tasks = snapshot.data!.docs
                .map((doc) {
                  try {
                    final data = doc.data() as Map<String, dynamic>?;
                    if (data != null && 
                        data['type'] == 'task' && 
                        data['userId'] == userId &&
                        data['groupId'] != null) {
                      return TaskModel.fromFirestore(doc);
                    }
                  } catch (e) {
                    // Skip invalid documents
                  }
                  return null;
                })
                .where((task) => task != null)
                .cast<TaskModel>()
                .toList();

            if (tasks.isEmpty) {
              return _buildEmptyState();
            }

            // Sort by createdAt (newest first) and take 5
            tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final recentTasks = tasks.take(5).toList();

            return Column(
              children: recentTasks
                  .map((task) => _buildTaskCard(context, task))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.task_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد مهام بعد',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ بإضافة مهامك الآن',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isCompleted
              ? AppTheme.successColor.withOpacity(0.3)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: _buildCheckbox(task),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Tajawal',
            color: task.isCompleted
                ? AppTheme.textLightColor
                : AppTheme.textPrimaryColor,
            decoration: task.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: task.description != null
            ? Text(
                task.description!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                  fontFamily: 'Tajawal',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Priority indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Color(int.parse(
                        task.priorityColor.replaceFirst('#', '0xFF')))
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  task.priorityIcon,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            // Due date indicator
            if (task.dueDate != null) ...[
              const SizedBox(width: 6),
              Icon(
                task.isOverdue
                    ? Icons.error_outline
                    : task.isDueToday
                        ? Icons.today_outlined
                        : Icons.calendar_today_outlined,
                size: 14,
                color: task.isOverdue
                    ? Colors.red
                    : task.isDueToday
                        ? AppTheme.accentColor
                        : AppTheme.textSecondaryColor,
              ),
            ],
          ],
        ),
        onTap: () {
          // Navigate to task details (will be handled by parent)
        },
      ),
    );
  }

  Widget _buildCheckbox(TaskModel task) {
    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: task.isCompleted 
            ? const Color(0xFF10B981)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: task.isCompleted
              ? const Color(0xFF10B981)
              : const Color(0xFFD1D5DB),
          width: 2,
        ),
      ),
      child: task.isCompleted
          ? const Icon(
              Icons.check,
              color: Colors.white,
              size: 18,
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
    );
  }
}
