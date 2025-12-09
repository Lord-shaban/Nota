import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/task_group.dart';
import '../../../core/models/task_model.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'create_task_dialog.dart';

/// Task Group Card with expandable tasks list
/// 
/// Co-authored-by: ALi Sameh
/// Co-authored-by: Mahmoud Abdelrauf
class TaskGroupCard extends StatefulWidget {
  final TaskGroup group;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskGroupCard({
    Key? key,
    required this.group,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  State<TaskGroupCard> createState() => _TaskGroupCardState();
}

class _TaskGroupCardState extends State<TaskGroupCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Actions
                  Row(
                    children: [
                      // Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(int.parse(
                                  widget.group.color.replaceFirst('#', '0xFF')))
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            widget.group.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      
                      // Title and Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.group.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            if (widget.group.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.group.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Menu
                      PopupMenuButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: AppTheme.textSecondaryColor,
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 12),
                                Text('تعديل'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 12),
                                Text('حذف', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') widget.onEdit?.call();
                          if (value == 'delete') widget.onDelete?.call();
                        },
                      ),
                      
                      // Expand Icon
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${widget.group.completedTasks} من ${widget.group.totalTasks}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${widget.group.completionPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: widget.group.completionPercentage / 100,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.group.isCompleted
                                ? AppTheme.successColor
                                : AppTheme.primaryColor,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Tasks List (Expanded)
          if (_isExpanded) _buildTasksList(),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notes')
          .where('type', isEqualTo: 'task')
          .where('groupId', isEqualTo: widget.group.id)
          .orderBy('sortOrder')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyTasksState();
        }

        final tasks = snapshot.data!.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList();

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ...tasks.map((task) => _buildTaskItem(task)).toList(),
              const SizedBox(height: 8),
              _buildAddTaskButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyTasksState() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.task_alt,
            size: 50,
            color: AppTheme.textLightColor,
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد مهام في هذه المجموعة',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildAddTaskButton(),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isCompleted
              ? AppTheme.successColor.withOpacity(0.3)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _buildTaskCheckbox(task),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: task.isCompleted
                ? AppTheme.textLightColor
                : AppTheme.textPrimaryColor,
            decoration: task.isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle: task.description != null
            ? Text(
                task.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Priority Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(int.parse(
                        task.priorityColor.replaceFirst('#', '0xFF')))
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                task.priorityIcon,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            
            // Due Date
            if (task.dueDate != null) ...[
              const SizedBox(width: 8),
              Icon(
                task.isOverdue
                    ? Icons.error
                    : task.isDueToday
                        ? Icons.today
                        : Icons.calendar_today,
                size: 16,
                color: task.isOverdue
                    ? Colors.red
                    : task.isDueToday
                        ? AppTheme.accentColor
                        : AppTheme.textSecondaryColor,
              ),
            ],
          ],
        ),
        onTap: () => _showTaskDetails(task),
      ),
    );
  }

  Widget _buildTaskCheckbox(TaskModel task) {
    return GestureDetector(
      onTap: () => _toggleTaskCompletion(task),
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

  Widget _buildAddTaskButton() {
    return OutlinedButton.icon(
      onPressed: () => _showAddTaskDialog(),
      icon: const Icon(Icons.add, size: 20),
      label: const Text('إضافة مهمة'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryColor,
        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Future<void> _toggleTaskCompletion(TaskModel task) async {
    final newStatus = !task.isCompleted;
    final now = DateTime.now();

    await FirebaseFirestore.instance
        .collection('notes')
        .doc(task.id)
        .update({
      'isCompleted': newStatus,
      'completedAt': newStatus ? Timestamp.fromDate(now) : null,
    });

    // Update group stats
    final groupRef = FirebaseFirestore.instance
        .collection('task_groups')
        .doc(widget.group.id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final groupDoc = await transaction.get(groupRef);
      final currentCompleted = groupDoc.data()?['completedTasks'] ?? 0;
      
      transaction.update(groupRef, {
        'completedTasks': newStatus ? currentCompleted + 1 : currentCompleted - 1,
        'updatedAt': Timestamp.fromDate(now),
      });
    });
  }

  void _showTaskDetails(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(
        groupId: widget.group.id,
        task: task,
      ),
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(groupId: widget.group.id),
    );
  }
}
