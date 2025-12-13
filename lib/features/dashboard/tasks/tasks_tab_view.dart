import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/task_model.dart';
import '../../../core/models/task_group.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'task_group_card.dart';
import 'create_task_group_dialog.dart';
import 'all_tasks_view.dart';
import '../../../scripts/fix_tasks_type.dart';

/// Enhanced Tasks Tab View with Groups and Completion Tracking
/// 
/// Co-authored-by: ALi Sameh
/// Co-authored-by: Mahmoud Abdelrauf
class TasksTabView extends StatefulWidget {
  const TasksTabView({Key? key}) : super(key: key);

  @override
  State<TasksTabView> createState() => _TasksTabViewState();
}

class _TasksTabViewState extends State<TasksTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all'; // all, today, week, overdue
  String _selectedPriority = 'all'; // all, urgent, high, medium, low

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _userId {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    print('📍 TasksTabView - Current User ID: $uid');
    return uid;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F7F7),
      child: Column(
        children: [
          // Compact Header
          _buildCompactHeader(),
          
          // Filters Row
          _buildFiltersRow(),
          
          const SizedBox(height: 8),
          
          // Tab Selector
          _buildTabSelector(),
          
          // Tab Views
          Expanded(
            child: Stack(
              children: [
                TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGroupsView(),
                    _buildAllTasksView(),
                  ],
                ),
                // FAB positioned at bottom
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: _buildFloatingActionButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    final userId = _userId;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notes')
            .where('type', isEqualTo: 'task')
            .snapshots(),
        builder: (context, notesSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('notes')
                .where('type', isEqualTo: 'task')
                .snapshots(),
            builder: (context, standaloneSnapshot) {
              int totalTasks = 0;
              int completedTasks = 0;
              int todayTasks = 0;
              int overdueTasks = 0;

              // Count group tasks from notes collection
              if (notesSnapshot.hasData) {
                final groupTasks = notesSnapshot.data!.docs
                    .where((doc) {
                      final data = doc.data() as Map<String, dynamic>?;
                      return data != null && 
                             data['groupId'] != null && 
                             data['groupId'] != '';
                    })
                    .map((doc) => TaskModel.fromFirestore(doc))
                    .toList();
                
                totalTasks += groupTasks.length;
                completedTasks += groupTasks.where((t) => t.isCompleted).length;
                overdueTasks += groupTasks.where((t) => t.isOverdue).length;
                todayTasks += groupTasks.where((t) => t.isDueToday).length;
              }

              // Count standalone tasks
              if (standaloneSnapshot.hasData) {
                final standaloneTasks = standaloneSnapshot.data!.docs
                    .where((doc) {
                      final data = doc.data() as Map<String, dynamic>?;
                      return data != null && 
                             (data['groupId'] == null || data['groupId'] == '');
                    })
                    .toList();
                
                totalTasks += standaloneTasks.length;
                
                for (var doc in standaloneTasks) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['completed'] == true) completedTasks++;
                  
                  // Check if task is for today or overdue
                  final dueDate = data['dueDate'] as Timestamp?;
                  if (dueDate != null) {
                    final now = DateTime.now();
                    final taskDate = dueDate.toDate();
                    final today = DateTime(now.year, now.month, now.day);
                    final taskDay = DateTime(taskDate.year, taskDate.month, taskDate.day);
                    
                    if (taskDay.isAtSameMomentAs(today)) {
                      todayTasks++;
                    } else if (taskDay.isBefore(today) && data['completed'] != true) {
                      overdueTasks++;
                    }
                  }
                }
              }

              return _buildStatsRow(totalTasks, completedTasks, todayTasks, overdueTasks);
            },
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(int total, int completed, int today, int overdue) {
    return Row(
      children: [
        _buildStatChip('الكل', total.toString(), const Color(0xFF58CC02), Icons.check_circle_outline),
        const SizedBox(width: 8),
        _buildStatChip('منجز', completed.toString(), const Color(0xFF10B981), Icons.check_circle),
        const SizedBox(width: 8),
        _buildStatChip('اليوم', today.toString(), const Color(0xFFFFD900), Icons.today),
        if (overdue > 0) ...[
          const SizedBox(width: 8),
          _buildStatChip('متأخر', overdue.toString(), const Color(0xFFFF3B30), Icons.warning),
        ],
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCompactFilterChip('الكل', 'all', Icons.filter_list),
          _buildCompactFilterChip('اليوم', 'today', Icons.today),
          _buildCompactFilterChip('أسبوع', 'week', Icons.date_range),
          _buildCompactFilterChip('متأخر', 'overdue', Icons.warning_amber),
          const SizedBox(width: 8),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          const SizedBox(width: 8),
          _buildPriorityFilterChip('🔴', 'urgent'),
          _buildPriorityFilterChip('🟠', 'high'),
          _buildPriorityFilterChip('🟡', 'medium'),
          _buildPriorityFilterChip('🟢', 'low'),
        ],
      ),
    );
  }

  Widget _buildCompactFilterChip(String label, String filter, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filter;
            if (filter != 'all') _selectedPriority = 'all';
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF58CC02).withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF58CC02) : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
        checkmarkColor: const Color(0xFF58CC02),
        side: BorderSide(
          color: isSelected ? const Color(0xFF58CC02) : Colors.grey.shade300,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildPriorityFilterChip(String emoji, String priority) {
    final isSelected = _selectedPriority == priority;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(emoji, style: const TextStyle(fontSize: 18)),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedPriority = selected ? priority : 'all';
            if (priority != 'all') _selectedFilter = 'all';
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFFFD900).withOpacity(0.3),
        side: BorderSide(
          color: isSelected ? const Color(0xFFFFD900) : Colors.grey.shade300,
          width: 1.5,
        ),
        padding: const EdgeInsets.all(4),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF58CC02), Color(0xFF45A801)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF58CC02).withOpacity(0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade700,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        tabs: const [
          Tab(
            text: '📁  المجموعات',
            height: 44,
          ),
          Tab(
            text: '✅  كل المهام',
            height: 44,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsView() {
    final userId = _userId;
    
    print('📦 Building GroupsView for userId: $userId');
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('task_groups')
          .snapshots(),
      builder: (context, snapshot) {
        print('📡 Stream state: ${snapshot.connectionState}');
        print('📡 Has data: ${snapshot.hasData}');
        print('📡 Docs count: ${snapshot.data?.docs.length ?? 0}');
        
        if (snapshot.hasError) {
          print('❌ Error: ${snapshot.error}');
          return Center(
            child: Text('خطأ: ${snapshot.error}'),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('📭 No groups found - showing empty state');
          return _buildEmptyGroupsState();
        }

        // Filter by userId and sort in code
        final groups = snapshot.data!.docs
            .map((doc) {
              print('📄 Doc ID: ${doc.id}, Data: ${doc.data()}');
              return TaskGroup.fromFirestore(doc);
            })
            .where((group) => group.userId == userId)
            .toList();
        
        if (groups.isEmpty) {
          print('📭 No groups for this user - showing empty state');
          return _buildEmptyGroupsState();
        }
        
        // Sort by createdAt descending (newest first)
        groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        print('✅ Found ${groups.length} groups');

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            return _buildTaskGroupCard(groups[index])
                .animate()
                .fadeIn(delay: Duration(milliseconds: index * 100))
                .slideX(begin: 0.2, end: 0);
          },
        );
      },
    );
  }  Widget _buildEmptyGroupsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 80,
                color: const Color(0xFF58CC02).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد مجموعات مهام',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'ابدأ بإنشاء مجموعة لتنظيم مهامك\nوزيادة إنتاجيتك',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showCreateGroupDialog,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                'إنشاء مجموعة جديدة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58CC02),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Temporary fix button
            TextButton.icon(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔧 جاري إصلاح المهام القديمة...'),
                    duration: Duration(seconds: 2),
                  ),
                );
                await fixTasksType();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ تم إصلاح المهام بنجاح!'),
                      backgroundColor: Color(0xFF58CC02),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.build_circle_outlined, size: 18),
              label: const Text(
                'إصلاح المهام القديمة (اضغط مرة واحدة فقط)',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskGroupCard(TaskGroup group) {
    return TaskGroupCard(
      group: group,
      onEdit: () => _showEditGroupDialog(group),
      onDelete: () => _deleteGroup(group),
    );
  }

  void _showEditGroupDialog(TaskGroup group) {
    showDialog(
      context: context,
      builder: (context) => CreateTaskGroupDialog(group: group),
    );
  }

  Future<void> _deleteGroup(TaskGroup group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المجموعة'),
        content: Text('هل تريد حذف "${group.title}"؟\nسيتم حذف جميع المهام المرتبطة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('task_groups')
          .doc(group.id)
          .delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المجموعة')),
        );
      }
    }
  }

  Widget _buildAllTasksView() {
    return AllTasksView(
      userId: _userId,
      selectedFilter: _selectedFilter,
      selectedPriority: _selectedPriority,
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showQuickActionsMenu,
      backgroundColor: const Color(0xFF58CC02),
      elevation: 8,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF58CC02), Color(0xFF45A801)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF58CC02).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  void _showQuickActionsMenu() {
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'إنشاء جديد',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildQuickActionButton(
              icon: Icons.task_alt_rounded,
              title: 'مهمة سريعة',
              subtitle: 'إنشاء مهمة بدون مجموعة',
              color: const Color(0xFF58CC02),
              onTap: () {
                Navigator.pop(context);
                _showQuickTaskDialog();
              },
            ),
            const SizedBox(height: 12),
            _buildQuickActionButton(
              icon: Icons.folder_rounded,
              title: 'مجموعة مهام جديدة',
              subtitle: 'تنظيم المهام في مجموعات',
              color: const Color(0xFFFFB800),
              onTap: () {
                Navigator.pop(context);
                _showCreateGroupDialog();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
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
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickTaskDialog() {
    final titleController = TextEditingController();
    String selectedPriority = 'medium';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF58CC02).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Color(0xFF58CC02),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'مهمة سريعة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'اكتب المهمة هنا...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text(
              'الأولوية',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setState) {
                return Wrap(
                  spacing: 8,
                  children: [
                    _buildPriorityChip('urgent', '🔴 عاجل', selectedPriority, (value) {
                      setState(() => selectedPriority = value);
                    }),
                    _buildPriorityChip('high', '🟠 عالي', selectedPriority, (value) {
                      setState(() => selectedPriority = value);
                    }),
                    _buildPriorityChip('medium', '🟡 متوسط', selectedPriority, (value) {
                      setState(() => selectedPriority = value);
                    }),
                    _buildPriorityChip('low', '🟢 منخفض', selectedPriority, (value) {
                      setState(() => selectedPriority = value);
                    }),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              
              await _createStandaloneTask(
                titleController.text.trim(),
                selectedPriority,
              );
              
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إنشاء المهمة بنجاح'),
                    backgroundColor: Color(0xFF58CC02),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58CC02),
            ),
            child: const Text('إنشاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(
    String value,
    String label,
    String selectedValue,
    Function(String) onSelected,
  ) {
    final isSelected = value == selectedValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      backgroundColor: Colors.grey[100],
      selectedColor: const Color(0xFF58CC02).withOpacity(0.2),
      checkmarkColor: const Color(0xFF58CC02),
    );
  }

  Future<void> _createStandaloneTask(String title, String priority) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('notes')
          .add({
        'title': title,
        'content': '',
        'type': 'task',
        'priority': priority,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': _userId,
      });
    } catch (e) {
      print('Error creating standalone task: $e');
    }
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateTaskGroupDialog(),
    );
  }
}
