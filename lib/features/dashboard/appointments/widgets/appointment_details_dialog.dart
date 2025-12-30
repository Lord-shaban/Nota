import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';

/// حوار عرض تفاصيل الموعد
class AppointmentDetailsDialog extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onComplete;

  const AppointmentDetailsDialog({
    super.key,
    required this.appointment,
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final type = AppointmentType.fromString(appointment.type);
    final priority = AppointmentPriority.fromString(appointment.priority);
    final status = AppointmentStatus.fromString(appointment.status);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context, type),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العنوان والحالة
                    _buildTitleSection(status),
                    
                    const SizedBox(height: 20),
                    
                    // التاريخ والوقت
                    _buildDateTimeSection(type.color),
                    
                    const SizedBox(height: 16),
                    
                    // الموقع
                    if (appointment.location.isNotEmpty)
                      _buildInfoCard(
                        icon: Icons.location_on,
                        title: 'الموقع',
                        content: appointment.location,
                        color: type.color,
                      ),
                    
                    // الوصف
                    if (appointment.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.description,
                        title: 'الوصف',
                        content: appointment.description,
                        color: type.color,
                      ),
                    ],
                    
                    // الملاحظات
                    if (appointment.notes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.note,
                        title: 'ملاحظات',
                        content: appointment.notes,
                        color: type.color,
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // معلومات إضافية
                    _buildMetaInfo(type, priority),
                  ],
                ),
              ),
            ),
            
            // Actions
            _buildActions(context, status),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppointmentType type) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [type.color, type.color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(type.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'تفاصيل الموعد',
                  style: GoogleFonts.tajawal(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(AppointmentStatus status) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            appointment.title,
            style: GoogleFonts.tajawal(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: status.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: status.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(status.icon, size: 18, color: status.color),
              const SizedBox(width: 6),
              Text(
                status.label,
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: status.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection(Color color) {
    final dateFormat = DateFormat('EEEE، d MMMM yyyy', 'ar');
    final timeFormat = DateFormat('h:mm a', 'ar');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calendar_month, color: color, size: 22),
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
                    Text(
                      dateFormat.format(appointment.dateTime),
                      style: GoogleFonts.tajawal(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (appointment.isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'اليوم',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.access_time, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الوقت',
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _getTimeText(timeFormat),
                      style: GoogleFonts.tajawal(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (appointment.duration != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDuration(appointment.duration!),
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeText(DateFormat format) {
    final start = format.format(appointment.dateTime);
    if (appointment.endTime != null) {
      final end = format.format(appointment.endTime!);
      return '$start - $end';
    }
    return start;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours ساعة ${minutes > 0 ? 'و $minutes دقيقة' : ''}';
    }
    return '$minutes دقيقة';
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.tajawal(
              fontSize: 15,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(AppointmentType type, AppointmentPriority priority) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // النوع
        _buildMetaChip(
          icon: type.icon,
          label: type.label,
          color: type.color,
        ),
        
        // الأولوية
        _buildMetaChip(
          icon: priority.icon,
          label: 'أولوية ${priority.label}',
          color: priority.color,
        ),
        
        // التذكير
        if (appointment.hasReminder)
          _buildMetaChip(
            icon: Icons.notifications_active,
            label: 'تذكير قبل ${appointment.reminderMinutes} دقيقة',
            color: const Color(0xFF6366F1),
          ),
      ],
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, AppointmentStatus status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          // زر الحذف
          IconButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
          
          const SizedBox(width: 12),
          
          // زر التعديل
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onEdit();
              },
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: Text('تعديل', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // زر الإكمال
          if (status == AppointmentStatus.pending)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onComplete();
                },
                icon: const Icon(Icons.check_circle, size: 20),
                label: Text('إكمال', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
