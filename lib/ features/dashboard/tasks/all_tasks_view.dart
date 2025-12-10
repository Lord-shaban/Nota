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
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(context);
        }

        // Filter and sort in code to avoid Firestore index requirements
        var tasks = snapshot.data!.docs
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
        
        // Apply priority filter
        if (selectedPriority != 'all') {
          tasks = tasks.where((t) => t.priority == selectedPriority).toList();
        }
        
        // Sort by createdAt descending (newest first)
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Apply date filters
        tasks = _applyFilters(tasks);

        if (tasks.isEmpty) {
          return _buildNoResultsState(context);
        }

        // Group tasks by completion status
        final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();
        final completedTasks = tasks.where((t) => t.isCompleted).toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Incomplete Tasks
            if (incompleteTasks.isNotEmpty) ...[
              _buildSectionHeader(
                'المهام النشطة',
                incompleteTasks.length,
                Icons.pending_actions,
                AppTheme.primaryColor,
              ),
              const SizedBox(height: 12),
              ...incompleteTasks
                  .asMap()
                  .entries
                  .map((entry) => _buildTaskCard(context, entry.value, entry.key))
                  .toList(),
              const SizedBox(height: 24),
            ],

            // Completed Tasks
            if (completedTasks.isNotEmpty) ...[
              _buildSectionHeader(
                'المهام المنجزة',
                completedTasks.length,
                Icons.check_circle,
                AppTheme.successColor,
              ),
              const SizedBox(height: 12),
              ...completedTasks
                  .asMap()
                  .entries
                  .map((entry) => _buildTaskCard(context, entry.value, entry.key))
                  .toList(),
            ],
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _getTasksStream() {
    // Get all notes without filters to avoid index requirements
    return FirebaseFirestore.instance
        .collection('notes')
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
    return GestureDetector(
      onTap: () => _toggleTaskCompletion(context, task),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: task.isCompleted ? AppTheme.successColor : Colors.transparent,
          border: Border.all(
            color: task.isCompleted
                ? AppTheme.successColor
                : AppTheme.textLightColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: task.isCompleted
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 18,
              )
            : null,
      ),
    ).animate(target: task.isCompleted ? 1 : 0).scale(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
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
