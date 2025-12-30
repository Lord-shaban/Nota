import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';

/// بطاقة الموعد المحسّنة
class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onComplete;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final type = AppointmentType.fromString(appointment.type);
    final priority = AppointmentPriority.fromString(appointment.priority);
    final status = AppointmentStatus.fromString(appointment.status);
    final isPast = appointment.isPast;
    final isOngoing = appointment.isOngoing;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          right: BorderSide(color: type.color, width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: type.color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // أيقونة النوع
                    _buildTypeIcon(type, isOngoing),
                    const SizedBox(width: 14),
                    
                    // العنوان والنوع
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.title,
                            style: GoogleFonts.tajawal(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isPast && status != AppointmentStatus.completed 
                                  ? Colors.grey 
                                  : Colors.black87,
                              decoration: status == AppointmentStatus.cancelled 
                                  ? TextDecoration.lineThrough 
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildTypeLabel(type),
                              const SizedBox(width: 8),
                              _buildPriorityIndicator(priority),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // الحالة
                    _buildStatusBadge(status, isOngoing, appointment.isUpcoming),
                  ],
                ),
                
                // الوصف
                if (appointment.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment.description,
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                
                const SizedBox(height: 14),
                
                // معلومات التاريخ والوقت والموقع
                _buildInfoRow(type.color),
                
                // الأزرار
                const SizedBox(height: 14),
                _buildActionsRow(status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(AppointmentType type, bool isOngoing) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [type.color, type.color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: type.color.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Icon(type.icon, color: Colors.white, size: 24),
          if (isOngoing)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeLabel(AppointmentType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.label,
        style: GoogleFonts.tajawal(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: type.color,
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(AppointmentPriority priority) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(priority.icon, size: 14, color: priority.color),
        const SizedBox(width: 4),
        Text(
          priority.label,
          style: GoogleFonts.tajawal(
            fontSize: 11,
            color: priority.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(AppointmentStatus status, bool isOngoing, bool isUpcoming) {
    Color color;
    String label;
    IconData icon;

    if (isOngoing) {
      color = const Color(0xFF10B981);
      label = 'جاري الآن';
      icon = Icons.play_circle;
    } else if (isUpcoming) {
      color = const Color(0xFFF59E0B);
      label = 'قريباً';
      icon = Icons.timer;
    } else {
      color = status.color;
      label = status.label;
      icon = status.icon;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(Color typeColor) {
    final timeFormat = DateFormat('h:mm a', 'ar');

    return Wrap(
      spacing: 16,
      runSpacing: 10,
      children: [
        // التاريخ
        _buildInfoChip(
          Icons.calendar_today,
          _getDateLabel(),
          typeColor,
        ),
        
        // الوقت
        _buildInfoChip(
          Icons.access_time,
          _getTimeLabel(timeFormat),
          typeColor,
        ),
        
        // الموقع
        if (appointment.location.isNotEmpty)
          _buildInfoChip(
            Icons.location_on_outlined,
            appointment.location,
            typeColor,
          ),
        
        // التذكير
        if (appointment.hasReminder)
          _buildInfoChip(
            Icons.notifications_active,
            'تذكير قبل ${appointment.reminderMinutes} د',
            typeColor,
          ),
      ],
    );
  }

  String _getDateLabel() {
    if (appointment.isToday) return 'اليوم';
    if (appointment.isTomorrow) return 'غداً';
    
    final daysUntil = appointment.daysUntil;
    if (daysUntil > 0 && daysUntil <= 7) return 'بعد $daysUntil أيام';
    if (daysUntil < 0 && daysUntil >= -7) return 'منذ ${-daysUntil} أيام';
    
    return DateFormat('d MMM', 'ar').format(appointment.dateTime);
  }

  String _getTimeLabel(DateFormat timeFormat) {
    final start = timeFormat.format(appointment.dateTime);
    if (appointment.endTime != null) {
      final end = timeFormat.format(appointment.endTime!);
      return '$start - $end';
    }
    return start;
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow(AppointmentStatus status) {
    return Row(
      children: [
        // زر الإكمال
        if (status == AppointmentStatus.pending && onComplete != null)
          Expanded(
            child: _ActionButton(
              icon: Icons.check_circle_outline,
              label: 'إكمال',
              color: const Color(0xFF10B981),
              onTap: onComplete!,
            ),
          ),
        
        if (status == AppointmentStatus.pending && onComplete != null)
          const SizedBox(width: 8),
        
        // زر التعديل
        Expanded(
          child: _ActionButton(
            icon: Icons.edit_outlined,
            label: 'تعديل',
            color: const Color(0xFF6366F1),
            onTap: onEdit,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // زر الحذف
        _ActionButton(
          icon: Icons.delete_outline,
          label: '',
          color: Colors.red,
          onTap: onDelete,
          compact: true,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(icon, size: 18, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
