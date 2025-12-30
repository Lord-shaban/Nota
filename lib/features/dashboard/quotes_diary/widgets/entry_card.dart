import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/entry_model.dart';

/// بطاقة الاقتباس/اليومية
class EntryCard extends StatelessWidget {
  final EntryModel entry;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isCompact;

  const EntryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
    this.onEdit,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getGradientColor(),
              _getGradientColor().withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _getGradientColor().withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: isCompact ? _buildCompactContent() : _buildFullContent(context),
      ),
    );
  }

  Color _getGradientColor() {
    if (entry.isQuote && entry.quoteCategory != null) {
      return entry.quoteCategory!.color;
    } else if (entry.isDiary && entry.mood != null) {
      return entry.mood!.color;
    }
    return entry.type.color;
  }

  Widget _buildCompactContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // النوع والمفضلة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTypeBadge(),
              if (entry.isFavorite)
                const Icon(Icons.favorite, color: Colors.white, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          // المحتوى
          Text(
            entry.shortContent,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: Colors.white,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // التاريخ
          Text(
            DateFormat('d MMM', 'ar').format(entry.date),
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الهيدر
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildTypeBadge(),
                  const SizedBox(width: 8),
                  if (entry.isQuote && entry.quoteCategory != null)
                    _buildCategoryBadge(),
                  if (entry.isDiary && entry.mood != null)
                    _buildMoodBadge(),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // المفضلة
                  GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // القائمة
                  _buildPopupMenu(context),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // أيقونة الاقتباس
          if (entry.isQuote)
            Icon(
              Icons.format_quote,
              color: Colors.white.withValues(alpha: 0.8),
              size: 32,
            ),

          // عنوان اليومية
          if (entry.isDiary && entry.title != null) ...[
            Text(
              entry.title!,
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 8),

          // المحتوى
          Text(
            entry.content,
            style: GoogleFonts.tajawal(
              fontSize: entry.isQuote ? 18 : 15,
              fontStyle: entry.isQuote ? FontStyle.italic : FontStyle.normal,
              color: Colors.white,
              height: 1.6,
            ),
          ),

          // المؤلف (للاقتباسات)
          if (entry.isQuote && entry.author != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 30,
                  height: 2,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.author!,
                    style: GoogleFonts.tajawal(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // المصدر (للاقتباسات)
          if (entry.isQuote && entry.source != null) ...[
            const SizedBox(height: 4),
            Text(
              entry.source!,
              style: GoogleFonts.tajawal(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // التاجات
          if (entry.tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#$tag',
                    style: GoogleFonts.tajawal(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // الفوتر
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // التاريخ
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEEE، d MMMM yyyy', 'ar').format(entry.date),
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              // الخصوصية
              if (entry.isPrivate)
                Icon(
                  Icons.lock,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            entry.type.icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            entry.type.arabicName,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            entry.quoteCategory!.icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            entry.quoteCategory!.arabicName,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.mood!.emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            entry.mood!.arabicName,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'copy':
            _copyContent(context);
            break;
          case 'share':
            _shareContent(context);
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, size: 20),
              const SizedBox(width: 10),
              Text('تعديل', style: GoogleFonts.tajawal()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              const Icon(Icons.copy, size: 20),
              const SizedBox(width: 10),
              Text('نسخ', style: GoogleFonts.tajawal()),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              const Icon(Icons.share, size: 20),
              const SizedBox(width: 10),
              Text('مشاركة', style: GoogleFonts.tajawal()),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 20, color: Colors.red),
              const SizedBox(width: 10),
              Text('حذف', style: GoogleFonts.tajawal(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _copyContent(BuildContext context) {
    String textToCopy = entry.content;
    if (entry.isQuote && entry.author != null) {
      textToCopy += '\n- ${entry.author}';
    }
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check, color: Colors.white),
            const SizedBox(width: 8),
            Text('تم النسخ!', style: GoogleFonts.tajawal()),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareContent(BuildContext context) {
    // TODO: تنفيذ المشاركة
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('قريباً...', style: GoogleFonts.tajawal()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// بطاقة اقتباس اليوم
class QuoteOfDayCard extends StatelessWidget {
  final String text;
  final String author;
  final VoidCallback? onTap;

  const QuoteOfDayCard({
    super.key,
    required this.text,
    required this.author,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
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
              color: const Color(0xFF667eea).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'اقتباس اليوم',
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // أيقونة الاقتباس
            Icon(
              Icons.format_quote,
              color: Colors.white.withValues(alpha: 0.6),
              size: 36,
            ),

            const SizedBox(height: 12),

            // النص
            Text(
              text,
              style: GoogleFonts.tajawal(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 16),

            // المؤلف
            Row(
              children: [
                Container(
                  width: 30,
                  height: 2,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 10),
                Text(
                  author,
                  style: GoogleFonts.tajawal(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة ملخص اليوميات
class DiaryStatsCard extends StatelessWidget {
  final int totalDiaries;
  final int thisMonthDiaries;
  final DiaryMood? mostFrequentMood;

  const DiaryStatsCard({
    super.key,
    required this.totalDiaries,
    required this.thisMonthDiaries,
    this.mostFrequentMood,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إحصائيات اليوميات',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'الإجمالي',
                  totalDiaries.toString(),
                  Icons.book,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'هذا الشهر',
                  thisMonthDiaries.toString(),
                  Icons.calendar_month,
                  Colors.green,
                ),
              ),
              if (mostFrequentMood != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'المزاج الغالب',
                    mostFrequentMood!.emoji,
                    mostFrequentMood!.icon,
                    mostFrequentMood!.color,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
