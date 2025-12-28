import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../calendar/appointment_model.dart';
import '../calendar/add_appointment_dialog.dart';

/// واجهة المواعيد المحسّنة
/// تعرض المواعيد بتصميم حديث ومنظم
class AppointmentsView extends StatefulWidget {
  const AppointmentsView({super.key});

  @override
  State<AppointmentsView> createState() => _AppointmentsViewState();
}

class _AppointmentsViewState extends State<AppointmentsView>
    with SingleTickerProviderStateMixin {
  String _filter = 'upcoming';
  DateTime _selectedDate = DateTime.now();
  late AnimationController _animController;

  // ألوان التصميم
  static const _primaryColor = Color(0xFF6366F1);
  static const _accentColor = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildLoginRequired();
    }

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _buildHeader(),
          _buildQuickDateSelector(),
          _buildFilterChips(),
          Expanded(child: _buildAppointmentsList(user.uid)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Header
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryColor, _primaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_month, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المواعيد',
                  style: GoogleFonts.tajawal(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  DateFormat('EEEE، d MMMM', 'ar').format(DateTime.now()),
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _showAddDialog(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: _primaryColor, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Quick Date Selector
  // ═══════════════════════════════════════════════════════════
  Widget _buildQuickDateSelector() {
    final today = DateTime.now();
    final dates = List.generate(7, (i) => today.add(Duration(days: i - 1)));

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, today);

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 55,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: _primaryColor, width: 2)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                        )
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE', 'ar').format(date),
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (isToday)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : _primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Filter Chips
  // ═══════════════════════════════════════════════════════════
  Widget _buildFilterChips() {
    final filters = [
      {'key': 'upcoming', 'label': 'القادمة', 'icon': Icons.upcoming},
      {'key': 'today', 'label': 'اليوم', 'icon': Icons.today},
      {'key': 'past', 'label': 'السابقة', 'icon': Icons.history},
      {'key': 'all', 'label': 'الكل', 'icon': Icons.list_alt},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _filter == f['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f['label'] as String,
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.white,
                selectedColor: _primaryColor,
                checkmarkColor: Colors.white,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? _primaryColor : Colors.grey.shade300,
                  ),
                ),
                onSelected: (_) => setState(() => _filter = f['key'] as String),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Appointments List
  // ═══════════════════════════════════════════════════════════
  Widget _buildAppointmentsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _primaryColor));
        }

        if (snapshot.hasError) {
          return _buildError(snapshot.error.toString());
        }

        final docs = snapshot.data?.docs ?? [];
        final appointments = docs
            .map((d) => AppointmentModel.fromFirestore(d))
            .where((a) => _matchesFilter(a))
            .toList();

        // ترتيب حسب التاريخ
        appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));

        if (appointments.isEmpty) {
          return _buildEmptyState();
        }

        // تجميع حسب التاريخ
        final grouped = _groupByDate(appointments);

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final entry = grouped.entries.elementAt(index);
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 400),
                child: SlideAnimation(
                  verticalOffset: 50,
                  child: FadeInAnimation(
                    child: _buildDateGroup(entry.key, entry.value),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDateGroup(String dateLabel, List<AppointmentModel> appointments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
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
              const SizedBox(width: 8),
              Text(
                '${appointments.length} موعد',
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const Spacer(),
              Container(
                height: 1,
                width: 60,
                color: Colors.grey.shade200,
              ),
            ],
          ),
        ),
        // Appointments
        ...appointments.map((apt) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AppointmentCard(
                appointment: apt,
                onEdit: () => _showAddDialog(apt),
                onDelete: () => _deleteAppointment(apt),
              ),
            )),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Empty & Error States
  // ═══════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    final messages = {
      'upcoming': ('لا توجد مواعيد قادمة', 'أضف موعداً جديداً للبدء'),
      'today': ('لا توجد مواعيد اليوم', 'استمتع بيومك!'),
      'past': ('لا توجد مواعيد سابقة', 'سجّل مواعيدك المهمة'),
      'all': ('لا توجد مواعيد', 'ابدأ بإضافة موعدك الأول'),
    };

    final msg = messages[_filter]!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available,
              size: 48,
              color: _primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            msg.$1,
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            msg.$2,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(),
            icon: const Icon(Icons.add),
            label: Text('إضافة موعد', style: GoogleFonts.tajawal()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('حدث خطأ', style: GoogleFonts.tajawal(fontSize: 18)),
          Text(error, style: GoogleFonts.tajawal(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'يرجى تسجيل الدخول',
            style: GoogleFonts.tajawal(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Helper Methods
  // ═══════════════════════════════════════════════════════════
  Stream<QuerySnapshot> _getStream(String userId) {
    var query = FirebaseFirestore.instance
        .collection('appointments')
        .where('userId', isEqualTo: userId);

    final now = Timestamp.fromDate(DateTime.now());

    if (_filter == 'upcoming') {
      query = query.where('dateTime', isGreaterThanOrEqualTo: now);
    } else if (_filter == 'past') {
      query = query.where('dateTime', isLessThan: now);
    }

    return query.orderBy('dateTime', descending: _filter == 'past').snapshots();
  }

  bool _matchesFilter(AppointmentModel apt) {
    if (_filter == 'today') {
      return apt.isToday;
    }
    return true;
  }

  Map<String, List<AppointmentModel>> _groupByDate(List<AppointmentModel> list) {
    final Map<String, List<AppointmentModel>> grouped = {};

    for (final apt in list) {
      final label = _getDateLabel(apt.dateTime);
      grouped.putIfAbsent(label, () => []).add(apt);
    }

    return grouped;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final diff = dateOnly.difference(today).inDays;

    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'غداً';
    if (diff == -1) return 'أمس';
    if (diff > 1 && diff <= 7) return 'خلال $diff أيام';
    if (diff < -1 && diff >= -7) return 'منذ ${-diff} أيام';

    return DateFormat('d MMMM yyyy', 'ar').format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showAddDialog([AppointmentModel? apt]) {
    showDialog(
      context: context,
      builder: (_) => AddAppointmentDialog(appointment: apt),
    );
  }

  Future<void> _deleteAppointment(AppointmentModel apt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف الموعد', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
        content: Text(
          'هل تريد حذف "${apt.title}"؟',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('حذف', style: GoogleFonts.tajawal(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(apt.id)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حذف الموعد', style: GoogleFonts.tajawal()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e')),
          );
        }
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Appointment Card Widget
// ═══════════════════════════════════════════════════════════════════════════
class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AppointmentCard({
    required this.appointment,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type = AppointmentType.fromString(appointment.type);
    final color = _getColor(appointment.type);
    final isPast = appointment.isPast;
    final isUpcoming = appointment.isUpcoming;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          right: BorderSide(color: color, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(type.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),

                    // Title & Type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.title,
                            style: GoogleFonts.tajawal(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPast ? Colors.grey : Colors.black87,
                              decoration: isPast ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            type.label,
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Badge
                    if (isUpcoming)
                      _StatusBadge(label: 'قريب', color: const Color(0xFFF59E0B))
                    else if (appointment.isToday && !isPast)
                      _StatusBadge(label: 'اليوم', color: const Color(0xFF10B981))
                    else if (isPast)
                      _StatusBadge(label: 'منتهي', color: Colors.grey),
                  ],
                ),

                // Description
                if (appointment.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      appointment.description,
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Date, Time, Location Row
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today,
                      text: DateFormat('d MMM', 'ar').format(appointment.dateTime),
                    ),
                    _InfoChip(
                      icon: Icons.access_time,
                      text: DateFormat('h:mm a', 'ar').format(appointment.dateTime),
                    ),
                    if (appointment.location.isNotEmpty)
                      _InfoChip(
                        icon: Icons.location_on_outlined,
                        text: appointment.location,
                      ),
                  ],
                ),

                // Actions
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text('تعديل', style: GoogleFonts.tajawal()),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text('حذف', style: GoogleFonts.tajawal()),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColor(String type) {
    switch (type) {
      case 'meeting':
        return const Color(0xFF3B82F6);
      case 'doctor':
        return const Color(0xFFEF4444);
      case 'personal':
        return const Color(0xFF10B981);
      case 'work':
        return const Color(0xFFF59E0B);
      case 'event':
        return const Color(0xFF8B5CF6);
      case 'reminder':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF6366F1);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Helper Widgets
// ═══════════════════════════════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.tajawal(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.tajawal(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
