import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
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
            Text(
              'المهام الأخيرة',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: widget.onViewAll,
              child: Text(
                'عرض الكل',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF58CC02),
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
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('notes')
                  .where('type', isEqualTo: 'task')
                  .snapshots(),
              builder: (context, standaloneSnapshot) {
                if (groupSnapshot.connectionState == ConnectionState.waiting ||
                    standaloneSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: Color(0xFF58CC02),
                      ),
                    ),
                  );
                }

                // Collect all tasks synchronously
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _collectAllTasks(groupSnapshot, standaloneSnapshot, userId),
                  builder: (context, tasksFuture) {
                    if (!tasksFuture.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: Color(0xFF58CC02),
                          ),
                        ),
                      );
                    }

                    final allTasks = tasksFuture.data!;

                    if (allTasks.isEmpty) {
                      return _buildEmptyState();
                    }

                    // Sort by createdAt (newest first)
                    allTasks.sort((a, b) {
                      try {
                        if (a['isStandalone'] == true && b['isStandalone'] == true) {
                          final aData = a['task'] as Map<String, dynamic>;
                          final bData = b['task'] as Map<String, dynamic>;
                          final aTime = aData['createdAt'] as Timestamp?;
                          final bTime = bData['createdAt'] as Timestamp?;
                          if (aTime != null && bTime != null) {
                            return bTime.compareTo(aTime);
                          }
                          return 0;
                        } else if (a['isStandalone'] == false && b['isStandalone'] == false) {
                          final taskA = a['task'] as TaskModel;
                          final taskB = b['task'] as TaskModel;
                          return taskB.createdAt.compareTo(taskA.createdAt);
                        } else {
                          // Mix standalone and group tasks by timestamp
                          final aTime = a['isStandalone'] == true
                              ? (a['task'] as Map<String, dynamic>)['createdAt'] as Timestamp?
                              : (a['task'] as TaskModel).createdAt;
                          final bTime = b['isStandalone'] == true
                              ? (b['task'] as Map<String, dynamic>)['createdAt'] as Timestamp?
                              : (b['task'] as TaskModel).createdAt;
                          
                          if (aTime is Timestamp && bTime is Timestamp) {
                            return bTime.compareTo(aTime);
                          } else if (aTime is DateTime && bTime is DateTime) {
                            return bTime.compareTo(aTime);
                          } else if (aTime is Timestamp && bTime is DateTime) {
                            return bTime.compareTo(aTime.toDate());
                          } else if (aTime is DateTime && bTime is Timestamp) {
                            return bTime.toDate().compareTo(aTime);
                          }
                          return 0;
                        }
                      } catch (e) {
                        return 0;
                      }
                    });

                    final recentTasks = allTasks.take(5).toList();

                    return Column(
                      children: recentTasks
                          .map((taskData) => taskData['isStandalone'] == true
                              ? _buildStandaloneTaskCard(context, taskData)
                              : _buildTaskCard(context, taskData))
                          .toList(),
                    );
                  },
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF58CC02).withOpacity(0.05),
            const Color(0xFFFFD900).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF58CC02).withOpacity(0.1),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 48,
                color: Color(0xFF58CC02),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد مهام بعد',
              style: GoogleFonts.cairo(
                color: const Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ بإضافة مهامك من الزر أدناه',
              style: GoogleFonts.cairo(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: widget.onViewAll,
              icon: const Icon(Icons.add_task, size: 20),
              label: Text(
                'إضافة مهمة',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58CC02),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _collectAllTasks(
    AsyncSnapshot<QuerySnapshot> groupSnapshot,
    AsyncSnapshot<QuerySnapshot> standaloneSnapshot,
    String userId,
  ) async {
    final allTasks = <Map<String, dynamic>>[];

    // Add tasks from groups
    if (groupSnapshot.hasData && groupSnapshot.data!.docs.isNotEmpty) {
      final groups = groupSnapshot.data!.docs;
      
      for (var groupDoc in groups) {
        try {
          final groupId = groupDoc.id;
          final groupData = TaskGroup.fromFirestore(groupDoc);
          
          // Get tasks for this group
          final tasksSnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('taskGroups')
              .doc(groupId)
              .collection('tasks')
              .get();
          
          for (var taskDoc in tasksSnapshot.docs) {
            try {
              final task = TaskModel.fromFirestore(taskDoc);
              allTasks.add({
                'task': task,
                'groupId': groupId,
                'groupIcon': groupData.icon,
                'groupTitle': groupData.title,
                'groupColor': groupData.color,
                'isStandalone': false,
              });
            } catch (e) {
              // Skip invalid tasks
            }
          }
        } catch (e) {
          // Skip invalid group
        }
      }
    }

    // Add standalone tasks
    if (standaloneSnapshot.hasData && standaloneSnapshot.data!.docs.isNotEmpty) {
      for (var doc in standaloneSnapshot.data!.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          allTasks.add({
            'task': data,
            'taskId': doc.id,
            'groupIcon': '📝',
            'groupTitle': 'بدون مجموعة',
            'groupColor': '#6B7280',
            'isStandalone': true,
          });
        } catch (e) {
          // Skip invalid tasks
        }
      }
    }

    return allTasks;
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
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
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
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
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
                            style: GoogleFonts.cairo(
                              fontSize: 10,
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
            content: Text(
              'حدث خطأ أثناء التحديث',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStandaloneTaskCard(BuildContext context, Map<String, dynamic> taskData) {
    final task = taskData['task'] as Map<String, dynamic>;
    final taskId = taskData['taskId'] as String;
    final groupIcon = taskData['groupIcon'] as String;
    final groupTitle = taskData['groupTitle'] as String;
    final groupColor = taskData['groupColor'] as String;

    final title = task['title'] as String? ?? 'بدون عنوان';
    final isCompleted = task['completed'] as bool? ?? false;
    final priority = task['priority'] as String? ?? 'medium';

    // Priority icon
    String priorityIcon = '🟡';
    switch (priority) {
      case 'urgent':
        priorityIcon = '🔴';
        break;
      case 'high':
        priorityIcon = '🟠';
        break;
      case 'low':
        priorityIcon = '🟢';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? AppTheme.successColor.withOpacity(0.3)
              : Color(int.parse(groupColor.replaceFirst('#', '0xFF')))
                  .withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showStandaloneTaskDetails(context, task, taskId),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              InkWell(
                onTap: () => _toggleStandaloneTaskComplete(taskId, isCompleted),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  child: isCompleted
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
                            title,
                            style: GoogleFonts.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? AppTheme.textLightColor
                                  : AppTheme.textPrimaryColor,
                              decoration: isCompleted
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
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(int.parse(
                                  groupColor.replaceFirst('#', '0xFF'))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Priority
                        Text(
                          priorityIcon,
                          style: const TextStyle(fontSize: 12),
                        ),
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

  void _showStandaloneTaskDetails(BuildContext context, Map<String, dynamic> task, String taskId) {
    // For now, just show a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          task['title'] ?? 'مهمة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task['content'] != null && task['content'].toString().isNotEmpty)
              Text(
                task['content'],
                style: GoogleFonts.cairo(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStandaloneTaskComplete(String taskId, bool currentStatus) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(taskId)
          .update({
        'completed': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء التحديث',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
