import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/task_model.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'create_task_dialog.dart';

/// All Tasks View with filtering capabilities
/// 
/// Co-authored-by: ALi Sameh
/// Co-authored-by: Mahmoud Abdelrauf
class AllTasksView extends StatelessWidget {
  final String userId;
  final String selectedFilter;
  final String selectedPriority;

  const AllTasksView({
    Key? key,
    required this.userId,
    required this.selectedFilter,
    required this.selectedPriority,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getTasksStream(),
      builder: (context, groupTasksSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _getStandaloneTasksStream(),
          builder: (context, standaloneSnapshot) {
            if (groupTasksSnapshot.connectionState == ConnectionState.waiting ||
                standaloneSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Get group tasks
            var groupTasks = <TaskModel>[];
            if (groupTasksSnapshot.hasData) {
              groupTasks = groupTasksSnapshot.data!.docs
                  .map((doc) {
                    try {
                      return TaskModel.fromFirestore(doc);
                    } catch (e) {
                      return null;
                    }
                  })
                  .where((task) => task != null)
                  .cast<TaskModel>()
                  .where((task) => task.userId == userId && task.groupId != null)
                  .toList();
            }

            // Get standalone tasks
            var standaloneTasks = <Map<String, dynamic>>[];
            if (standaloneSnapshot.hasData) {
              standaloneTasks = standaloneSnapshot.data!.docs
                  .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return {
                      'id': doc.id,
                      'title': data['title'] ?? '',
                      'priority': data['priority'] ?? 'medium',
                      'completed': data['completed'] ?? false,
                      'createdAt': data['createdAt'],
                    };
                  })
                  .toList();
            }

            if (groupTasks.isEmpty && standaloneTasks.isEmpty) {
              return _buildEmptyState(context);
            }

            // Apply filters to group tasks
            if (selectedPriority != 'all') {
              groupTasks = groupTasks.where((t) => t.priority == selectedPriority).toList();
              standaloneTasks = standaloneTasks
                  .where((t) => t['priority'] == selectedPriority)
                  .toList();
            }

            // Sort by createdAt
            groupTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            standaloneTasks.sort((a, b) {
              final aTime = a['createdAt'] as Timestamp?;
              final bTime = b['createdAt'] as Timestamp?;
              if (aTime != null && bTime != null) {
                return bTime.compareTo(aTime);
              }
              return 0;
            });

            // Apply date filters
            groupTasks = _applyFilters(groupTasks);

            // Group by completion status
            final incompleteGroupTasks = groupTasks.where((t) => !t.isCompleted).toList();
            final completedGroupTasks = groupTasks.where((t) => t.isCompleted).toList();
            final incompleteStandalone =
                standaloneTasks.where((t) => t['completed'] == false).toList();
            final completedStandalone =
                standaloneTasks.where((t) => t['completed'] == true).toList();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Standalone Tasks Section
                if (incompleteStandalone.isNotEmpty || completedStandalone.isNotEmpty) ...[
                  _buildSectionHeader(
                    'المهام السريعة',
                    incompleteStandalone.length,
                    Icons.flash_on_rounded,
                    const Color(0xFFFFB800),
                  ),
                  const SizedBox(height: 12),
                  ...incompleteStandalone
                      .asMap()
                      .entries
                      .map((entry) =>
                          _buildStandaloneTaskCard(context, entry.value, entry.key))
                      .toList(),
                  if (completedStandalone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...completedStandalone
                        .asMap()
                        .entries
                        .map((entry) =>
                            _buildStandaloneTaskCard(context, entry.value, entry.key))
                        .toList(),
                  ],
                  const SizedBox(height: 24),
                ],

                // Group Tasks - Incomplete
                if (incompleteGroupTasks.isNotEmpty) ...[
                  _buildSectionHeader(
                    'مهام المجموعات',
                    incompleteGroupTasks.length,
                    Icons.pending_actions,
                    AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  ...incompleteGroupTasks
                      .asMap()
                      .entries
                      .map((entry) => _buildTaskCard(context, entry.value, entry.key))
                      .toList(),
                  const SizedBox(height: 24),
                ],

                // Group Tasks - Completed
                if (completedGroupTasks.isNotEmpty) ...[
                  _buildSectionHeader(
                    'المهام المنجزة',
                    completedGroupTasks.length,
                    Icons.check_circle,
                    AppTheme.successColor,
                  ),
                  const SizedBox(height: 12),
                  ...completedGroupTasks
                      .asMap()
                      .entries
                      .map((entry) => _buildTaskCard(context, entry.value, entry.key))
                      .toList(),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getTasksStream() {
    // Get all notes without filters
    return FirebaseFirestore.instance.collection('notes').snapshots();
  }

  Stream<QuerySnapshot> _getStandaloneTasksStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notes')
        .where('type', isEqualTo: 'task')
        .snapshots();
  }

  List<TaskModel> _applyFilters(List<TaskModel> tasks) {
    var filteredTasks = tasks;

    // Apply date filter
    switch (selectedFilter) {
      case 'today':
        filteredTasks = tasks.where((t) => t.isDueToday).toList();
        break;
      case 'week':
        filteredTasks = tasks.where((t) => t.isDueThisWeek).toList();
        break;
      case 'overdue':
        filteredTasks = tasks.where((t) => t.isOverdue).toList();
        break;
    }

    return filteredTasks;
  }

  Widget _buildSectionHeader(
      String title, int count, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.isCompleted
              ? AppTheme.successColor.withOpacity(0.3)
              : task.isOverdue
                  ? Colors.red.withOpacity(0.3)
                  : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildTaskCheckbox(context, task),
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: task.isCompleted
                      ? AppTheme.textLightColor
                      : AppTheme.textPrimaryColor,
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
            // Priority Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(int.parse(
                        task.priorityColor.replaceFirst('#', '0xFF')))
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(task.priorityIcon, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    task.priority == 'urgent'
                        ? 'عاجل'
                        : task.priority == 'high'
                            ? 'عالي'
                            : task.priority == 'medium'
                                ? 'متوسط'
                                : 'منخفض',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null) ...[
              const SizedBox(height: 6),
              Text(
                task.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                // Due Date
                if (task.dueDate != null) ...[
                  Icon(
                    task.isOverdue
                        ? Icons.error
                        : task.isDueToday
                            ? Icons.today
                            : Icons.calendar_today,
                    size: 14,
                    color: task.isOverdue
                        ? Colors.red
                        : task.isDueToday
                            ? AppTheme.accentColor
                            : AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: task.isOverdue
                          ? Colors.red
                          : AppTheme.textSecondaryColor,
                      fontWeight:
                          task.isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
                // Group Info
                const Spacer(),
                StreamBuilder<DocumentSnapshot>(
                  stream: task.groupId != null
                      ? FirebaseFirestore.instance
                          .collection('task_groups')
                          .doc(task.groupId)
                          .snapshots()
                      : null,
                  builder: (context, groupSnapshot) {
                    if (!groupSnapshot.hasData) return const SizedBox.shrink();
                    
                    final groupData =
                        groupSnapshot.data!.data() as Map<String, dynamic>?;
                    if (groupData == null) return const SizedBox.shrink();

                    return Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            groupData['icon'] ?? '📋',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            groupData['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showTaskDetails(context, task),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 50))
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildTaskCheckbox(BuildContext context, TaskModel task) {
    return InkWell(
      onTap: () => _toggleTaskCompletion(context, task),
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
    );
  }

  Future<void> _toggleTaskCompletion(
      BuildContext context, TaskModel task) async {
    final newStatus = !task.isCompleted;
    final now = DateTime.now();

    try {
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(task.id)
          .update({
        'isCompleted': newStatus,
        'completedAt': newStatus ? Timestamp.fromDate(now) : null,
      });

      // Update group stats if task belongs to a group
      if (task.groupId != null) {
        final groupRef = FirebaseFirestore.instance
            .collection('task_groups')
            .doc(task.groupId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final groupDoc = await transaction.get(groupRef);
          if (!groupDoc.exists) return;

          final currentCompleted = groupDoc.data()?['completedTasks'] ?? 0;

          transaction.update(groupRef, {
            'completedTasks':
                newStatus ? currentCompleted + 1 : currentCompleted - 1,
            'updatedAt': Timestamp.fromDate(now),
          });
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Widget _buildStandaloneTaskCard(
      BuildContext context, Map<String, dynamic> task, int index) {
    final title = task['title'] ?? '';
    final priority = task['priority'] ?? 'medium';
    final isCompleted = task['completed'] ?? false;
    final taskId = task['id'] ?? '';

    String priorityIcon = '🟡';
    String priorityLabel = 'متوسط';
    switch (priority) {
      case 'urgent':
        priorityIcon = '🔴';
        priorityLabel = 'عاجل';
        break;
      case 'high':
        priorityIcon = '🟠';
        priorityLabel = 'عالي';
        break;
      case 'low':
        priorityIcon = '🟢';
        priorityLabel = 'منخفض';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppTheme.successColor.withOpacity(0.3)
              : const Color(0xFFFFB800).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: InkWell(
          onTap: () =>
              _toggleStandaloneTaskCompletion(context, taskId, isCompleted),
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
        title: Row(
          children: [
            const Text(
              '⚡',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? AppTheme.textLightColor
                      : AppTheme.textPrimaryColor,
                  decoration: isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(priorityIcon, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    priorityLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.flash_on_rounded,
                        size: 12, color: Color(0xFFFFB800)),
                    SizedBox(width: 4),
                    Text(
                      'مهمة سريعة',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFFB800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        onTap: () => _showStandaloneTaskDetails(context, task),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 50))
        .slideX(begin: 0.2, end: 0);
  }

  Future<void> _toggleStandaloneTaskCompletion(
      BuildContext context, String taskId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(taskId)
          .update({
        'completed': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showStandaloneTaskDetails(
      BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('⚡', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'مهمة سريعة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('notes')
                    .doc(task['id'])
                    .delete();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف المهمة')),
                  );
                }
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task['title'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
          ],
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

  void _showTaskDetails(BuildContext context, TaskModel task) {
    if (task.groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذه المهمة غير مرتبطة بمجموعة')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(
        groupId: task.groupId!,
        task: task,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 100,
            color: AppTheme.textLightColor,
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد مهام',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'أنشئ مجموعة وابدأ بإضافة المهام',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textLightColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppTheme.textLightColor,
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'جرب فلتر مختلف',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textLightColor,
            ),
          ),
        ],
      ),
    );
  }
}
