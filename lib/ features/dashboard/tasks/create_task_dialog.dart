import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/task_model.dart';
import '../../../core/theme/app_theme.dart';

/// Dialog for creating or editing tasks
/// 
/// Co-authored-by: ALi Sameh
/// Co-authored-by: Mahmoud Abdelrauf
class CreateTaskDialog extends StatefulWidget {
  final String groupId;
  final TaskModel? task; // null for new, non-null for edit

  const CreateTaskDialog({
    Key? key,
    required this.groupId,
    this.task,
  }) : super(key: key);

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;

  String _selectedPriority = 'medium';
  DateTime? _selectedDueDate;
  List<String> _tags = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _priorities = [
    {'value': 'low', 'label': 'منخفض', 'icon': '🟢', 'color': '#58CC02'},
    {'value': 'medium', 'label': 'متوسط', 'icon': '🟡', 'color': '#FFD900'},
    {'value': 'high', 'label': 'عالي', 'icon': '🟠', 'color': '#FF9500'},
    {'value': 'urgent', 'label': 'عاجل', 'icon': '🔴', 'color': '#FF3B30'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _notesController = TextEditingController(text: widget.task?.notes ?? '');

    if (widget.task != null) {
      _selectedPriority = widget.task!.priority;
      _selectedDueDate = widget.task!.dueDate;
      _tags = List.from(widget.task!.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.task != null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.task_alt,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing ? 'تعديل المهمة' : 'مهمة جديدة',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'أضف تفاصيل المهمة',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'عنوان المهمة *',
                      hintText: 'مثال: إنهاء التقرير الشهري',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال عنوان المهمة';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'الوصف (اختياري)',
                      hintText: 'تفاصيل المهمة',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                    ),
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 24),

                  // Priority Selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الأولوية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: _priorities.map((priority) {
                          final isSelected =
                              priority['value'] == _selectedPriority;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedPriority = priority['value'];
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Color(int.parse(priority['color']
                                                .replaceFirst('#', '0xFF')))
                                            .withOpacity(0.2)
                                        : AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Color(int.parse(priority['color']
                                              .replaceFirst('#', '0xFF')))
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        priority['icon'],
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        priority['label'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Due Date Picker
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تاريخ الاستحقاق',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _selectDueDate,
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: AppTheme.textLightColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDueDate == null
                                      ? 'اختر تاريخ الاستحقاق'
                                      : '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _selectedDueDate == null
                                        ? AppTheme.textSecondaryColor
                                        : AppTheme.textPrimaryColor,
                                  ),
                                ),
                              ),
                              if (_selectedDueDate != null)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDueDate = null;
                                    });
                                  },
                                  icon: const Icon(Icons.clear, size: 20),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Notes Field
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'ملاحظات إضافية',
                      hintText: 'أي تفاصيل أخرى',
                      prefixIcon: const Icon(Icons.note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveTask,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isEditing ? 'حفظ التعديلات' : 'إضافة المهمة',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'priority': _selectedPriority,
        'dueDate':
            _selectedDueDate != null ? Timestamp.fromDate(_selectedDueDate!) : null,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'tags': _tags,
        'userId': userId,
        'groupId': widget.groupId,
        'type': 'task',
      };

      if (_isEditing) {
        // Update existing task
        await FirebaseFirestore.instance
            .collection('notes')
            .doc(widget.task!.id)
            .update(data);
      } else {
        // Create new task
        data['isCompleted'] = false;
        data['createdAt'] = Timestamp.fromDate(now);
        data['sortOrder'] = 0;

        await FirebaseFirestore.instance.collection('notes').add(data);

        // Update group stats
        final groupRef = FirebaseFirestore.instance
            .collection('task_groups')
            .doc(widget.groupId);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final groupDoc = await transaction.get(groupRef);
          final currentTotal = groupDoc.data()?['totalTasks'] ?? 0;

          transaction.update(groupRef, {
            'totalTasks': currentTotal + 1,
            'updatedAt': Timestamp.fromDate(now),
          });
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'تم تحديث المهمة بنجاح'
                : 'تم إضافة المهمة بنجاح'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
