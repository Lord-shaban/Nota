import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

/// بطاقة عرض المصروف
/// تعرض معلومات المصروف بشكل جذاب ومنظم
class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool isCompact;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = expense.category.color;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 16,
        vertical: isCompact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            child: isCompact ? _buildCompactLayout(context) : _buildFullLayout(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = expense.category.color;

    return Row(
      children: [
        // أيقونة الفئة
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            expense.category.icon,
            color: categoryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // العنوان والفئة
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.title,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                expense.category.arabicName,
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  color: categoryColor,
                ),
              ),
            ],
          ),
        ),

        // المبلغ
        Text(
          expense.formattedAmount,
          style: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: categoryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFullLayout(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = expense.category.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // الصف العلوي: أيقونة الفئة والعنوان والمبلغ
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // أيقونة الفئة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    categoryColor,
                    categoryColor.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: categoryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                expense.category.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // العنوان والتفاصيل
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان
                  Text(
                    expense.title,
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey.shade800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // الفئة وطريقة الدفع
                  Row(
                    children: [
                      _buildTag(
                        expense.category.arabicName,
                        categoryColor,
                      ),
                      const SizedBox(width: 6),
                      _buildTag(
                        expense.paymentMethod.arabicName,
                        Colors.grey.shade600,
                      ),
                    ],
                  ),

                  // التاريخ
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(expense.date),
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // المبلغ
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    expense.formattedAmount,
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                ),

                // مؤشر الاسترداد
                if (expense.isRefunded) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          size: 12,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'مسترد',
                          style: GoogleFonts.tajawal(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),

        // الوصف (إن وجد)
        if (expense.description != null && expense.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey.shade800.withOpacity(0.5)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    expense.description!,
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],

        // البائع والموقع (إن وجد)
        if (expense.vendor != null || expense.location != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              if (expense.vendor != null && expense.vendor!.isNotEmpty)
                _buildInfoChip(
                  Icons.store_rounded,
                  expense.vendor!,
                  Colors.blue,
                ),
              if (expense.location != null && expense.location!.isNotEmpty)
                _buildInfoChip(
                  Icons.location_on_rounded,
                  expense.location!,
                  Colors.red,
                ),
            ],
          ),
        ],

        // التكرار (إن وجد)
        if (expense.recurrence != RecurrenceType.none) ...[
          const SizedBox(height: 10),
          _buildInfoChip(
            Icons.repeat_rounded,
            expense.recurrence.arabicName,
            Colors.purple,
          ),
        ],

        // التاجات (إن وجدت)
        if (expense.tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: expense.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: categoryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '#$tag',
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    color: categoryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],

        // أزرار الإجراءات
        if (showActions) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // زر التعديل
              TextButton.icon(
                onPressed: onEdit,
                icon: Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: Colors.blue.shade600,
                ),
                label: Text(
                  'تعديل',
                  style: GoogleFonts.tajawal(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // زر الحذف
              TextButton.icon(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: Colors.red.shade600,
                ),
                label: Text(
                  'حذف',
                  style: GoogleFonts.tajawal(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.tajawal(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.tajawal(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'اليوم - ${DateFormat.jm('ar').format(date)}';
    } else if (dateToCheck == yesterday) {
      return 'أمس - ${DateFormat.jm('ar').format(date)}';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat.EEEE('ar').format(date);
    } else {
      return DateFormat.yMMMd('ar').format(date);
    }
  }
}

/// بطاقة ملخص المصروفات
class ExpenseSummaryCard extends StatelessWidget {
  final double totalAmount;
  final String currency;
  final int expenseCount;
  final ExpenseCategory? topCategory;
  final double? percentChange;
  final String period;

  const ExpenseSummaryCard({
    super.key,
    required this.totalAmount,
    this.currency = 'EGP',
    required this.expenseCount,
    this.topCategory,
    this.percentChange,
    this.period = 'هذا الشهر',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان والفترة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إجمالي المصروفات',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  period,
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // المبلغ الإجمالي
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatAmount(totalAmount),
                style: GoogleFonts.tajawal(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  _getCurrencyLabel(currency),
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),

          // الإحصائيات السفلية
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // عدد المصروفات
              _buildStatItem(
                icon: Icons.receipt_long_rounded,
                label: 'عدد المصروفات',
                value: expenseCount.toString(),
              ),

              // نسبة التغيير
              if (percentChange != null)
                _buildStatItem(
                  icon: percentChange! >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  label: 'مقارنة بالسابق',
                  value: '${percentChange!.abs().toStringAsFixed(1)}%',
                  valueColor: percentChange! >= 0
                      ? Colors.red.shade200
                      : Colors.green.shade200,
                ),

              // الفئة الأعلى
              if (topCategory != null)
                _buildStatItem(
                  icon: topCategory!.icon,
                  label: 'الأعلى إنفاقاً',
                  value: topCategory!.arabicName,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(2);
  }

  String _getCurrencyLabel(String currency) {
    switch (currency.toUpperCase()) {
      case 'EGP':
        return 'جنيه مصري';
      case 'USD':
        return 'دولار';
      case 'EUR':
        return 'يورو';
      case 'SAR':
        return 'ريال سعودي';
      default:
        return currency;
    }
  }
}
