import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/task_model.dart';
import '../../../core/models/task_group.dart';
import '../../../core/theme/app_theme.dart';
import '../tasks/create_task_dialog.dart';

/// Widget to display recent tasks in home tab
/// Fully integrated with TasksTabView system
/// 
/// Co-authored-by: ALi Sameh
/// Co-authored-by: Mahmoud Abdelrauf
class RecentTasksWidget extends StatefulWidget {
  final VoidCallback? onViewAll;

  const RecentTasksWidget({Key? key, this.onViewAll}) : super(key: key);

  @override
  State<RecentTasksWidget> createState() => _RecentTasksWidgetState();
}

class _RecentTasksWidgetState extends State<RecentTasksWidget> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid ?? '';
    
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
              onPressed: widget.onViewAll,
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
          stream: _firestore
              .collection('users')
              .doc(userId)
              .collection('taskGroups')
              .snapshots(),
          builder: (context, groupSnapshot) {
            if (groupSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Color(0xFF58CC02),
                  ),
                ),
              );
            }

            if (!groupSnapshot.hasData || groupSnapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            // Get all tasks from all groups
            final groups = groupSnapshot.data!.docs;
            
            return FutureBuilder<List<QuerySnapshot>>(
              future: Future.wait(
                groups.map((groupDoc) {
                  return _firestore
                      .collection('users')
                      .doc(userId)
                      .collection('taskGroups')
                      .doc(groupDoc.id)
                      .collection('tasks')
                      .get();
                }).toList(),
              ),
              builder: (context, tasksSnapshot) {
                if (tasksSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: Color(0xFF58CC02),
                      ),
                    ),
                  );
                }

                if (!tasksSnapshot.hasData) {
                  return _buildEmptyState();
                }

                // Combine all tasks
                final allTasks = <Map<String, dynamic>>[];
                for (int i = 0; i < tasksSnapshot.data!.length; i++) {
                  final taskDocs = tasksSnapshot.data![i].docs;
                  final groupId = groups[i].id;
                  final groupData = TaskGroup.fromFirestore(groups[i]);
                  
                  for (var taskDoc in taskDocs) {
                    try {
                      final task = TaskModel.fromFirestore(taskDoc);
                      allTasks.add({
                        'task': task,
                        'groupId': groupId,
                        'groupIcon': groupData.icon,
                        'groupTitle': groupData.title,
                        'groupColor': groupData.color,
                      });
                    } catch (e) {
                      // Skip invalid tasks
                    }
                  }
                }

                if (allTasks.isEmpty) {
                  return _buildEmptyState();
                }

                // Sort by createdAt (newest first) and take 5
                allTasks.sort((a, b) {
                  final taskA = a['task'] as TaskModel;
                  final taskB = b['task'] as TaskModel;
                  return taskB.createdAt.compareTo(taskA.createdAt);
                });
                final recentTasks = allTasks.take(5).toList();

                return Column(
                  children: recentTasks
                      .map((taskData) => _buildTaskCard(context, taskData))
                      .toList(),
                );
              },
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

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> taskData) {
    final task = taskData['task'] as TaskModel;
    final groupIcon = taskData['groupIcon'] as String;
    final groupTitle = taskData['groupTitle'] as String;
    final groupColor = taskData['groupColor'] as String;
    final groupId = taskData['groupId'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isCompleted
              ? AppTheme.successColor.withOpacity(0.3)
              : Color(int.parse(groupColor.replaceFirst('#', '0xFF')))
                  .withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTaskDetails(context, task, groupId),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              InkWell(
                onTap: () => _toggleTaskComplete(task, groupId),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 36,
                  height: 36,
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
                          size: 20,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Task content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          groupIcon,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Group badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(int.parse(
                                    groupColor.replaceFirst('#', '0xFF')))
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            groupTitle,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Tajawal',
                              color: Color(int.parse(
                                  groupColor.replaceFirst('#', '0xFF'))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Priority
                        Text(
                          task.priorityIcon,
                          style: const TextStyle(fontSize: 12),
                        ),
                        // Due date
                        if (task.dueDate != null) ...[
                          const SizedBox(width: 6),
                          Icon(
                            task.isOverdue
                                ? Icons.error_outline
                                : task.isDueToday
                                    ? Icons.today_outlined
                                    : Icons.calendar_today_outlined,
                            size: 12,
                            color: task.isOverdue
                                ? Colors.red
                                : task.isDueToday
                                    ? AppTheme.accentColor
                                    : AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatDueDate(task.dueDate!),
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'Tajawal',
                              color: task.isOverdue
                                  ? Colors.red
                                  : AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    
    if (taskDate == today) return 'اليوم';
    if (taskDate == today.add(const Duration(days: 1))) return 'غداً';
    if (taskDate == today.subtract(const Duration(days: 1))) return 'أمس';
    
    final diff = taskDate.difference(today).inDays;
    if (diff > 0 && diff <= 7) return 'خلال $diff يوم';
    if (diff < 0 && diff >= -7) return 'منذ ${-diff} يوم';
    
    return '${date.day}/${date.month}';
  }

  void _showTaskDetails(BuildContext context, TaskModel task, String groupId) {
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(
        groupId: groupId,
        task: task,
      ),
    );
  }

  Future<void> _toggleTaskComplete(TaskModel task, String groupId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final newStatus = !task.isCompleted;
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('taskGroups')
          .doc(groupId)
          .collection('tasks')
          .doc(task.id)
          .update({
        'isCompleted': newStatus,
        'completedAt': newStatus ? FieldValue.serverTimestamp() : null,
      });

      // Update group stats
      final groupRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('taskGroups')
          .doc(groupId);

      final groupDoc = await groupRef.get();
      if (groupDoc.exists) {
        final currentCompleted = groupDoc.data()?['completedTasks'] ?? 0;
        await groupRef.update({
          'completedTasks': newStatus ? currentCompleted + 1 : currentCompleted - 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'حدث خطأ أثناء التحديث',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
