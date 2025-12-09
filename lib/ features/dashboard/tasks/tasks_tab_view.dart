import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/task_model.dart';
import '../../../core/models/task_group.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'task_group_card.dart';
import 'create_task_group_dialog.dart';

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

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header with filters
          _buildHeader(),
          
          // Tab Bar
          _buildTabBar(),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGroupsView(),
                _buildAllTasksView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'المهام',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            
            // Stats
            _buildTaskStats(),
            
            const SizedBox(height: 16),
            
            // Filters
            _buildFilters(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStats() {
    final userId = _userId;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notes')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'task')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final tasks = snapshot.data!.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList();
        
        final totalTasks = tasks.length;
        final completedTasks = tasks.where((t) => t.isCompleted).length;
        final overdueTasks = tasks.where((t) => t.isOverdue).length;
        final todayTasks = tasks.where((t) => t.isDueToday).length;

        return Row(
          children: [
            _buildStatItem('الكل', totalTasks.toString(), Icons.task_alt),
            const SizedBox(width: 16),
            _buildStatItem('منجز', completedTasks.toString(), Icons.check_circle),
            const SizedBox(width: 16),
            _buildStatItem('اليوم', todayTasks.toString(), Icons.today),
            if (overdueTasks > 0) ...[
              const SizedBox(width: 16),
              _buildStatItem('متأخر', overdueTasks.toString(), Icons.warning,
                  color: Colors.red.shade300),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon,
      {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('الكل', 'all'),
          _buildFilterChip('اليوم', 'today'),
          _buildFilterChip('هذا الأسبوع', 'week'),
          _buildFilterChip('متأخر', 'overdue'),
          const SizedBox(width: 8),
          Container(width: 1, height: 30, color: Colors.white30),
          const SizedBox(width: 8),
          _buildPriorityChip('🔴 عاجل', 'urgent'),
          _buildPriorityChip('🟠 عالي', 'high'),
          _buildPriorityChip('🟡 متوسط', 'medium'),
          _buildPriorityChip('🟢 منخفض', 'low'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filter;
            if (filter != 'all') _selectedPriority = 'all';
          });
        },
        backgroundColor: Colors.white.withOpacity(0.2),
        selectedColor: Colors.white.withOpacity(0.3),
        labelStyle: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Colors.white,
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildPriorityChip(String label, String priority) {
    final isSelected = _selectedPriority == priority;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedPriority = selected ? priority : 'all';
            if (priority != 'all') _selectedFilter = 'all';
          });
        },
        backgroundColor: Colors.white.withOpacity(0.2),
        selectedColor: Colors.white.withOpacity(0.3),
        labelStyle: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Colors.white,
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(15),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondaryColor,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.folder_outlined),
            text: 'المجموعات',
          ),
          Tab(
            icon: Icon(Icons.list),
            text: 'كل المهام',
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsView() {
    final userId = _userId;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('task_groups')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyGroupsState();
        }

        final groups = snapshot.data!.docs
            .map((doc) => TaskGroup.fromFirestore(doc))
            .toList();

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
  }

  Widget _buildEmptyGroupsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 100,
            color: AppTheme.textLightColor,
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد مجموعات مهام',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'أنشئ مجموعة لتنظيم مهامك',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textLightColor,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _showCreateGroupDialog,
            icon: const Icon(Icons.add),
            label: const Text('إنشاء مجموعة'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
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
    // This will show filtered tasks
    return const Center(
      child: Text('All Tasks View - Coming Soon'),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showCreateGroupDialog,
      backgroundColor: AppTheme.primaryColor,
      icon: const Icon(Icons.add),
      label: const Text('مجموعة جديدة'),
    );
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateTaskGroupDialog(),
    );
  }
}
