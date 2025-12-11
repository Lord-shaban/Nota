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
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _collectAllTasks(groupSnapshot, standaloneSnapshot, userId),
                  builder: (context, tasksFuture) {
                    final tasksCount = tasksFuture.hasData ? tasksFuture.data!.length : 0;
                    
                    return Row(
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
                          style: GoogleFonts.tajawal(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (tasksCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF58CC02),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$tasksCount',
                              style: GoogleFonts.tajawal(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        TextButton(
                          onPressed: widget.onViewAll,
                          child: Text(
                            'عرض الكل',
                            style: GoogleFonts.tajawal(
                              color: const Color(0xFF58CC02),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
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

                    // Show all tasks instead of limiting to 5
                    return Column(
                      children: [
                        ...allTasks
                            .map((taskData) => taskData['isStandalone'] == true
                                ? _buildStandaloneTaskCard(context, taskData)
                                : _buildTaskCard(context, taskData))
                            .toList(),
                        const SizedBox(height: 12),
                        _buildAddTaskButton(userId),
                      ],
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
              style: GoogleFonts.tajawal(
                color: const Color(0xFF1F2937),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ بإضافة مهامك من الزر أدناه',
              style: GoogleFonts.tajawal(
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
                style: GoogleFonts.tajawal(
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

  Widget _buildAddTaskButton(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(userId)
          .collection('taskGroups')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // If no groups, show quick task button only
          return InkWell(
            onTap: () => _showQuickTaskDialog(context, userId),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFB800).withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFFFFB800),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'إضافة مهمة سريعة',
                    style: GoogleFonts.tajawal(
                      color: const Color(0xFFFFB800),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // If groups exist, show options menu
        return InkWell(
          onTap: () => _showAddTaskOptions(context, userId, snapshot.data!.docs),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF58CC02), Color(0xFF45A801)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF58CC02).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_task,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'إضافة مهمة جديدة',
                  style: GoogleFonts.tajawal(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddTaskOptions(BuildContext context, String userId, List<QueryDocumentSnapshot> groups) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'إضافة مهمة جديدة',
              style: GoogleFonts.tajawal(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _buildQuickActionButton(
              icon: Icons.flash_on_rounded,
              label: 'مهمة سريعة ⚡',
              color: const Color(0xFFFFB800),
              onTap: () {
                Navigator.pop(context);
                _showQuickTaskDialog(context, userId);
              },
            ),
            const SizedBox(height: 12),
            ...groups.map((groupDoc) {
              final groupData = TaskGroup.fromFirestore(groupDoc);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildQuickActionButton(
                  icon: Icons.folder,
                  label: '${groupData.icon} ${groupData.title}',
                  color: Color(int.parse(groupData.color.replaceFirst('#', '0xFF'))),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddToGroupDialog(context, groupDoc.id);
                  },
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  void _showQuickTaskDialog(BuildContext context, String userId) {
    final titleController = TextEditingController();
    String selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'مهمة سريعة',
                style: GoogleFonts.tajawal(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'اكتب عنوان المهمة...',
                  hintStyle: GoogleFonts.tajawal(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: GoogleFonts.tajawal(),
              ),
              const SizedBox(height: 16),
              Text(
                'الأولوية',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildPriorityChip('urgent', '🔴 عاجل', selectedPriority, (p) {
                    setState(() => selectedPriority = p);
                  }),
                  _buildPriorityChip('high', '🟠 عالي', selectedPriority, (p) {
                    setState(() => selectedPriority = p);
                  }),
                  _buildPriorityChip('medium', '🟡 متوسط', selectedPriority, (p) {
                    setState(() => selectedPriority = p);
                  }),
                  _buildPriorityChip('low', '🟢 منخفض', selectedPriority, (p) {
                    setState(() => selectedPriority = p);
                  }),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.tajawal()),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                await _createStandaloneTask(userId, titleController.text.trim(), selectedPriority);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB800),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('إضافة', style: GoogleFonts.tajawal()),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToGroupDialog(BuildContext context, String groupId) {
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(
        groupId: groupId,
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label, String selected, Function(String) onSelect) {
    final isSelected = value == selected;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(value),
      backgroundColor: Colors.grey.shade100,
      selectedColor: const Color(0xFFFFB800).withOpacity(0.2),
      checkmarkColor: const Color(0xFFFFB800),
      labelStyle: GoogleFonts.tajawal(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Future<void> _createStandaloneTask(String userId, String title, String priority) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .add({
        'title': title,
        'type': 'task',
        'priority': priority,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة المهمة بنجاح', style: GoogleFonts.tajawal()),
            backgroundColor: const Color(0xFF58CC02),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e', style: GoogleFonts.tajawal()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          
          // Get tasks for this group from notes collection
          final tasksSnapshot = await _firestore
              .collection('notes')
              .where('type', isEqualTo: 'task')
              .where('groupId', isEqualTo: groupId)
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
          // Only add if task doesn't have groupId (standalone)
          if (data['groupId'] == null || data['groupId'] == '') {
            allTasks.add({
              'task': data,
              'taskId': doc.id,
              'groupIcon': '⚡',
              'groupTitle': 'مهمة سريعة',
              'groupColor': '#FFB800',
              'isStandalone': true,
            });
          }
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
                            style: GoogleFonts.tajawal(
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
                            style: GoogleFonts.tajawal(
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
                            style: GoogleFonts.tajawal(
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
      
      // Update task in notes collection
      await _firestore
          .collection('notes')
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
              style: GoogleFonts.tajawal(),
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
                            style: GoogleFonts.tajawal(
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
                            style: GoogleFonts.tajawal(
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
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task['content'] != null && task['content'].toString().isNotEmpty)
              Text(
                task['content'],
                style: GoogleFonts.tajawal(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق', style: GoogleFonts.tajawal()),
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
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
