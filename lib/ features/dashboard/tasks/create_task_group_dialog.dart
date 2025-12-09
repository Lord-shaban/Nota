import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/task_group.dart';
import '../../../core/theme/app_theme.dart';

/// Dialog for creating or editing task groups
/// 
/// Co-authored-by: ALi Sameh
/// Co-authored-by: Mahmoud Abdelrauf
class CreateTaskGroupDialog extends StatefulWidget {
  final TaskGroup? group; // null for new, non-null for edit

  const CreateTaskGroupDialog({
    Key? key,
    this.group,
  }) : super(key: key);

  @override
  State<CreateTaskGroupDialog> createState() => _CreateTaskGroupDialogState();
}

class _CreateTaskGroupDialogState extends State<CreateTaskGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  String _selectedColor = '#58CC02';
  String _selectedIcon = '📋';
  bool _isLoading = false;

  final List<String> _colors = [
    '#58CC02', // Green
    '#FFD900', // Yellow
    '#FF9500', // Orange
    '#FF3B30', // Red
    '#5856D6', // Purple
    '#007AFF', // Blue
    '#34C759', // Light Green
    '#FF2D55', // Pink
    '#AF52DE', // Violet
    '#32ADE6', // Cyan
  ];

  final List<String> _icons = [
    '📋', '✅', '🎯', '💼', '🏠', '🎓', '💪', '🛒',
    '📱', '💻', '🎨', '📚', '🏃', '🍳', '🧘', '✈️',
    '💡', '🎵', '🎮', '📝', '🔧', '🎁', '🌟', '⚡',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.group?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.group?.description ?? '');
    
    if (widget.group != null) {
      _selectedColor = widget.group!.color;
      _selectedIcon = widget.group!.icon;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.group != null;

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
                        child: Text(
                          _selectedIcon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing ? 'تعديل المجموعة' : 'مجموعة جديدة',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'نظّم مهامك في مجموعات',
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
                      labelText: 'اسم المجموعة *',
                      hintText: 'مثال: مهام العمل',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال اسم المجموعة';
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
                      hintText: 'وصف قصير للمجموعة',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                    ),
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Icon Selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختر أيقونة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 120,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemCount: _icons.length,
                          itemBuilder: (context, index) {
                            final icon = _icons[index];
                            final isSelected = icon == _selectedIcon;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedIcon = icon;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Color Selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختر لون',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _colors.map((color) {
                          final isSelected = color == _selectedColor;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Color(
                                    int.parse(color.replaceFirst('#', '0xFF'))),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.textPrimaryColor
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Color(int.parse(
                                                  color.replaceFirst('#', '0xFF')))
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
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
                          onPressed: _isLoading ? null : _saveGroup,
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
                                  _isEditing ? 'حفظ التعديلات' : 'إنشاء المجموعة',
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

  Future<void> _saveGroup() async {
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
        'color': _selectedColor,
        'icon': _selectedIcon,
        'userId': userId,
        'updatedAt': Timestamp.fromDate(now),
      };

      if (_isEditing) {
        // Update existing group
        await FirebaseFirestore.instance
            .collection('task_groups')
            .doc(widget.group!.id)
            .update(data);
      } else {
        // Create new group
        data['createdAt'] = Timestamp.fromDate(now);
        data['totalTasks'] = 0;
        data['completedTasks'] = 0;
        data['taskIds'] = [];
        
        await FirebaseFirestore.instance.collection('task_groups').add(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'تم تحديث المجموعة بنجاح'
                : 'تم إنشاء المجموعة بنجاح'),
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
