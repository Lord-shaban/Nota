// search_delegate.dart
// ------------------------------------------------------------
// Search Delegate for Notes/Tasks/Appointments
// Inspired by alNota's search and filter functionality
// Provides smart search with filters and sorting
// ------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom Search Delegate
/// Handles search across all content types with filters
class NotaSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  final List<Map<String, dynamic>> allItems;
  final Function(Map<String, dynamic>)? onItemSelected;

  // Filters
  String? _selectedCategory;
  String? _selectedPriority;
  DateTime? _selectedDate;
  String _sortBy = 'recent'; // recent, priority, alphabetical

  NotaSearchDelegate({
    required this.allItems,
    this.onItemSelected,
  });

  @override
  String get searchFieldLabel => 'ابحث في الملاحظات...';

  @override
  TextStyle get searchFieldStyle => GoogleFonts.tajawal(fontSize: 16);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFFB800),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: GoogleFonts.tajawal(
          color: Colors.white70,
          fontSize: 16,
        ),
        border: InputBorder.none,
      ),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.tajawal(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
      IconButton(
        icon: const Icon(Icons.filter_list),
        onPressed: () => _showFilterDialog(context),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _getFilteredResults();

    if (results.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return _buildResultCard(context, results[index]);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentSearches(context);
    }

    final suggestions = _getFilteredResults();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: suggestions.length > 5 ? 5 : suggestions.length,
      itemBuilder: (context, index) {
        return _buildSuggestionCard(context, suggestions[index]);
      },
    );
  }

  /// Get filtered and sorted results
  List<Map<String, dynamic>> _getFilteredResults() {
    var results = allItems.where((item) {
      // Text search
      final title = (item['title'] ?? '').toString().toLowerCase();
      final content = (item['content'] ?? '').toString().toLowerCase();
      final searchLower = query.toLowerCase();

      final matchesSearch =
          title.contains(searchLower) || content.contains(searchLower);

      // Category filter
      final matchesCategory = _selectedCategory == null ||
          item['category'] == _selectedCategory;

      // Priority filter
      final matchesPriority = _selectedPriority == null ||
          item['priority'] == _selectedPriority;

      // Date filter
      final matchesDate = _selectedDate == null ||
          _isSameDay(item['date'], _selectedDate!);

      return matchesSearch &&
          matchesCategory &&
          matchesPriority &&
          matchesDate;
    }).toList();

    // Sort results
    results = _sortResults(results);

    return results;
  }

  /// Sort results based on selected option
  List<Map<String, dynamic>> _sortResults(List<Map<String, dynamic>> items) {
    switch (_sortBy) {
      case 'priority':
        items.sort((a, b) {
          final priorityOrder = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3};
          final aPriority = priorityOrder[a['priority']] ?? 99;
          final bPriority = priorityOrder[b['priority']] ?? 99;
          return aPriority.compareTo(bPriority);
        });
        break;
      case 'alphabetical':
        items.sort((a, b) {
          final aTitle = (a['title'] ?? '').toString();
          final bTitle = (b['title'] ?? '').toString();
          return aTitle.compareTo(bTitle);
        });
        break;
      case 'recent':
      default:
        items.sort((a, b) {
          final aDate = a['createdAt'] as DateTime? ?? DateTime(2000);
          final bDate = b['createdAt'] as DateTime? ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
    }
    return items;
  }

  /// Build result card
  Widget _buildResultCard(BuildContext context, Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          close(context, item);
          onItemSelected?.call(item);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getCategoryIcon(item['category']),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['title'] ?? 'بدون عنوان',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item['priority'] != null)
                    _getPriorityBadge(item['priority']),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['content'] ?? '',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(item['createdAt']),
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build suggestion card (similar but smaller)
  Widget _buildSuggestionCard(BuildContext context, Map<String, dynamic> item) {
    return ListTile(
      leading: _getCategoryIcon(item['category']),
      title: Text(
        item['title'] ?? 'بدون عنوان',
        style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        item['content'] ?? '',
        style: GoogleFonts.tajawal(fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: item['priority'] != null
          ? _getPriorityBadge(item['priority'])
          : null,
      onTap: () {
        query = item['title'] ?? '';
        showResults(context);
      },
    );
  }

  /// Build recent searches
  Widget _buildRecentSearches(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'ابحث في ملاحظاتك',
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ الكتابة للبحث',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'جرب كلمات مفتاحية أخرى',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// Show filter dialog
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تصفية النتائج', style: GoogleFonts.tajawal()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category filter
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'الفئة',
                  labelStyle: GoogleFonts.tajawal(),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text('الكل')),
                  DropdownMenuItem(value: 'todo', child: Text('مهام')),
                  DropdownMenuItem(value: 'appointment', child: Text('مواعيد')),
                  DropdownMenuItem(value: 'expense', child: Text('مصروفات')),
                  DropdownMenuItem(value: 'note', child: Text('ملاحظات')),
                ],
                onChanged: (value) => _selectedCategory = value,
              ),
              const SizedBox(height: 16),
              // Sort option
              DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: InputDecoration(
                  labelText: 'الترتيب',
                  labelStyle: GoogleFonts.tajawal(),
                ),
                items: [
                  DropdownMenuItem(value: 'recent', child: Text('الأحدث')),
                  DropdownMenuItem(value: 'priority', child: Text('الأولوية')),
                  DropdownMenuItem(value: 'alphabetical', child: Text('أبجدياً')),
                ],
                onChanged: (value) => _sortBy = value ?? 'recent',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _selectedCategory = null;
              _selectedPriority = null;
              _selectedDate = null;
              _sortBy = 'recent';
              Navigator.pop(context);
              showResults(context);
            },
            child: Text('إعادة تعيين', style: GoogleFonts.tajawal()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showResults(context);
            },
            child: Text('تطبيق', style: GoogleFonts.tajawal()),
          ),
        ],
      ),
    );
  }

  /// Get category icon
  Widget _getCategoryIcon(String? category) {
    IconData icon;
    Color color;

    switch (category) {
      case 'todo':
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case 'appointment':
        icon = Icons.event;
        color = Colors.purple;
        break;
      case 'expense':
        icon = Icons.attach_money;
        color = Colors.orange;
        break;
      case 'quote':
        icon = Icons.format_quote;
        color = Colors.teal;
        break;
      default:
        icon = Icons.note;
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  /// Get priority badge
  Widget _getPriorityBadge(String? priority) {
    if (priority == null) return const SizedBox.shrink();

    Color color;
    switch (priority.toLowerCase()) {
      case 'urgent':
        color = Colors.red;
        break;
      case 'high':
        color = Colors.orange;
        break;
      case 'medium':
        color = Colors.blue;
        break;
      case 'low':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.toUpperCase(),
        style: GoogleFonts.tajawal(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Format date
  String _formatDate(dynamic date) {
    if (date == null) return '';
    final DateTime dt = date is DateTime ? date : DateTime.now();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  /// Check if same day
  bool _isSameDay(dynamic date1, DateTime date2) {
    if (date1 == null) return false;
    final DateTime dt1 = date1 is DateTime ? date1 : DateTime.now();
    return dt1.year == date2.year &&
        dt1.month == date2.month &&
        dt1.day == date2.day;
  }
}
