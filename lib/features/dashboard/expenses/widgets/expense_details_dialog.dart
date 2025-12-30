import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import 'add_expense_dialog.dart';

/// حوار تفاصيل المصروف
/// يعرض جميع تفاصيل المصروف بشكل منظم وجميل
class ExpenseDetailsDialog extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpenseDetailsDialog({
    super.key,
    required this.expense,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = expense.category.color;
    final size = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: size.height * 0.85,
          maxWidth: 500,
        ),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.shade900
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // الهيدر
            _buildHeader(context),

            // المحتوى
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // بطاقة المبلغ
                    _buildAmountCard(context),
                    const SizedBox(height: 20),

                    // المعلومات الأساسية
                    _buildInfoSection(context),
                    const SizedBox(height: 20),

                    // التفاصيل الإضافية
                    if (_hasAdditionalDetails()) ...[
                      _buildAdditionalDetails(context),
                      const SizedBox(height: 20),
                    ],

                    // التاجات
                    if (expense.tags.isNotEmpty) ...[
                      _buildTagsSection(context),
                      const SizedBox(height: 20),
                    ],

                    // الملاحظات
                    if (expense.notes != null && expense.notes!.isNotEmpty)
                      _buildNotesSection(context),
                  ],
                ),
              ),
            ),

            // أزرار الإجراءات
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final categoryColor = expense.category.color;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            categoryColor,
            categoryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // أيقونة الفئة
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  expense.category.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // العنوان والفئة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      style: GoogleFonts.tajawal(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        expense.category.arabicName,
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // زر الإغلاق
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          // حالة الاسترداد
          if (expense.isRefunded) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تم استرداد ${expense.refundAmount?.toStringAsFixed(2) ?? '0'} ${expense.currency}',
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context) {
    final categoryColor = expense.category.color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            categoryColor.withOpacity(0.1),
            categoryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // المبلغ
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المبلغ',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                expense.formattedAmount,
                style: GoogleFonts.tajawal(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: categoryColor,
                ),
              ),
              if (expense.isRefunded) ...[
                const SizedBox(height: 4),
                Text(
                  'المبلغ الفعلي: ${expense.formattedEffectiveAmount}',
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),

          // الأولوية
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: expense.priority.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: expense.priority.color.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _getPriorityIcon(expense.priority),
                  color: expense.priority.color,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  expense.priority.arabicName,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: expense.priority.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات المصروف',
          style: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),

        // طريقة الدفع
        _buildInfoRow(
          icon: expense.paymentMethod.icon,
          iconColor: Colors.blue,
          label: 'طريقة الدفع',
          value: expense.paymentMethod.arabicName,
        ),
        const Divider(height: 24),

        // التاريخ
        _buildInfoRow(
          icon: Icons.calendar_today_rounded,
          iconColor: Colors.orange,
          label: 'التاريخ',
          value: DateFormat.yMMMMEEEEd('ar').format(expense.date),
        ),
        const Divider(height: 24),

        // الوقت
        _buildInfoRow(
          icon: Icons.access_time_rounded,
          iconColor: Colors.purple,
          label: 'الوقت',
          value: DateFormat.jm('ar').format(expense.date),
        ),

        // التكرار
        if (expense.recurrence != RecurrenceType.none) ...[
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.repeat_rounded,
            iconColor: Colors.teal,
            label: 'التكرار',
            value: expense.recurrence.arabicName,
          ),
        ],

        // الوصف
        if (expense.description != null && expense.description!.isNotEmpty) ...[
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.description_outlined,
            iconColor: Colors.grey,
            label: 'الوصف',
            value: expense.description!,
            isMultiLine: true,
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تفاصيل إضافية',
          style: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),

        // البائع
        if (expense.vendor != null && expense.vendor!.isNotEmpty) ...[
          _buildInfoRow(
            icon: Icons.store_rounded,
            iconColor: Colors.indigo,
            label: 'البائع/المتجر',
            value: expense.vendor!,
          ),
          const Divider(height: 24),
        ],

        // الموقع
        if (expense.location != null && expense.location!.isNotEmpty)
          _buildInfoRow(
            icon: Icons.location_on_rounded,
            iconColor: Colors.red,
            label: 'الموقع',
            value: expense.location!,
          ),
      ],
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    final categoryColor = expense.category.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التاجات',
          style: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: expense.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: categoryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                '#$tag',
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  color: categoryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ملاحظات',
          style: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.amber.withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.note_rounded,
                color: Colors.amber.shade700,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  expense.notes!,
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiLine
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final categoryColor = expense.category.color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // زر الحذف
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.red.shade400),
              ),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade600,
              ),
              label: Text(
                'حذف',
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // زر التعديل
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () => _editExpense(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: categoryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: categoryColor.withOpacity(0.4),
              ),
              icon: const Icon(Icons.edit_rounded),
              label: Text(
                'تعديل',
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPriorityIcon(ExpensePriority priority) {
    switch (priority) {
      case ExpensePriority.essential:
        return Icons.priority_high_rounded;
      case ExpensePriority.important:
        return Icons.arrow_upward_rounded;
      case ExpensePriority.optional:
        return Icons.arrow_downward_rounded;
    }
  }

  bool _hasAdditionalDetails() {
    return (expense.vendor != null && expense.vendor!.isNotEmpty) ||
        (expense.location != null && expense.location!.isNotEmpty);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'تأكيد الحذف',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا المصروف؟\nلا يمكن التراجع عن هذا الإجراء.',
          style: GoogleFonts.tajawal(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: GoogleFonts.tajawal(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'حذف',
              style: GoogleFonts.tajawal(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('notes')
            .doc(expense.id)
            .delete();

        if (context.mounted) {
          Navigator.pop(context, 'deleted');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'تم حذف المصروف بنجاح',
                    style: GoogleFonts.tajawal(),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في الحذف: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editExpense(BuildContext context) async {
    Navigator.pop(context);
    
    await showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(expense: expense),
    );
  }
}
