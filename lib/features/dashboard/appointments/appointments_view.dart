import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'models/appointment_model.dart';
import 'widgets/appointment_card.dart';
import 'widgets/add_appointment_dialog.dart';
import 'widgets/appointment_details_dialog.dart';

/// صفحة المواعيد المحسنة
class AppointmentsView extends StatefulWidget {
  const AppointmentsView({super.key});

  @override
  State<AppointmentsView> createState() => _AppointmentsViewState();
}

class _AppointmentsViewState extends State<AppointmentsView> with TickerProviderStateMixin {
  // المتغيرات
  String _selectedFilter = 'all';
  AppointmentType? _selectedType;
  DateTime _selectedDate = DateTime.now();
  bool _showCalendar = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // الألوان
  static const _primaryColor = Color(0xFF6366F1);
  static const _successColor = Color(0xFF10B981);
  
  // الفلاتر
  final List<Map<String, dynamic>> _filters = [
    {'id': 'all', 'label': 'الكل', 'icon': Icons.apps},
    {'id': 'today', 'label': 'اليوم', 'icon': Icons.today},
    {'id': 'upcoming', 'label': 'القادمة', 'icon': Icons.upcoming},
    {'id': 'pending', 'label': 'معلقة', 'icon': Icons.pending_outlined},
    {'id': 'completed', 'label': 'مكتملة', 'icon': Icons.check_circle_outline},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // استعلام بسيط بدون فلاتر معقدة - التصفية تتم على جانب العميل
  Stream<QuerySnapshot<Map<String, dynamic>>> _getAppointmentsStream() {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('userId', isEqualTo: _userId)
        .snapshots();
  }

  // تصفية المواعيد على جانب العميل
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterAppointments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    var filtered = docs.where((doc) {
      final data = doc.data();
      final dateTime = (data['dateTime'] as Timestamp?)?.toDate();
      if (dateTime == null) return false;

      switch (_selectedFilter) {
        case 'today':
          return dateTime.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
                 dateTime.isBefore(todayEnd);
        case 'upcoming':
          return dateTime.isAfter(now.subtract(const Duration(seconds: 1)));
        case 'pending':
          return data['status'] == 'pending' || data['status'] == null;
        case 'completed':
          return data['status'] == 'completed';
        default:
          return true;
      }
    }).toList();

    // فلتر النوع
    if (_selectedType != null) {
      filtered = filtered.where((doc) {
        final data = doc.data();
        return data['type'] == _selectedType!.name;
      }).toList();
    }

    // ترتيب حسب التاريخ
    filtered.sort((a, b) {
      final aDate = (a.data()['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
      final bDate = (b.data()['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
      return aDate.compareTo(bDate);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.grey.shade50,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // الهيدر
                _buildHeader(),
                
                // الفلاتر
                _buildFilters(),
                
                // محدد التقويم
                if (_showCalendar) _buildCalendarPicker(),
                
                // فلتر النوع
                _buildTypeFilter(),
                
                // قائمة المواعيد
                Expanded(
                  child: _buildAppointmentsList(),
                ),
              ],
            ),
          ),
        ),
        // FAB
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFAB(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // أيقونة وعنوان
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryColor, Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.calendar_month, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المواعيد',
                    style: GoogleFonts.tajawal(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _getAppointmentsStream(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      final filtered = _filterAppointments(docs);
                      return Text(
                        '${filtered.length} موعد',
                        style: GoogleFonts.tajawal(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // زر التقويم
            Material(
              color: _showCalendar ? _primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => setState(() => _showCalendar = !_showCalendar),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _showCalendar ? Icons.calendar_view_day : Icons.date_range,
                    color: _showCalendar ? _primaryColor : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter['id'];
          
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: isSelected ? _primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: isSelected ? 2 : 0,
                shadowColor: _primaryColor.withValues(alpha: 0.3),
                child: InkWell(
                  onTap: () => setState(() => _selectedFilter = filter['id']),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? null : Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          filter['icon'],
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          filter['label'],
                          style: GoogleFonts.tajawal(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarPicker() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month - 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
              Text(
                DateFormat('MMMM yyyy', 'ar').format(_selectedDate),
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = DateTime(
                      _selectedDate.year,
                      _selectedDate.month + 1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildWeekDays(),
          const SizedBox(height: 8),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildWeekDays() {
    final days = ['أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((day) => Text(
        day,
        style: GoogleFonts.tajawal(
          fontSize: 12,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w600,
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday % 7;
    
    final today = DateTime.now();
    final isSelectedToday = _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final day = index - startWeekday + 1;
        if (day < 1 || day > daysInMonth) {
          return const SizedBox();
        }
        
        final date = DateTime(_selectedDate.year, _selectedDate.month, day);
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day &&
            !isSelectedToday;

        return Material(
          color: isToday
              ? _primaryColor
              : isSelected
                  ? _primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => setState(() => _selectedDate = date),
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: Text(
                '$day',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  color: isToday ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeFilter() {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppointmentType.values.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedType == null;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Material(
                color: isSelected ? _primaryColor.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => setState(() => _selectedType = null),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _primaryColor : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.apps,
                          size: 16,
                          color: isSelected ? _primaryColor : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'كل الأنواع',
                          style: GoogleFonts.tajawal(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? _primaryColor : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          
          final type = AppointmentType.values[index - 1];
          final isSelected = _selectedType == type;
          
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Material(
              color: isSelected ? type.color.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => setState(() => _selectedType = type),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? type.color : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(type.icon, size: 16, color: type.color),
                      const SizedBox(width: 6),
                      Text(
                        type.label,
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? type.color : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentsList() {
    if (_userId == null) {
      return _buildEmptyState(
        icon: Icons.login,
        title: 'غير مسجل الدخول',
        subtitle: 'يرجى تسجيل الدخول لعرض المواعيد',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _getAppointmentsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Firestore Error: ${snapshot.error}');
          return _buildEmptyState(
            icon: Icons.error_outline,
            title: 'حدث خطأ',
            subtitle: 'لم نتمكن من تحميل المواعيد\n${snapshot.error}',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primaryColor),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        
        // تصفية المواعيد على جانب العميل
        final appointments = _filterAppointments(docs);

        if (appointments.isEmpty) {
          return _buildEmptyState(
            icon: Icons.event_available,
            title: 'لا توجد مواعيد',
            subtitle: 'اضغط على الزر + لإضافة موعد جديد',
          );
        }

        // تجميع المواعيد حسب التاريخ
        final groupedAppointments = _groupAppointments(appointments);

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: groupedAppointments.length,
            itemBuilder: (context, index) {
              final entry = groupedAppointments.entries.elementAt(index);
              final dateLabel = entry.key;
              final items = entry.value;

              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 400),
                child: SlideAnimation(
                  verticalOffset: 30,
                  child: FadeInAnimation(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // عنوان التاريخ
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  dateLabel,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Divider(
                                  color: Colors.grey.shade200,
                                  thickness: 1,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${items.length} موعد',
                                style: GoogleFonts.tajawal(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // المواعيد
                        ...items.map((doc) {
                          final appointment = AppointmentModel.fromMap(
                            doc.data(),
                            doc.id,
                          );
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppointmentCard(
                              appointment: appointment,
                              onTap: () => _showAppointmentDetails(appointment),
                              onEdit: () => _editAppointment(appointment),
                              onDelete: () => _deleteAppointment(appointment),
                              onComplete: () => _completeAppointment(appointment),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> _groupAppointments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> appointments,
  ) {
    final grouped = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateFormat = DateFormat('EEEE، d MMMM', 'ar');

    for (final doc in appointments) {
      final data = doc.data();
      final dateTime = (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
      final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

      String label;
      if (date == today) {
        label = 'اليوم';
      } else if (date == tomorrow) {
        label = 'غداً';
      } else if (date.isBefore(today)) {
        label = 'سابق';
      } else {
        label = dateFormat.format(date);
      }

      grouped.putIfAbsent(label, () => []).add(doc);
    }

    return grouped;
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: _primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.tajawal(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _addAppointment,
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add),
      label: Text(
        'إضافة موعد',
        style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
      ),
    );
  }

  // الدوال
  void _addAppointment() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddAppointmentDialog(),
    );
    
    if (result == true && mounted) {
      setState(() {}); // تحديث القائمة
    }
  }

  void _showAppointmentDetails(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AppointmentDetailsDialog(
        appointment: appointment,
        onEdit: () => _editAppointment(appointment),
        onDelete: () => _deleteAppointment(appointment),
        onComplete: () => _completeAppointment(appointment),
      ),
    );
  }

  void _editAppointment(AppointmentModel appointment) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddAppointmentDialog(appointment: appointment),
    );
    
    if (result == true && mounted) {
      setState(() {}); // تحديث القائمة
    }
  }

  void _deleteAppointment(AppointmentModel appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Text(
              'حذف الموعد',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا الموعد؟',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('حذف', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );

    if (confirmed == true && _userId != null) {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointment.id)
          .delete();
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف الموعد',
              style: GoogleFonts.tajawal(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _completeAppointment(AppointmentModel appointment) async {
    if (_userId == null) return;

    await FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointment.id)
        .update({'status': 'completed'});
        
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'تم إكمال الموعد!',
                style: GoogleFonts.tajawal(),
              ),
            ],
          ),
          backgroundColor: _successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
