import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';

/// حوار إضافة/تعديل موعد محسّن
class AddAppointmentDialog extends StatefulWidget {
  final AppointmentModel? appointment;
  final DateTime? initialDate;

  const AddAppointmentDialog({
    super.key, 
    this.appointment,
    this.initialDate,
  });

  @override
  State<AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  TimeOfDay? _endTime;
  late AppointmentType _selectedType;
  late AppointmentPriority _selectedPriority;
  bool _hasReminder = false;
  int _reminderMinutes = 30;
  bool _isLoading = false;
  late TabController _tabController;

  bool get _isEditing => widget.appointment != null;

  // الألوان
  static const _primaryColor = Color(0xFF6366F1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    if (_isEditing) {
      final apt = widget.appointment!;
      _titleController.text = apt.title;
      _descriptionController.text = apt.description;
      _locationController.text = apt.location;
      _notesController.text = apt.notes;
      _selectedDate = apt.dateTime;
      _startTime = TimeOfDay.fromDateTime(apt.dateTime);
      if (apt.endTime != null) {
        _endTime = TimeOfDay.fromDateTime(apt.endTime!);
      }
      _selectedType = AppointmentType.fromString(apt.type);
      _selectedPriority = AppointmentPriority.fromString(apt.priority);
      _hasReminder = apt.hasReminder;
      _reminderMinutes = apt.reminderMinutes ?? 30;
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
      _startTime = TimeOfDay.now();
      _selectedType = AppointmentType.meeting;
      _selectedPriority = AppointmentPriority.medium;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildTabs(),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(),
                  _buildDetailsTab(),
                ],
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _selectedType.color,
            _selectedType.color.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _isEditing ? Icons.edit_calendar : Icons.add_circle_outline,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'تعديل الموعد' : 'موعد جديد',
                  style: GoogleFonts.tajawal(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  DateFormat('EEEE، d MMMM', 'ar').format(_selectedDate),
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.grey.shade50,
      child: TabBar(
        controller: _tabController,
        labelColor: _primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _primaryColor,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'المعلومات الأساسية', icon: Icon(Icons.info_outline, size: 20)),
          Tab(text: 'تفاصيل إضافية', icon: Icon(Icons.settings, size: 20)),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            _buildSectionTitle('العنوان', Icons.title),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style: GoogleFonts.tajawal(fontSize: 16),
              decoration: _inputDecoration('أدخل عنوان الموعد', Icons.event),
              validator: (v) => v?.isEmpty ?? true ? 'العنوان مطلوب' : null,
            ),
            
            const SizedBox(height: 20),
            
            // نوع الموعد
            _buildSectionTitle('نوع الموعد', Icons.category),
            const SizedBox(height: 8),
            _buildTypeSelector(),
            
            const SizedBox(height: 20),
            
            // التاريخ والوقت
            _buildSectionTitle('التاريخ والوقت', Icons.schedule),
            const SizedBox(height: 8),
            _buildDateTimeSection(),
            
            const SizedBox(height: 20),
            
            // الموقع
            _buildSectionTitle('الموقع', Icons.location_on),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationController,
              style: GoogleFonts.tajawal(),
              decoration: _inputDecoration('أضف الموقع (اختياري)', Icons.location_on_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الأولوية
          _buildSectionTitle('الأولوية', Icons.flag),
          const SizedBox(height: 8),
          _buildPrioritySelector(),
          
          const SizedBox(height: 20),
          
          // التذكير
          _buildSectionTitle('التذكير', Icons.notifications),
          const SizedBox(height: 8),
          _buildReminderSection(),
          
          const SizedBox(height: 20),
          
          // الوصف
          _buildSectionTitle('الوصف', Icons.description),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            style: GoogleFonts.tajawal(),
            maxLines: 3,
            decoration: _inputDecoration('أضف وصفاً للموعد (اختياري)', Icons.description_outlined),
          ),
          
          const SizedBox(height: 20),
          
          // ملاحظات
          _buildSectionTitle('ملاحظات', Icons.note),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            style: GoogleFonts.tajawal(),
            maxLines: 2,
            decoration: _inputDecoration('أضف ملاحظات (اختياري)', Icons.note_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.tajawal(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.tajawal(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: _primaryColor),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppointmentType.values
          .where((t) => t != AppointmentType.general)
          .map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? type.color : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? type.color : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: type.color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type.icon,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  type.label,
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      children: [
        // التاريخ
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.calendar_today, size: 20, color: _primaryColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التاريخ',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('EEEE، d MMMM yyyy', 'ar').format(_selectedDate),
                        style: GoogleFonts.tajawal(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // الوقت
        Row(
          children: [
            Expanded(child: _buildTimePicker('من', _startTime, (t) => setState(() => _startTime = t))),
            const SizedBox(width: 12),
            Expanded(child: _buildTimePicker('إلى', _endTime, (t) => setState(() => _endTime = t), isOptional: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, Function(TimeOfDay) onSelect, {bool isOptional = false}) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: _primaryColor),
            ),
            child: child!,
          ),
        );
        if (picked != null) onSelect(picked);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 20, color: _primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    time?.format(context) ?? (isOptional ? 'اختياري' : '--:--'),
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: time != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: AppointmentPriority.values.map((priority) {
        final isSelected = _selectedPriority == priority;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPriority = priority),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(left: priority != AppointmentPriority.low ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? priority.color : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? priority.color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    priority.icon,
                    color: isSelected ? Colors.white : priority.color,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priority.label,
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReminderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _hasReminder ? Icons.notifications_active : Icons.notifications_off,
                color: _hasReminder ? _primaryColor : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'تفعيل التذكير',
                  style: GoogleFonts.tajawal(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _hasReminder,
                onChanged: (v) => setState(() => _hasReminder = v),
                activeTrackColor: _primaryColor.withValues(alpha: 0.5),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _primaryColor;
                  }
                  return Colors.grey.shade400;
                }),
              ),
            ],
          ),
          if (_hasReminder) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'التذكير قبل:',
                  style: GoogleFonts.tajawal(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: [15, 30, 60, 120].map((min) {
                      final isSelected = _reminderMinutes == min;
                      return ChoiceChip(
                        label: Text(
                          min < 60 ? '$min د' : '${min ~/ 60} س',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: _primaryColor,
                        onSelected: (_) => setState(() => _reminderMinutes = min),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text('إلغاء', style: GoogleFonts.tajawal(fontSize: 15)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedType.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isEditing ? Icons.check : Icons.add, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isEditing ? 'حفظ التغييرات' : 'إضافة الموعد',
                          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: _primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      DateTime? endDateTime;
      if (_endTime != null) {
        endDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      final data = {
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'notes': _notesController.text.trim(),
        'type': _selectedType.value,
        'priority': _selectedPriority.value,
        'dateTime': Timestamp.fromDate(startDateTime),
        'endTime': endDateTime != null ? Timestamp.fromDate(endDateTime) : null,
        'status': 'pending',
        'hasReminder': _hasReminder,
        'reminderMinutes': _hasReminder ? _reminderMinutes : null,
        'attendees': <String>[],
      };

      if (_isEditing) {
        data['updatedAt'] = Timestamp.now();
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(widget.appointment!.id)
            .update(data);
      } else {
        data['createdAt'] = Timestamp.now();
        await FirebaseFirestore.instance.collection('appointments').add(data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _isEditing ? Icons.check_circle : Icons.add_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  _isEditing ? 'تم تحديث الموعد بنجاح' : 'تم إضافة الموعد بنجاح',
                  style: GoogleFonts.tajawal(),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e', style: GoogleFonts.tajawal()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
