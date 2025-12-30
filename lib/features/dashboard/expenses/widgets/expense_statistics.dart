import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/expense_model.dart';

/// ويدجت إحصائيات المصروفات
/// يعرض إحصائيات وتحليلات المصروفات بشكل بصري جذاب
class ExpenseStatistics extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final String period;

  const ExpenseStatistics({
    super.key,
    required this.expenses,
    this.period = 'هذا الشهر',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // بطاقة الإجمالي
        _buildTotalCard(context),
        const SizedBox(height: 16),

        // رسم بياني للفئات
        _buildCategoryChart(context),
        const SizedBox(height: 16),

        // إحصائيات سريعة
        _buildQuickStats(context),
      ],
    );
  }

  Widget _buildTotalCard(BuildContext context) {
    final total = _calculateTotal();
    final avgDaily = _calculateDailyAverage();
    final topCategory = _getTopCategory();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // العنوان والفترة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'إجمالي المصروفات',
                style: GoogleFonts.tajawal(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
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
          const SizedBox(height: 16),

          // المبلغ الإجمالي
          Text(
            _formatAmount(total),
            style: GoogleFonts.tajawal(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'جنيه مصري',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 24),

          // الإحصائيات السفلية
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                icon: Icons.receipt_long_rounded,
                value: expenses.length.toString(),
                label: 'مصروف',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
              ),
              _buildStatColumn(
                icon: Icons.trending_up_rounded,
                value: _formatAmount(avgDaily),
                label: 'متوسط يومي',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white24,
              ),
              _buildStatColumn(
                icon: topCategory?.icon ?? Icons.category_rounded,
                value: topCategory?.arabicName ?? '-',
                label: 'الأعلى',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.tajawal(
            fontSize: 11,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChart(BuildContext context) {
    final categoryTotals = _getCategoryTotals();
    final total = _calculateTotal();

    if (categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'المصروفات حسب الفئة',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),

          // شريط التقدم للفئات
          ...categoryTotals.entries.take(5).map((entry) {
            final category = entry.key;
            final amount = entry.value;
            final percentage = total > 0 ? (amount / total) * 100 : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          category.icon,
                          color: category.color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category.arabicName,
                          style: GoogleFonts.tajawal(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.grey.shade800,
                          ),
                        ),
                      ),
                      Text(
                        _formatAmount(amount),
                        style: GoogleFonts.tajawal(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: category.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: category.color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(category.color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final maxExpense = _getMaxExpense();
    final minExpense = _getMinExpense();
    final paymentMethodStats = _getPaymentMethodStats();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // أعلى مصروف
          Expanded(
            child: _buildQuickStatCard(
              context,
              icon: Icons.arrow_upward_rounded,
              iconColor: Colors.red,
              title: 'أعلى مصروف',
              value: maxExpense != null
                  ? _formatAmount(maxExpense.amount)
                  : '-',
              subtitle: maxExpense?.title ?? '',
            ),
          ),
          const SizedBox(width: 12),

          // أقل مصروف
          Expanded(
            child: _buildQuickStatCard(
              context,
              icon: Icons.arrow_downward_rounded,
              iconColor: Colors.green,
              title: 'أقل مصروف',
              value: minExpense != null
                  ? _formatAmount(minExpense.amount)
                  : '-',
              subtitle: minExpense?.title ?? '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.white,
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
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.grey.shade800,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.tajawal(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // الدوال المساعدة للحسابات
  double _calculateTotal() {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double _calculateDailyAverage() {
    if (expenses.isEmpty) return 0;

    final dates = expenses.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet();
    if (dates.isEmpty) return 0;

    return _calculateTotal() / dates.length;
  }

  ExpenseCategory? _getTopCategory() {
    if (expenses.isEmpty) return null;

    final categoryTotals = _getCategoryTotals();
    if (categoryTotals.isEmpty) return null;

    return categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  Map<ExpenseCategory, double> _getCategoryTotals() {
    final Map<ExpenseCategory, double> totals = {};

    for (final expense in expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }

    // ترتيب تنازلي
    final sorted = Map.fromEntries(
      totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    return sorted;
  }

  ExpenseModel? _getMaxExpense() {
    if (expenses.isEmpty) return null;
    return expenses.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  ExpenseModel? _getMinExpense() {
    if (expenses.isEmpty) return null;
    return expenses.reduce((a, b) => a.amount < b.amount ? a : b);
  }

  Map<PaymentMethod, int> _getPaymentMethodStats() {
    final Map<PaymentMethod, int> stats = {};
    for (final expense in expenses) {
      stats[expense.paymentMethod] = (stats[expense.paymentMethod] ?? 0) + 1;
    }
    return stats;
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

/// ويدجت ملخص الفئة
class CategorySummaryCard extends StatelessWidget {
  final ExpenseCategory category;
  final double amount;
  final int count;
  final double percentage;
  final VoidCallback? onTap;

  const CategorySummaryCard({
    super.key,
    required this.category,
    required this.amount,
    required this.count,
    required this.percentage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: category.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: category.color.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: category.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              category.arabicName,
              style: GoogleFonts.tajawal(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ج.م ${amount.toStringAsFixed(0)}',
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: category.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count مصروف',
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ويدجت فلتر الفترة الزمنية
class PeriodFilter extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const PeriodFilter({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final periods = [
      {'key': 'today', 'label': 'اليوم'},
      {'key': 'week', 'label': 'هذا الأسبوع'},
      {'key': 'month', 'label': 'هذا الشهر'},
      {'key': 'year', 'label': 'هذه السنة'},
      {'key': 'all', 'label': 'الكل'},
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final period = periods[index];
          final isSelected = selectedPeriod == period['key'];

          return InkWell(
            onTap: () => onPeriodChanged(period['key']!),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF667eea)
                    : Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF667eea)
                      : Colors.transparent,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                period['label']!,
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ويدجت فلتر الفئة
class CategoryFilter extends StatelessWidget {
  final ExpenseCategory? selectedCategory;
  final Function(ExpenseCategory?) onCategoryChanged;

  const CategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ExpenseCategory.values.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            // زر "الكل"
            final isSelected = selectedCategory == null;
            return InkWell(
              onTap: () => onCategoryChanged(null),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF667eea)
                      : Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade800
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'الكل',
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                  ),
                ),
              ),
            );
          }

          final category = ExpenseCategory.values[index - 1];
          final isSelected = selectedCategory == category;

          return InkWell(
            onTap: () => onCategoryChanged(category),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? category.color
                    : category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: category.color.withOpacity(isSelected ? 1 : 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    category.icon,
                    size: 18,
                    color: isSelected ? Colors.white : category.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category.arabicName,
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : category.color,
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
}
