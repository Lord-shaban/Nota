import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// شبكة الإجراءات السريعة - أزرار للانتقال السريع للأقسام
class QuickActionsGrid extends StatelessWidget {
  final VoidCallback onAddTask;
  final VoidCallback onAddAppointment;
  final VoidCallback onAddExpense;
  final VoidCallback onAddQuote;

  const QuickActionsGrid({
    super.key,
    required this.onAddTask,
    required this.onAddAppointment,
    required this.onAddExpense,
    required this.onAddQuote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Color(0xFF58CC02),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'الانتقال السريع',
                style: GoogleFonts.tajawal(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _QuickActionButton(
                icon: Icons.task_alt_rounded,
                label: 'المهام',
                color: const Color(0xFF58CC02),
                onTap: onAddTask,
              ),
              _QuickActionButton(
                icon: Icons.event_rounded,
                label: 'المواعيد',
                color: const Color(0xFFFFB800),
                onTap: onAddAppointment,
              ),
              _QuickActionButton(
                icon: Icons.receipt_long_rounded,
                label: 'المصروفات',
                color: Colors.blue,
                onTap: onAddExpense,
              ),
              _QuickActionButton(
                icon: Icons.format_quote_rounded,
                label: 'الاقتباسات',
                color: Colors.purple,
                onTap: onAddQuote,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
