import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/task_model.dart';
import '../../../core/models/task_group.dart';
import '../../../core/theme/app_theme.dart';
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(int.parse(widget.group.color.replaceFirst('#', '0xFF')))
              .withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(int.parse(widget.group.color.replaceFirst('#', '0xFF'))),
                              Color(int.parse(widget.group.color.replaceFirst('#', '0xFF'))).withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(int.parse(widget.group.color.replaceFirst('#', '0xFF')))
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.group.icon,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
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
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.textLightColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.more_horiz,
                            color: AppTheme.textSecondaryColor,
                            size: 20,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 10),
                                Text('تعديل', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                SizedBox(width: 10),
                                Text('حذف', style: TextStyle(color: Colors.red, fontSize: 14)),
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
                  
                  const SizedBox(height: 12),
                  
                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.group.completedTasks} / ${widget.group.totalTasks}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.group.isCompleted
                                  ? AppTheme.successColor.withOpacity(0.1)
                                  : AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${widget.group.completionPercentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11,
                                color: widget.group.isCompleted
                                    ? AppTheme.successColor
                                    : AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: widget.group.completionPercentage / 100,
                          backgroundColor: AppTheme.textLightColor.withOpacity(0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.group.isCompleted
                                ? AppTheme.successColor
                                : AppTheme.primaryColor,
                          ),
                          minHeight: 6,
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
    print('🔍 Loading tasks for group: ${widget.group.id}');
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notes')
          .snapshots(),
      builder: (context, snapshot) {
        print('📡 Tasks stream state: ${snapshot.connectionState}');
        print('📡 Has data: ${snapshot.hasData}');
        print('📡 Tasks count: ${snapshot.data?.docs.length ?? 0}');
        
        if (snapshot.hasError) {
          print('❌ Tasks error: ${snapshot.error}');
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          print('📭 No data from stream');
          return _buildEmptyTasksState();
        }

        // Filter tasks by groupId in code to avoid Firestore index
        final tasks = snapshot.data!.docs
            .map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>?;
                if (data != null && data['type'] == 'task' && data['groupId'] == widget.group.id) {
                  print('📝 Task doc: ${doc.id}, data: $data');
                  return TaskModel.fromFirestore(doc);
                }
              } catch (e) {
                print('⚠️ Error parsing task: $e');
              }
              return null;
            })
            .where((task) => task != null)
            .cast<TaskModel>()
            .toList();
        
        if (tasks.isEmpty) {
          print('📭 No tasks found for group ${widget.group.id}');
          return _buildEmptyTasksState();
        }
        
        // Sort by createdAt (oldest first for better UX)
        tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        print('✅ Loaded ${tasks.length} tasks');

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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: task.isCompleted
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.textLightColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: _buildTaskCheckbox(task),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
                  fontSize: 12,
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
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(int.parse(
                        task.priorityColor.replaceFirst('#', '0xFF')))
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  task.priorityIcon,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            
            // Due Date
            if (task.dueDate != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: task.isOverdue
                      ? Colors.red.withOpacity(0.1)
                      : task.isDueToday
                          ? AppTheme.accentColor.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  task.isOverdue
                      ? Icons.error_outline
                      : task.isDueToday
                          ? Icons.today
                          : Icons.calendar_today_outlined,
                  size: 14,
                  color: task.isOverdue
                      ? Colors.red
                      : task.isDueToday
                          ? AppTheme.accentColor
                          : AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ],
        ),
        onTap: () => _showTaskDetails(task),
      ),
    );
  }

  Widget _buildTaskCheckbox(TaskModel task) {
    return InkWell(
      onTap: () => _toggleTaskCompletion(task),
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

  Widget _buildAddTaskButton() {
    return InkWell(
      onTap: () => _showAddTaskDialog(),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              'إضافة مهمة',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
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
